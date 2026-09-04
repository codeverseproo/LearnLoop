-- ============================================
-- Source Quality Metrics - Credibility Scoring
-- ============================================
-- Calculate credibility scores for topic sources based on type and age
-- scoring: official=1.0, academic=0.9, practical=0.7, expert=0.8
-- Age factor: 1.0 (recent), 0.8 (<1 year), 0.6 (<2 years), 0.4 (<3 years), 0.2 (>3 years)
--
-- Parameters: :goal_id (optional, aggregates all if null)
--
-- Returns: Quality scores per topic with source breakdown
--
-- Usage: Run during WAVE5_OUTPUT to assess content credibility
-- ============================================

WITH source_scores AS (
    SELECT
        ts.topic_id,
        t.topic_id AS topic_identifier,
        t.name AS topic_name,
        ts.source_type,
        ts.source_title,
        ts.source_date,
        CASE ts.source_type
            WHEN 'official' THEN 1.0
            WHEN 'academic' THEN 0.9
            WHEN 'expert' THEN 0.8
            WHEN 'practical' THEN 0.7
            ELSE 0.5
        END AS type_score,
        CASE
            WHEN ts.source_date >= date('now', '-30 days') THEN 1.0
            WHEN ts.source_date >= date('now', '-365 days') THEN 0.8
            WHEN ts.source_date >= date('now', '-730 days') THEN 0.6
            WHEN ts.source_date >= date('now', '-1095 days') THEN 0.4
            ELSE 0.2
        END AS age_score,
        ts.cited_at
    FROM topic_sources ts
    JOIN topics t ON ts.topic_id = t.id
),
topic_quality AS (
    SELECT
        topic_id,
        topic_identifier,
        topic_name,
        COUNT(*) AS total_sources,
        SUM(type_score * age_score) AS weighted_score,
        AVG(type_score * age_score) AS avg_quality,
        SUM(CASE WHEN source_type = 'official' THEN 1 ELSE 0 END) AS official_count,
        SUM(CASE WHEN source_type = 'academic' THEN 1 ELSE 0 END) AS academic_count,
        SUM(CASE WHEN source_type = 'expert' THEN 1 ELSE 0 END) AS expert_count,
        SUM(CASE WHEN source_type = 'practical' THEN 1 ELSE 0 END) AS practical_count,
        MIN(source_date) AS oldest_source,
        MAX(source_date) AS newest_source,
        AVG(CAST((julianday('now') - julianday(source_date)) AS INTEGER)) AS avg_source_age_days
    FROM source_scores
    GROUP BY topic_id, topic_identifier, topic_name
)
SELECT
    topic_identifier AS topic_id,
    topic_name,
    total_sources,
    ROUND(weighted_score, 3) AS credibility_score,
    ROUND(avg_quality, 3) AS avg_source_quality,
    official_count,
    academic_count,
    expert_count,
    practical_count,
    oldest_source,
    newest_source,
    ROUND(avg_source_age_days, 1) AS avg_source_age_days,
    CASE
        WHEN AVG(type_score * age_score) >= 0.8 THEN 'HIGH_QUALITY'
        WHEN AVG(type_score * age_score) >= 0.6 THEN 'MEDIUM_QUALITY'
        WHEN AVG(type_score * age_score) >= 0.4 THEN 'LOW_QUALITY'
        ELSE 'POOR_QUALITY'
    END AS quality_grade
FROM topic_quality
ORDER BY avg_source_quality DESC;
