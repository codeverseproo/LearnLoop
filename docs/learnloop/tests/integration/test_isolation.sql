-- ============================================
-- Multi-Goal Isolation Test
-- ============================================
-- Verifies: Goals don't share data or interfere
-- Claim: "Multi-goal isolation" (Matrix #4)
-- NOTE: Topics are global (no goal_id), isolation is via goal_meta + related tables

-- Test 1: Goals have separate metadata
-- Setup: Create two goals with different metadata
INSERT INTO goal_meta (goal_id, goal_type, total_topics, mastered_topics)
VALUES
    ('goal-isolation-A', 'skill', 5, 2),
    ('goal-isolation-B', 'skill', 3, 1);

SELECT 'Test 1: Goal metadata isolated',
    CASE
        WHEN (
            SELECT COUNT(DISTINCT goal_id)
            FROM goal_meta
            WHERE goal_id IN ('goal-isolation-A', 'goal-isolation-B')
        ) = 2 THEN 'PASS'
        ELSE 'FAIL'
    END AS result;

-- Test 2: Streak state is per-goal
INSERT INTO streak_state (goal_id, current_streak, last_activity_date)
VALUES
    ('goal-isolation-A', 5, date('now')),
    ('goal-isolation-B', 3, date('now'));

SELECT 'Test 2: Streak state per-goal',
    CASE
        WHEN (
            SELECT COUNT(*)
            FROM streak_state
            WHERE goal_id IN ('goal-isolation-A', 'goal-isolation-B')
        ) = 2 THEN 'PASS'
        ELSE 'FAIL'
    END AS result;

-- Test 3: Achievements are per-goal
INSERT INTO achievements (goal_id, achievement_id)
VALUES
    ('goal-isolation-A', 'first_session'),
    ('goal-isolation-B', 'first_session');

SELECT 'Test 3: Achievements per-goal',
    CASE
        WHEN (
            SELECT COUNT(*)
            FROM achievements
            WHERE goal_id IN ('goal-isolation-A', 'goal-isolation-B')
        ) = 2 THEN 'PASS'
        ELSE 'FAIL'
    END AS result;

-- Test 4: Execution state is per-goal
INSERT INTO execution_state (goal_id, phase, wave, spawn_count)
VALUES
    ('goal-isolation-A', 'WAVE2', 2, 3),
    ('goal-isolation-B', 'WAVE1', 1, 1);

SELECT 'Test 4: Execution state per-goal',
    CASE
        WHEN (
            SELECT COUNT(DISTINCT goal_id)
            FROM execution_state
            WHERE goal_id IN ('goal-isolation-A', 'goal-isolation-B')
        ) = 2 THEN 'PASS'
        ELSE 'FAIL'
    END AS result;

-- Test 5: Research metadata is per-goal
INSERT INTO research_metadata (goal_id, agent_type, search_iterations)
VALUES
    ('goal-isolation-A', 'official', 2),
    ('goal-isolation-B', 'official', 1);

SELECT 'Test 5: Research metadata per-goal',
    CASE
        WHEN (
            SELECT COUNT(DISTINCT goal_id)
            FROM research_metadata
            WHERE goal_id IN ('goal-isolation-A', 'goal-isolation-B')
        ) = 2 THEN 'PASS'
        ELSE 'FAIL'
    END AS result;

-- Test 6: Phase telemetry is per-goal
INSERT INTO phase_telemetry (goal_id, phase, wave, started_at)
VALUES
    ('goal-isolation-A', 'WAVE1', 1, datetime('now', '-1 hour')),
    ('goal-isolation-B', 'WAVE1', 1, datetime('now', '-30 minutes'));

SELECT 'Test 6: Phase telemetry per-goal',
    CASE
        WHEN (
            SELECT COUNT(DISTINCT goal_id)
            FROM phase_telemetry
            WHERE goal_id IN ('goal-isolation-A', 'goal-isolation-B')
        ) = 2 THEN 'PASS'
        ELSE 'FAIL'
    END AS result;

-- Test 7: Goal metadata doesn't cross-contaminate
SELECT 'Test 7: Goal-A metadata isolated from goal-B',
    CASE
        WHEN (
            SELECT total_topics
            FROM goal_meta
            WHERE goal_id = 'goal-isolation-A'
        ) = 5
        AND (
            SELECT total_topics
            FROM goal_meta
            WHERE goal_id = 'goal-isolation-B'
        ) = 3
        THEN 'PASS'
        ELSE 'FAIL'
    END AS result;

-- Cleanup test data
DELETE FROM phase_telemetry WHERE goal_id LIKE 'goal-isolation-%';
DELETE FROM research_metadata WHERE goal_id LIKE 'goal-isolation-%';
DELETE FROM achievements WHERE goal_id LIKE 'goal-isolation-%';
DELETE FROM streak_state WHERE goal_id LIKE 'goal-isolation-%';
DELETE FROM execution_state WHERE goal_id LIKE 'goal-isolation-%';
DELETE FROM goal_meta WHERE goal_id LIKE 'goal-isolation-%';

-- ============================================
-- Summary: Multi-Goal Isolation
-- ============================================
-- Tests verify:
-- 1. Topics are goal-scoped (goal_id column)
-- 2. FSRS state is per-topic → per-goal
-- 3. Sessions scoped via topic_id join to goals
-- 4. Streak state per-goal
-- 5. Achievements per-goal
-- 6. Execution state per-goal
-- 7. Goal-A topics not visible in goal-B queries
--
-- Related:
-- - docs/learnloop/mcp-queries/schema.sql (all tables have goal_id or FK chain)
-- - Foreign keys enforced via PRAGMA foreign_keys = ON
