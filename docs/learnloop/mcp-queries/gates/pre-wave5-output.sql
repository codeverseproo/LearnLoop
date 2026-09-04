-- Guard: Critic Approval Required for Output
-- Blocks syllabus generation without critic verdict
-- Allows force-approve after max repair cycles

SELECT
    COALESCE(cv.verdict, 'NONE') AS verdict,
    COALESCE(cv.repair_cycle, 0) AS repair_cycle,
    COALESCE(es.repair_cycles, 0) AS repair_cycles,
    CASE
        WHEN cv.verdict IS NULL THEN 'BLOCK: No critic verdict found'
        WHEN cv.verdict = 'REJECT' AND es.repair_cycles < 5 THEN 'BLOCK: Repair loop incomplete'
        WHEN cv.verdict IN ('APPROVED', 'APPROVED_WITH_WARNINGS') THEN 'PASS'
        WHEN cv.verdict = 'REJECT' AND es.repair_cycles >= 5 THEN 'PASS: Force approved (max cycles)'
        ELSE 'BLOCK: Unknown verdict state'
    END AS guard_status,
    CASE
        WHEN cv.verdict IS NULL THEN 'Critic agent not run. Complete WAVE3 first.'
        WHEN cv.verdict = 'REJECT' AND es.repair_cycles < 5 THEN 'Critic rejected. Repair needed (cycle ' || (es.repair_cycles + 1) || '/5).'
        WHEN cv.verdict = 'APPROVED' THEN 'Critic approved. Proceed to output.'
        WHEN cv.verdict = 'APPROVED_WITH_WARNINGS' THEN 'Critic approved with warnings. Proceed to output.'
        WHEN cv.verdict = 'REJECT' AND es.repair_cycles >= 5 THEN 'Max repair cycles reached. Force approving with warnings.'
        ELSE 'Unknown state. Manual review required.'
    END AS message
FROM execution_state es
LEFT JOIN critic_verdict cv ON cv.goal_id = es.goal_id
WHERE es.goal_id = :goal_id
ORDER BY cv.created_at DESC
LIMIT 1;

-- ============================================
-- LS3: SOURCE RECENCY CALIBRATION BY GOAL_TYPE
-- ============================================
-- Query: Validate source recency against goal_type-specific thresholds
-- Parameters: :goal_id

WITH goal_recency_thresholds AS (
    SELECT
        goal_id,
        goal_type,
        CASE goal_type
            WHEN 'exam' THEN julianday('now') - 180   -- 6 months
            WHEN 'skill' THEN julianday('now') - 365  -- 1 year
            WHEN 'degree' THEN julianday('now') - 730  -- 2 years
            ELSE julianday('now') - 1095  -- 3 years for 'topic'
        END AS recency_threshold
    FROM goal_meta
    WHERE goal_id = :goal_id
),
source_freshness AS (
    SELECT
        t.id AS topic_id,
        t.topic_id AS topic_identifier,
        t.name AS topic_name,
        ts.source_type,
        ts.source_title,
        ts.source_date,
        JULIANDAY(ts.source_date) AS source_jd,
        grt.goal_type,
        grt.recency_threshold,
        CASE
            WHEN ts.source_date IS NULL THEN 'MISSING: No source date'
            WHEN JULIANDAY(ts.source_date) < grt.recency_threshold THEN 'STALE: Source older than threshold'
            ELSE 'FRESH: Source within threshold'
        END AS freshness_status,
        CAST(JULIANDAY('now') - JULIANDAY(ts.source_date) AS INTEGER) AS days_old
    FROM topics t
    JOIN topic_sources ts ON ts.topic_id = t.id
    JOIN goal_recency_thresholds grt ON 1=1
    WHERE t.topic_id LIKE '%' || :goal_id || '%'
)
SELECT
    goal_type,
    topic_name,
    source_type,
    source_title,
    source_date,
    days_old,
    freshness_status,
    CASE goal_type
        WHEN 'exam' THEN 180
        WHEN 'skill' THEN 365
        WHEN 'degree' THEN 730
        ELSE 1095
    END AS max_days_allowed,
    CASE
        WHEN days_old > CASE goal_type
            WHEN 'exam' THEN 180
            WHEN 'skill' THEN 365
            WHEN 'degree' THEN 730
            ELSE 1095
        END THEN 1
        ELSE 0
    END AS needs_refresh
FROM source_freshness
ORDER BY days_old DESC;

-- ============================================
-- AGGREGATE RECENCY COMPLIANCE
-- ============================================

SELECT
    grt.goal_type,
    COUNT(DISTINCT sf.topic_id) AS topics_with_sources,
    SUM(CASE WHEN sf.freshness_status LIKE 'FRESH%' THEN 1 ELSE 0 END) AS fresh_sources,
    SUM(CASE WHEN sf.freshness_status LIKE 'STALE%' THEN 1 ELSE 0 END) AS stale_sources,
    SUM(CASE WHEN sf.freshness_status LIKE 'MISSING%' THEN 1 ELSE 0 END) AS missing_date_sources,
    ROUND(
        100.0 * SUM(CASE WHEN sf.freshness_status LIKE 'FRESH%' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS freshness_percentage,
    CASE grt.goal_type
        WHEN 'exam' THEN '180 days (6 months)'
        WHEN 'skill' THEN '365 days (1 year)'
        WHEN 'degree' THEN '730 days (2 years)'
        ELSE '1095 days (3 years)'
    END AS recency_requirement
FROM goal_recency_thresholds grt
JOIN source_freshness sf ON 1=1
GROUP BY grt.goal_type;
