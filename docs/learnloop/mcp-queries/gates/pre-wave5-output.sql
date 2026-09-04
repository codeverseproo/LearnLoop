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
