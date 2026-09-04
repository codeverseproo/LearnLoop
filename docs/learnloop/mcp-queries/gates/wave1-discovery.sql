-- Gate: Wave 1 Discovery Agents Complete
-- Verifies all 4 discovery agents ran

SELECT
    goal_id,
    COUNT(*) as agent_count,
    CASE
        WHEN COUNT(*) >= 4 THEN 'PASS'
        ELSE 'FAIL'
    END as gate_status,
    CASE
        WHEN COUNT(*) < 4 THEN 'Missing agents: ' ||
            CASE WHEN COUNT(*) FILTER (WHERE agent_type = 'official') = 0 THEN 'official ' ELSE '' END ||
            CASE WHEN COUNT(*) FILTER (WHERE agent_type = 'academic') = 0 THEN 'academic ' ELSE '' END ||
            CASE WHEN COUNT(*) FILTER (WHERE agent_type = 'practical') = 0 THEN 'practical ' ELSE '' END ||
            CASE WHEN COUNT(*) FILTER (WHERE agent_type = 'expert') = 0 THEN 'expert' ELSE '' END
        ELSE 'All 4 discovery agents complete'
    END as message
FROM research_metadata
WHERE goal_id = :goal_id
GROUP BY goal_id;

-- Expected: agent_count = 4, gate_status = 'PASS'
