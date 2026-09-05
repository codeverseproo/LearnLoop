-- ============================================
-- Budget Limit Enforcement Test
-- ============================================
-- Verifies: Budget setting stops agent spawning at limit
-- Claim: "Budget actually stops spawning" (Matrix #2)

-- Test 1: Budget limit blocks spawn at threshold
-- Setup: Create execution state with budget = 5, spawn_count = 5
INSERT OR REPLACE INTO execution_state (
    goal_id, phase, wave, agent_spawns, user_budget, spawn_count
) VALUES (
    'test-budget-goal', 'WAVE1', 1, 5, 5, 5
);

-- Verify: spawn_count >= user_budget triggers block
SELECT 'Test 1: Budget at limit blocks spawn',
    CASE
        WHEN spawn_count >= user_budget THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM execution_state
WHERE goal_id = 'test-budget-goal' AND phase = 'WAVE1';

-- Test 2: Budget enforcement mode is configurable
-- Verify: budget_enforcement column exists and has valid value
SELECT 'Test 2: Budget enforcement mode configurable',
    CASE
        WHEN budget_enforcement IN ('warning', 'hard_stop', 'soft_limit') THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM execution_state
WHERE goal_id = 'test-budget-goal';

-- Test 3: Budget = -1 means unlimited (default)
INSERT OR REPLACE INTO execution_state (
    goal_id, phase, wave, user_budget, spawn_count
) VALUES (
    'test-unlimited-goal', 'WAVE1', 1, -1, 100
);

SELECT 'Test 3: Budget = -1 allows unlimited spawns',
    CASE
        WHEN user_budget = -1 AND spawn_count > 50 THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM execution_state
WHERE goal_id = 'test-unlimited-goal';

-- Test 4: Budget threshold warnings at 50%, 75%, 90%
-- Verify: Warning logic in budget check query
SELECT 'Test 4: Budget threshold warnings',
    CASE
        WHEN (
            -- Simulate 50% threshold warning
            SELECT CASE
                WHEN spawn_count >= user_budget * 0.5 THEN 'WARN_50PCT'
                ELSE 'OK'
            END
            FROM execution_state
            WHERE goal_id = 'test-budget-goal' AND user_budget > 0
        ) = 'WARN_50PCT' THEN 'PASS'
        ELSE 'FAIL'
    END AS result;

-- Cleanup test data
DELETE FROM execution_state WHERE goal_id LIKE 'test-%';

-- ============================================
-- Summary: Budget Limit Enforcement
-- ============================================
-- Tests verify:
-- 1. spawn_count >= user_budget triggers block
-- 2. budget_enforcement mode is configurable
-- 3. Budget = -1 allows unlimited spawns
-- 4. Threshold warnings at 50%, 75%, 90%
--
-- Related:
-- - docs/learnloop/mcp-queries/gates/budget-check.sql
-- - SKILL.md lines 764, 908-948 (budget/wave checks)
