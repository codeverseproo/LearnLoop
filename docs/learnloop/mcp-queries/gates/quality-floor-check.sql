-- ============================================
-- P0-10: Force Approve Quality Floor
-- Minimum thresholds before force approval allowed
-- ============================================

SELECT
    cv.goal_id,
    cv.verdict,
    es.repair_cycles,
    (SELECT AVG(confidence) FROM topics WHERE goal_id = :goal_id) as avg_confidence,
    (SELECT COUNT(*) FROM topic_sources WHERE topic_id IN (SELECT id FROM topics WHERE goal_id = :goal_id)) as total_sources,
    (SELECT COUNT(*) FROM topics WHERE goal_id = :goal_id) as total_topics,
    CASE
        WHEN cv.verdict IN ('APPROVED', 'APPROVED_WITH_WARNINGS') THEN 'PASS'
        WHEN cv.verdict = 'REJECT' AND es.repair_cycles < 5 THEN 'BLOCK: Repair incomplete'
        WHEN cv.verdict = 'REJECT' AND es.repair_cycles >= 5 THEN
            CASE
                WHEN (SELECT AVG(confidence) FROM topics WHERE goal_id = :goal_id) >= 0.3
                     AND (SELECT COUNT(*) FROM topic_sources WHERE topic_id IN (SELECT id FROM topics WHERE goal_id = :goal_id)) >= 30
                THEN 'PASS: Force approved (quality floor met)'
                ELSE 'BLOCK: Quality below threshold (confidence < 0.3 or sources < 30)'
            END
        ELSE 'BLOCK: Unknown state'
    END as guard_status
FROM critic_verdict cv
JOIN execution_state es ON cv.goal_id = es.goal_id
WHERE cv.goal_id = :goal_id
ORDER BY cv.created_at DESC
LIMIT 1;
