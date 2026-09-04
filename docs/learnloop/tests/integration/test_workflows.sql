-- ============================================
-- Workflow Integration Tests
-- ============================================

-- Test: Topic creation and FSRS initialization
SELECT 'Test: Topic+FSRS creation',
    CASE WHEN (SELECT COUNT(*) FROM topics) > 0 THEN 'PASS' ELSE 'FAIL' END AS result;

-- Test: Session tracking
SELECT 'Test: Session tracking',
    CASE WHEN (SELECT COUNT(*) FROM sessions) > 0 THEN 'PASS' ELSE 'FAIL' END AS result;

-- Test: Streak tracking
SELECT 'Test: Streak tracking',
    CASE WHEN (SELECT COUNT(*) FROM streak_state) > 0 THEN 'PASS' ELSE 'FAIL' END AS result;

-- Test: Achievements
SELECT 'Test: Achievements',
    CASE WHEN (SELECT COUNT(*) FROM achievements) > 0 THEN 'PASS' ELSE 'FAIL' END AS result;
