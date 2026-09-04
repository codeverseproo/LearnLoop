-- ============================================
-- Budget Pre-Allocation - Wave Budget Management
-- ============================================
-- Reserve agent budget per wave to enforce hard limits
-- Wave allocations: wave1=5, wave2=3, wave3=2, wave4=2, wave5=1
--
-- Parameters: :goal_id
--
-- Returns: Budget allocation status per wave with remaining capacity
--
-- Usage: Check before agent spawn in orchestrator
-- ============================================

WITH wave_budgets AS (
    SELECT 1 AS wave, 5 AS allocated_spawns UNION ALL
    SELECT 2, 3 UNION ALL
    SELECT 3, 2 UNION ALL
    SELECT 4, 2 UNION ALL
    SELECT 5, 1
),
current_usage AS (
    SELECT
        goal_id,
        wave,
        COUNT(*) AS used_spawns,
        SUM(attempts) AS total_attempts
    FROM execution_state
    WHERE goal_id = :goal_id
    GROUP BY goal_id, wave
)
SELECT
    wb.wave,
    wb.allocated_spawns AS budget,
    COALESCE(cu.used_spawns, 0) AS used,
    wb.allocated_spawns - COALESCE(cu.used_spawns, 0) AS remaining,
    CASE
        WHEN wb.allocated_spawns - COALESCE(cu.used_spawns, 0) > 0 THEN 'AVAILABLE'
        WHEN wb.allocated_spawns - COALESCE(cu.used_spawns, 0) = 0 THEN 'EXHAUSTED'
        ELSE 'OVER_BUDGET'
    END AS status,
    gm.agent_budget AS total_budget,
    gm.budget_enforcement
FROM wave_budgets wb
LEFT JOIN current_usage cu ON wb.wave = cu.wave
CROSS JOIN goal_meta gm
WHERE gm.goal_id = :goal_id
ORDER BY wb.wave;
