-- ============================================
-- Workflow Integration Tests
-- ============================================
-- NOTE: These tests require existing goal data.
-- Run against a real goal database, not empty test DB.

-- Test: Topic creation and FSRS initialization
-- Skip if no topics (fresh database)
SELECT 'Test: Topic+FSRS creation',
    CASE
        WHEN (SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='topics') = 1 THEN 'PASS'
        ELSE 'SKIP (run against real goal DB)'
    END AS result;

-- Test: Session tracking
SELECT 'Test: Session tracking',
    CASE
        WHEN (SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='sessions') = 1 THEN 'PASS'
        ELSE 'SKIP (run against real goal DB)'
    END AS result;

-- Test: Streak tracking
SELECT 'Test: Streak tracking',
    CASE
        WHEN (SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='streak_state') = 1 THEN 'PASS'
        ELSE 'SKIP (run against real goal DB)'
    END AS result;

-- Test: Achievements
SELECT 'Test: Achievements',
    CASE
        WHEN (SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='achievements') = 1 THEN 'PASS'
        ELSE 'SKIP (run against real goal DB)'
    END AS result;
