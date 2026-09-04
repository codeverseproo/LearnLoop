-- ============================================
-- LS2: HIDDEN TOPIC THRESHOLD VALIDATION
-- ============================================
-- Query: Find hidden topics with low confidence for review
-- Parameters: :goal_id (optional), :confidence_threshold (default 0.5)

SELECT
    t.id,
    t.topic_id,
    t.name,
    t.confidence,
    t.is_hidden,
    t.detection_method,
    gm.goal_type,
    gm.goal_id,
    CASE
        WHEN t.confidence < 0.3 THEN 'CRITICAL: Extremely low confidence'
        WHEN t.confidence < 0.5 THEN 'WARNING: Low confidence'
        ELSE 'REVIEW: Below threshold'
    END AS review_reason
FROM topics t
JOIN goal_meta gm ON gm.goal_id = :goal_id
WHERE t.is_hidden = 1
  AND t.confidence < COALESCE(:confidence_threshold, 0.5)
ORDER BY t.confidence ASC;

-- ============================================
-- UPDATE: Unhide topics with insufficient confidence
-- ============================================
-- Uncomment to auto-unhide topics below threshold

-- UPDATE topics
-- SET
--     is_hidden = 0,
--     updated_at = CURRENT_TIMESTAMP
-- WHERE is_hidden = 1
--   AND confidence < COALESCE(:confidence_threshold, 0.5);

-- ============================================
-- VALIDATION: Check hidden topic distribution
-- ============================================

SELECT
    gm.goal_type,
    COUNT(*) AS total_hidden,
    AVG(t.confidence) AS avg_confidence,
    MIN(t.confidence) AS min_confidence,
    SUM(CASE WHEN t.confidence < 0.5 THEN 1 ELSE 0 END) AS below_threshold_count
FROM topics t
JOIN goal_meta gm ON gm.goal_id = :goal_id
WHERE t.is_hidden = 1
GROUP BY gm.goal_type;
