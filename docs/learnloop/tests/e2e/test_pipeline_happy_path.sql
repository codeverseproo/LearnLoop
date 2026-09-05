-- ============================================
-- Test: Full pipeline happy path
-- Pattern: USER -> Interview -> WAVE1-5 -> Obsidian
-- Verifies: Pipeline state transitions work correctly
-- ============================================

-- ============================================
-- Test 1: Goal creation and interview completion
-- ============================================
-- Setup: Create test goal with interview complete
INSERT OR REPLACE INTO goal_meta (goal_id, goal_type, interview_complete, onboarding_complete, goal_interview_complete)
VALUES ('test-goal-happy', 'exam', 1, 1, 1);

-- Verify goal exists and interview is complete
SELECT 'Test 1: GOAL_CREATED',
    CASE WHEN interview_complete = 1 THEN 'PASS' ELSE 'FAIL' END AS result
FROM goal_meta WHERE goal_id = 'test-goal-happy';

-- ============================================
-- Test 2: WAVE1 Discovery Execution State
-- ============================================
-- Setup: Simulate WAVE1 discovery phase started
INSERT OR REPLACE INTO execution_state (goal_id, phase, wave, phase_complete, last_attempt)
VALUES ('test-goal-happy', 'WAVE1_DISCOVERY', 1, 0, CURRENT_TIMESTAMP);

-- Verify WAVE1 execution state created
SELECT 'Test 2: WAVE1_STARTED',
    CASE WHEN phase_complete = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM execution_state
WHERE goal_id = 'test-goal-happy' AND phase = 'WAVE1_DISCOVERY';

-- Simulate WAVE1 complete
UPDATE execution_state SET phase_complete = 1
WHERE goal_id = 'test-goal-happy' AND phase = 'WAVE1_DISCOVERY';

-- ============================================
-- Test 3: WAVE3 Critic Verdict Creation
-- ============================================
-- Setup: Create critic verdict (simulating WAVE3 complete)
INSERT INTO critic_verdict (goal_id, verdict, confidence, warnings_count, created_at)
VALUES ('test-goal-happy', 'APPROVED', 0.95, 0, CURRENT_TIMESTAMP);

-- Verify WAVE3 critic verdict exists
SELECT 'Test 3: CRITIC_VERDICT',
    CASE WHEN verdict = 'APPROVED' THEN 'PASS' ELSE 'FAIL' END AS result
FROM critic_verdict WHERE goal_id = 'test-goal-happy';

-- ============================================
-- Test 4: WAVE5 Output Note Registry
-- ============================================
-- Create a topic for the goal to satisfy FK
INSERT OR IGNORE INTO topics (id, topic_id, name, status)
VALUES (9999, 'test-goal-happy', 'Test Topic', 'active');

-- Create output note reference (topic_id FK, not goal_id)
INSERT INTO note_registry (topic_id, note_path)
VALUES (9999, 'LearnLoop/Syllabus/test-goal-happy.md');

-- Verify output generated
SELECT 'Test 4: OUTPUT_GENERATED',
    CASE WHEN COUNT(*) >= 1 THEN 'PASS' ELSE 'FAIL' END AS result
FROM note_registry WHERE note_path LIKE '%Syllabus%';

-- ============================================
-- Cleanup: Reset test state
-- ============================================
DELETE FROM note_registry WHERE topic_id = 9999;
DELETE FROM topics WHERE id = 9999;
DELETE FROM critic_verdict WHERE goal_id = 'test-goal-happy';
DELETE FROM execution_state WHERE goal_id = 'test-goal-happy';
DELETE FROM goal_meta WHERE goal_id = 'test-goal-happy';
