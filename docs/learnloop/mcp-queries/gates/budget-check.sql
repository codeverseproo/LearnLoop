-- Budget Check: Advisory Warning (NOT BLOCKING)
-- Emits warnings at 10/15/20 agents but does not stop execution

SELECT
    goal_id,
    SUM(agent_spawns) as total_agents,
    CASE
        WHEN SUM(agent_spawns) >= 20 THEN 'WARN_LIMIT'
        WHEN SUM(agent_spawns) >= 15 THEN 'WARN_75PCT'
        WHEN SUM(agent_spawns) >= 10 THEN 'WARN_50PCT'
        ELSE 'OK'
    END as budget_status,
    CASE
        WHEN SUM(agent_spawns) >= 20 THEN '⚠️ Agent budget exhausted. Consider simplifying goal scope for future runs.'
        WHEN SUM(agent_spawns) >= 15 THEN '⚠️ Agent budget at 75%. Approaching limit.'
        WHEN SUM(agent_spawns) >= 10 THEN 'ℹ️ Agent count: 10+. High agent usage.'
        ELSE '✓ Agent count within budget.'
    END as budget_message
FROM execution_state
WHERE goal_id = :goal_id
GROUP BY goal_id;

-- IMPORTANT: This is ADVISORY only. Does NOT block execution.
-- Purpose: Track resource usage and inform optimization opportunities.
