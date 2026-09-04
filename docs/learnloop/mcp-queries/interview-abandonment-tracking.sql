-- ============================================
-- Interview Abandonment Tracking - UX Analytics
-- ============================================
-- Track incomplete interviews to identify UX friction points
-- Monitors stage completion rates and drop-off patterns
--
-- Parameters: :days_back (default: 30)
--
-- Returns: Abandonment metrics per interview stage
--
-- Usage: Run weekly to identify UX improvement opportunities
-- ============================================

WITH interview_stats AS (
    SELECT
        goal_id,
        goal_type,
        created_at,
        interview_complete,
        stage_1_complete,
        stage_2_complete,
        stage_3_complete,
        goal_interview_complete,
        CASE
            WHEN interview_complete = 1 THEN 'COMPLETED'
            WHEN goal_interview_complete = 1 THEN 'GOAL_STAGE_ONLY'
            WHEN stage_3_complete = 1 THEN 'ABANDONED_STAGE_3'
            WHEN stage_2_complete = 1 THEN 'ABANDONED_STAGE_2'
            WHEN stage_1_complete = 1 THEN 'ABANDONED_STAGE_1'
            ELSE 'ABANDONED_STAGE_0'
        END AS completion_status
    FROM goal_meta
    WHERE created_at >= date('now', '-' || :days_back || ' days')
)
SELECT
    completion_status,
    COUNT(*) AS goal_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage,
    AVG(CAST((julianday('now') - julianday(created_at)) AS REAL)) AS avg_days_since_start
FROM interview_stats
GROUP BY completion_status
ORDER BY
    CASE completion_status
        WHEN 'COMPLETED' THEN 0
        WHEN 'GOAL_STAGE_ONLY' THEN 1
        WHEN 'ABANDONED_STAGE_3' THEN 2
        WHEN 'ABANDONED_STAGE_2' THEN 3
        WHEN 'ABANDONED_STAGE_1' THEN 4
        ELSE 5
    END;
