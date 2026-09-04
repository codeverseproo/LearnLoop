-- Budget Check: User-Defined Agent Budget
-- Advisory warnings based on user_budget from interview

SELECT
    es.goal_id,
    gm.agent_budget,
    gm.budget_enforcement,
    SUM(es.agent_spawns) as total_agents,
    CASE
        WHEN gm.agent_budget = -1 THEN 'UNLIMITED'
        WHEN SUM(es.agent_spawns) >= gm.agent_budget THEN 'EXHAUSTED'
        WHEN SUM(es.agent_spawns) >= gm.agent_budget * 0.75 THEN 'WARN_75PCT'
        WHEN SUM(es.agent_spawns) >= gm.agent_budget * 0.5 THEN 'WARN_50PCT'
        ELSE 'OK'
    END as budget_status,
    CASE
        WHEN gm.agent_budget = -1 THEN '✓ No budget limit (unlimited mode)'
        WHEN SUM(es.agent_spawns) >= gm.agent_budget THEN
            '⚠️ Budget exhausted: ' || SUM(es.agent_spawns) || '/' || gm.agent_budget || ' agents'
        WHEN SUM(es.agent_spawns) >= gm.agent_budget * 0.75 THEN
            '⚠️ Budget at 75%: ' || SUM(es.agent_spawns) || '/' || gm.agent_budget || ' agents'
        WHEN SUM(es.agent_spawns) >= gm.agent_budget * 0.5 THEN
            'ℹ️ Budget at 50%: ' || SUM(es.agent_spawns) || '/' || gm.agent_budget || ' agents'
        ELSE '✓ Within budget: ' || SUM(es.agent_spawns) || '/' || gm.agent_budget || ' agents'
    END as budget_message
FROM execution_state es
JOIN goal_meta gm ON es.goal_id = gm.goal_id
WHERE es.goal_id = :goal_id
GROUP BY es.goal_id;

-- Budget values:
-- agent_budget = -1: Unlimited (no warnings)
-- agent_budget = 10: Conservative
-- agent_budget = 20: Balanced (default)
-- agent_budget = 50: Aggressive

-- IMPORTANT: Advisory only unless budget_enforcement = 'hard_limit'
