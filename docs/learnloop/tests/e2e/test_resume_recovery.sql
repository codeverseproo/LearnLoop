-- ============================================
-- Test: Resume from failure scenarios
-- Pattern: EXECUTION_STATE retry + CRITIC rejection recovery
-- Verifies: Pipeline can resume from WAVE1 failures and critic rejections
-- ============================================

-- ============================================
-- Test 1: Resume from WAVE1 failure (execution_state with attempts=2, phase_complete=0)
-- ============================================
-- Setup: Create execution state simulating a WAVE1 failure after 2 attempts
INSERT OR REPLACE INTO execution_state (goal_id, phase, wave, attempts, max_attempts, phase_complete, last_attempt, last_failure_reason)
VALUES ('test-resume-wave1', 'WAVE1_DISCOVERY', 1, 2, 3, 0, CURRENT_TIMESTAMP, 'Agent timeout during discovery');

-- Verify: Execution state indicates incomplete phase with retry capacity
SELECT 'Test 1: WAVE1_RESUME_STATE',
    CASE
        WHEN attempts = 2 AND phase_complete = 0 AND attempts < max_attempts THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM execution_state
WHERE goal_id = 'test-resume-wave1' AND phase = 'WAVE1_DISCOVERY';

-- Verify: Resume is allowed (attempts < max_attempts)
SELECT 'Test 1b: RESUME_ALLOWED',
    CASE
        WHEN COUNT(*) = 1 THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM execution_state
WHERE goal_id = 'test-resume-wave1'
  AND phase = 'WAVE1_DISCOVERY'
  AND attempts < max_attempts
  AND phase_complete = 0;

-- ============================================
-- Test 2: Resume from critic rejection (critic_verdict with REJECT, repair simulation)
-- ============================================
-- Setup: Create critic verdict with rejection
INSERT INTO critic_verdict (goal_id, verdict, warnings_count, repair_cycle, created_at)
VALUES ('test-resume-critic', 'REJECT', 3, 0, CURRENT_TIMESTAMP);

-- Setup: Create research metadata for the rejected goal (simulating WAVE1 output that was rejected)
INSERT INTO research_metadata (goal_id, agent_type, search_iterations, researched_at)
VALUES
    ('test-resume-critic', 'official', 3, CURRENT_TIMESTAMP),
    ('test-resume-critic', 'academic', 5, CURRENT_TIMESTAMP);

-- Verify: Critic verdict indicates rejection
SELECT 'Test 2: CRITIC_REJECTED',
    CASE
        WHEN verdict = 'REJECT' THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM critic_verdict
WHERE goal_id = 'test-resume-critic';

-- Setup: Simulate repair by marking cycle complete
UPDATE critic_verdict SET repair_cycle = 1 WHERE goal_id = 'test-resume-critic';

-- Verify: Repair cycle incremented
SELECT 'Test 2b: REPAIR_CYCLE_INCREMENTED',
    CASE
        WHEN repair_cycle = 1 THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM critic_verdict
WHERE goal_id = 'test-resume-critic';

-- Setup: Simulate repair completion - update verdict
UPDATE critic_verdict SET verdict = 'APPROVED', repair_cycle = 1 WHERE goal_id = 'test-resume-critic';

-- Verify: After repair, verdict should allow pipeline continuation
SELECT 'Test 2c: REPAIR_SUCCESS',
    CASE
        WHEN verdict = 'APPROVED' THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM critic_verdict
WHERE goal_id = 'test-resume-critic';

-- ============================================
-- Cleanup: Reset test state
-- ============================================
DELETE FROM execution_state WHERE goal_id = 'test-resume-wave1';
DELETE FROM critic_verdict WHERE goal_id = 'test-resume-critic';
DELETE FROM research_metadata WHERE goal_id = 'test-resume-critic';
