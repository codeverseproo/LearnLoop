-- ============================================
-- Test: Full pipeline happy path
-- Pattern: USER -> Interview -> WAVE1-5 -> Obsidian
-- Verifies: Pipeline executes end-to-end without errors
-- ============================================

-- Setup: Create test goal with interview complete
INSERT OR REPLACE INTO goal_meta (goal_id, goal_type, interview_complete, onboarding_complete, goal_interview_complete)
VALUES ('test-goal-happy', 'exam', 1, 1, 1);

-- ============================================
-- Test 1: WAVE1 Discovery Agents Spawned
-- ============================================
-- Verify WAVE1 discovery agents spawned
SELECT 'Test 1: WAVE1_COUNT',
    CASE WHEN COUNT(*) >= 4 THEN 'PASS' ELSE 'FAIL' END AS result
FROM research_metadata WHERE goal_id = 'test-goal-happy';

-- ============================================
-- Test 2: WAVE3 Critic Verdict Exists
-- ============================================
-- Verify WAVE3 critic verdict exists
SELECT 'Test 2: CRITIC_VERDICT',
    CASE WHEN COUNT(*) >= 1 THEN 'PASS' ELSE 'FAIL' END AS result
FROM critic_verdict WHERE goal_id = 'test-goal-happy';

-- ============================================
-- Test 3: WAVE5 Output Generated
-- ============================================
-- Verify WAVE5 output generated
SELECT 'Test 3: OUTPUT_GENERATED',
    CASE WHEN COUNT(*) >= 1 THEN 'PASS' ELSE 'FAIL' END AS result
FROM note_registry WHERE note_path LIKE '%Syllabus%';

-- ============================================
-- Cleanup: Reset test state
-- ============================================
DELETE FROM goal_meta WHERE goal_id = 'test-goal-happy';
DELETE FROM research_metadata WHERE goal_id = 'test-goal-happy';
DELETE FROM critic_verdict WHERE goal_id = 'test-goal-happy';
