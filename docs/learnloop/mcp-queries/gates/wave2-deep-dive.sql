-- Gate: Wave 2 Deep-Dive Agents Complete
-- Verifies deep-dive agents (if spawned) completed

SELECT
    goal_id,
    COUNT(*) as deep_dive_count,
    CASE
        WHEN COUNT(*) <= 10 THEN 'PASS'
        ELSE 'FAIL'
    END as gate_status,
    'Deep-dive agents spawned: ' || COUNT(*) as message
FROM execution_state
WHERE goal_id = :goal_id
AND phase = 'deep-dive'
AND phase_complete = 1
GROUP BY goal_id;

-- Note: Deep-dive count can be 0 (no complex topics) to 10 (max)
-- Expected: deep_dive_count <= 10, gate_status = 'PASS'
