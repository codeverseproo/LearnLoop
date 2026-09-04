-- Gate: Critic Approval
-- Verifies critic verdict is not REJECT

SELECT
    goal_id,
    last_failure_reason,
    CASE
        WHEN phase_complete = 1 AND last_failure_reason IS NULL THEN 'PASS'
        WHEN last_failure_reason LIKE '%REJECT%' THEN 'FAIL'
        ELSE 'PASS'
    END as gate_status
FROM execution_state
WHERE goal_id = :goal_id
AND phase = 'critic'
ORDER BY last_attempt DESC
LIMIT 1;

-- Expected: gate_status = 'PASS' (critic approved or approved_with_warnings)
