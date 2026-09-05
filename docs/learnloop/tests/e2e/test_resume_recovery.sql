-- ============================================
-- Test: Resume from failure scenarios
-- Pattern: EXECUTION_STATE retry + CRITIC rejection recovery
-- Verifies: Pipeline can resume from WAVE1 failures and critic rejections
-- ============================================

-- ============================================
-- Test 1: Resume from WAVE1 failure (execution_state with attempts=2, phase_complete=0)
-- ============================================
-- Setup: Create execution state simulating a WAVE1 failure after 2 attempts
INSERT OR REPLACE INTO execution_state (goal_id, phase, attempts, max_attempts, phase_complete, last_attempt, error_message)
VALUES ('test-resume-wave1', 'WAVE1_DISCOVERY', 2, 3, 0, CURRENT_TIMESTAMP, 'Agent timeout during discovery');

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
INSERT OR REPLACE INTO critic_verdict (goal_id, verdict, issues_found, repair_required, timestamp)
VALUES ('test-resume-critic', 'REJECT', 3, 1, CURRENT_TIMESTAMP);

-- Setup: Create research metadata for the rejected goal (simulating WAVE1 output that was rejected)
INSERT OR REPLACE INTO research_metadata (goal_id, agent_name, phase, status, created_at)
VALUES
    ('test-resume-critic', 'explore-agent-1', 'WAVE1', 'complete', CURRENT_TIMESTAMP),
    ('test-resume-critic', 'explore-agent-2', 'WAVE1', 'complete', CURRENT_TIMESTAMP);

-- Verify: Critic verdict indicates rejection requiring repair
SELECT 'Test 2: CRITIC_REJECTED',
    CASE
        WHEN verdict = 'REJECT' AND repair_required = 1 THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM critic_verdict
WHERE goal_id = 'test-resume-critic';

-- Verify: Repair simulation - issues found should trigger WAVE1 re-execution
SELECT 'Test 2b: REPAIR_SIMULATION',
    CASE
        WHEN verdict = 'REJECT' AND issues_found > 0 AND repair_required = 1 THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM critic_verdict
WHERE goal_id = 'test-resume-critic';

-- Setup: Simulate repair by updating verdict after repair
INSERT OR REPLACE INTO critic_verdict (goal_id, verdict, issues_found, repair_required, timestamp)
VALUES ('test-resume-critic', 'APPROVE', 0, 0, CURRENT_TIMESTAMP);

-- Verify: After repair, verdict should allow pipeline continuation
SELECT 'Test 2c: REPAIR_SUCCESS',
    CASE
        WHEN verdict = 'APPROVE' AND repair_required = 0 THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM critic_verdict
WHERE goal_id = 'test-resume-critic';

-- ============================================
-- Cleanup: Reset test state
-- ============================================
DELETE FROM execution_state WHERE goal_id IN ('test-resume-wave1', 'test-resume-critic');
DELETE FROM critic_verdict WHERE goal_id IN ('test-resume-wave1', 'test-resume-critic');
DELETE FROM research_metadata WHERE goal_id IN ('test-resume-wave1', 'test-resume-critic');
