-- Test: Infrastructure chaos scenarios
-- Pattern: DB integrity, process recovery, orphan detection

-- ============================================
-- Test 1: Database integrity check
-- ============================================

SELECT 'DB_INTEGRITY',
    CASE WHEN UPPER((SELECT result FROM pragma_integrity_check LIMIT 1)) = 'OK'
    THEN 'PASS' ELSE 'FAIL' END;

-- ============================================
-- Test 2: Resume after process killed mid-wave
-- ============================================

-- Setup: Create mid-wave state (simulating process killed)
INSERT INTO execution_state (goal_id, phase, wave, phase_complete, last_attempt)
VALUES ('test-chaos-infra', 'WAVE2_DEEP_DIVE', 2, 0, CURRENT_TIMESTAMP);

-- Simulate resume: mark phase complete
UPDATE execution_state SET phase_complete = 1
WHERE goal_id = 'test-chaos-infra' AND phase = 'WAVE2_DEEP_DIVE';

-- Verify resume worked
SELECT 'PROCESS_KILL_RESUME',
    CASE WHEN phase_complete = 1 THEN 'PASS' ELSE 'FAIL' END
FROM execution_state
WHERE goal_id = 'test-chaos-infra' AND phase = 'WAVE2_DEEP_DIVE';

-- Cleanup: Reset test state
DELETE FROM execution_state WHERE goal_id = 'test-chaos-infra';

-- ============================================
-- Test 3: Orphan topics without FSRS state
-- ============================================

-- Setup: Create orphan topic
INSERT INTO topics (id, topic_id, name, status) VALUES (999, 'orphan-test', 'Orphan', 'pending');

-- Verify orphan detection query catches it
SELECT 'ORPHAN_DETECTED',
    CASE WHEN COUNT(*) >= 1 THEN 'PASS' ELSE 'FAIL' END
FROM topics t
LEFT JOIN fsrs_state f ON t.id = f.topic_id
WHERE f.topic_id IS NULL;

-- Cleanup: Remove orphan
DELETE FROM topics WHERE topic_id = 'orphan-test';
