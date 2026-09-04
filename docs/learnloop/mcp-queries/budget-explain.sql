-- ============================================
-- Budget Explanation (UX4)
-- ============================================
-- Retrieves budget configuration with user-friendly explanation

SELECT
    goal_id,
    agent_budget,
    budget_enforcement,
    budget_explanation,
    CASE
        WHEN agent_budget = -1 THEN 'Unlimited agent budget - no restrictions on agent usage'
        WHEN agent_budget > 0 THEN
            'Budget allows up to ' || agent_budget || ' agent executions. ' ||
            CASE
                WHEN budget_enforcement = 'warning' THEN 'You will be warned when approaching the limit.'
                WHEN budget_enforcement = 'hard_limit' THEN 'Execution will stop when budget is exhausted.'
                ELSE ''
            END
        ELSE 'Budget not configured'
    END AS budget_summary,
    (SELECT SUM(agent_spawns) FROM execution_state WHERE goal_id = :goal_id) AS agents_used
FROM goal_meta
WHERE goal_id = :goal_id;
