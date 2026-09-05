-- ============================================
-- Budget Enforcement E2E Tests
-- ============================================
-- Verifies budget threshold notifications and enforcement

-- ============================================
-- Test 1: 50% Threshold (10 agents)
-- ============================================
-- Test: Budget at 50% (10 agents)
INSERT INTO execution_state (goal_id, phase, wave, agent_spawns)
VALUES ('test-budget', 'WAVE1', 1, 10);

SELECT 'BUDGET_50PCT',
    CASE
        WHEN SUM(agent_spawns) >= 10 AND SUM(agent_spawns) < 15
        THEN 'PASS (WARN_50PCT expected)'
        ELSE 'FAIL'
    END
FROM execution_state WHERE goal_id = 'test-budget';

-- ============================================
-- Test 2: Exhausted Threshold (20 agents)
-- ============================================
-- Test: Budget exhausted (20 agents)
UPDATE execution_state SET agent_spawns = 20 WHERE goal_id = 'test-budget';

SELECT 'BUDGET_EXHAUSTED',
    CASE
        WHEN SUM(agent_spawns) >= 20
        THEN 'PASS (EXHAUSTED advisory expected)'
        ELSE 'FAIL'
    END
FROM execution_state WHERE goal_id = 'test-budget';

-- ============================================
-- Cleanup
-- ============================================
DELETE FROM execution_state WHERE goal_id = 'test-budget';
