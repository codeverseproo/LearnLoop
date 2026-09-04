-- Gate: Wave 3 Critic Verdict
-- Verifies critic approved research or max repair cycles reached

SELECT
    cv.goal_id,
    cv.verdict,
    cv.confidence,
    cv.warnings_count,
    cv.repair_cycle,
    es.repair_cycles,
    CASE
        WHEN cv.verdict = 'APPROVED' THEN 'PASS'
        WHEN cv.verdict = 'APPROVED_WITH_WARNINGS' THEN 'PASS'
        WHEN cv.verdict = 'REJECT' AND es.repair_cycles < 5 THEN 'RETRY'
        WHEN cv.verdict = 'REJECT' AND es.repair_cycles >= 5 THEN 'FORCE_APPROVE'
        ELSE 'FAIL'
    END AS gate_status,
    CASE
        WHEN cv.verdict = 'REJECT' AND es.repair_cycles < 5 THEN
            'Repair needed (cycle ' || (es.repair_cycles + 1) || '/5)'
        WHEN cv.verdict = 'REJECT' AND es.repair_cycles >= 5 THEN
            'Max repair cycles reached - forcing approval with warnings'
        ELSE 'Critic approved'
    END AS message
FROM critic_verdict cv
JOIN execution_state es ON cv.goal_id = es.goal_id
WHERE cv.goal_id = :goal_id
ORDER BY cv.created_at DESC
LIMIT 1;

-- Expected:
-- gate_status = 'PASS' (approved)
-- gate_status = 'RETRY' (repair loop)
-- gate_status = 'FORCE_APPROVE' (max cycles)
