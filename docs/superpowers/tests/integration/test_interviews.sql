-- Integration Tests: Interview System
-- Test File: docs/superpowers/tests/integration/test_interviews.sql
-- Purpose: Verify schema migration, JSON storage, and enforcement logic

-- ==============================================================================
-- SETUP: Create test database and apply migration
-- ==============================================================================
-- Run with: sqlite3 test_interviews.db < test_interviews.sql
-- Or against existing: sqlite3 ~/.mit-learning/goals/{goal_id}/memory.db < test_interviews.sql

-- ==============================================================================
-- TEST 1: Schema migration applied
-- ==============================================================================
-- Verify all 7 interview columns exist in goal_meta
SELECT COUNT(*) AS test1_column_count
FROM pragma_table_info('goal_meta')
WHERE name IN (
    'availability_json',
    'learning_style_json',
    'goal_profile_json',
    'note_preferences_json',
    'last_note_preferences_json',
    'onboarding_complete',
    'goal_interview_complete'
);
-- Expected: 7

-- ==============================================================================
-- TEST 2: Default values correct
-- ==============================================================================
-- Create test goal if not exists
INSERT OR IGNORE INTO goal_meta (goal_id, goal_type, created_at, vault_path)
VALUES ('test-goal', 'certification', datetime('now'), '/tmp/test-vault');

-- Verify default empty JSON objects
SELECT
    availability_json AS test2_avail_default,
    learning_style_json AS test2_style_default,
    goal_profile_json AS test2_profile_default,
    note_preferences_json AS test2_note_default
FROM goal_meta
WHERE goal_id = 'test-goal';
-- Expected: '{}', '{}', '{}', '{}'

-- Verify default completion flags
SELECT
    onboarding_complete AS test2_onboard_flag,
    goal_interview_complete AS test2_goal_flag
FROM goal_meta
WHERE goal_id = 'test-goal';
-- Expected: 0, 0

-- ==============================================================================
-- TEST 3: Interview data storage and JSON extraction
-- ==============================================================================
-- Store availability data
UPDATE goal_meta
SET availability_json = json_object(
    'hours_per_day', 2,
    'days_per_week', json_array('mon', 'tue', 'wed', 'thu', 'fri'),
    'preferred_times', json_array('morning', 'evening'),
    'version', 1,
    'completed_at', datetime('now')
)
WHERE goal_id = 'test-goal';

-- Verify JSON extraction
SELECT json_extract(availability_json, '$.hours_per_day') AS test3_hours;
-- Expected: 2

-- Store learning style data
UPDATE goal_meta
SET learning_style_json = json_object(
    'primary_style', 'visual',
    'secondary_style', 'kinesthetic',
    'pacing', 'self-paced',
    'note_format', 'structured',
    'version', 1,
    'completed_at', datetime('now')
)
WHERE goal_id = 'test-goal';

SELECT json_extract(learning_style_json, '$.primary_style') AS test3_primary_style;
-- Expected: 'visual'

-- Store goal profile data
UPDATE goal_meta
SET goal_profile_json = json_object(
    'baseline_knowledge', 'intermediate',
    'baseline_topics', json_array('AWS EC2', 'S3'),
    'exam_date', '2026-12-01',
    'exam_name', 'AWS SAA-C03',
    'passing_score', 720,
    'timeline_weeks', 12,
    'intensity', 'moderate',
    'default_depth', 'detailed',
    'version', 1,
    'completed_at', datetime('now')
)
WHERE goal_id = 'test-goal';

SELECT
    json_extract(goal_profile_json, '$.exam_date') AS test3_exam_date,
    json_extract(goal_profile_json, '$.timeline_weeks') AS test3_weeks;
-- Expected: '2026-12-01', 12

-- Store note preferences
UPDATE goal_meta
SET note_preferences_json = json_object(
    'depth', 'detailed',
    'focus_mode', 'exam-oriented',
    'include_examples', 1,
    'include_exercises', 1,
    'include_flashcards', 0,
    'time_budget_minutes', 30,
    'version', 1,
    'completed_at', datetime('now')
)
WHERE goal_id = 'test-goal';

SELECT json_extract(note_preferences_json, '$.focus_mode') AS test3_focus;
-- Expected: 'exam-oriented'

-- ==============================================================================
-- TEST 4: Enforcement check
-- ==============================================================================
-- Before completion flags set
SELECT
    CASE
        WHEN availability_json = '{}' THEN 'BLOCK'
        WHEN learning_style_json = '{}' THEN 'BLOCK'
        ELSE 'PROCEED'
    END AS test4_enforcement_before
FROM goal_meta
WHERE goal_id = 'test-goal';
-- Expected: 'PROCEED' (data already inserted)

-- Set completion flags
UPDATE goal_meta
SET
    onboarding_complete = 1,
    goal_interview_complete = 1
WHERE goal_id = 'test-goal';

SELECT
    onboarding_complete AS test4_onboard_complete,
    goal_interview_complete AS test4_goal_complete
FROM goal_meta
WHERE goal_id = 'test-goal';
-- Expected: 1, 1

-- ==============================================================================
-- TEST 5: Rollback preserves data (safe transaction-based)
-- ==============================================================================
-- Guard: Skip if real data exists (more than test-goal)
SELECT
    CASE
        WHEN COUNT(*) > 1 THEN 'SKIP: Real data present'
        ELSE 'PROCEED'
    END AS test5_guard
FROM goal_meta
WHERE goal_id != 'test-goal';

-- Safe rollback test using transaction
BEGIN TRANSACTION;

-- Apply test migration (hypothetical new column)
ALTER TABLE goal_meta ADD COLUMN test_column TEXT DEFAULT 'test_value';

-- Verify column added
SELECT COUNT(*) AS test5_column_added
FROM pragma_table_info('goal_meta')
WHERE name = 'test_column';
-- Expected: 1

-- Verify data preserved
SELECT goal_id AS test5_data_preserved
FROM goal_meta
WHERE goal_id = 'test-goal';
-- Expected: 'test-goal'

-- Rollback migration
ROLLBACK;

-- Verify rollback succeeded
SELECT COUNT(*) AS test5_column_removed
FROM pragma_table_info('goal_meta')
WHERE name = 'test_column';
-- Expected: 0

-- ==============================================================================
-- TEST 6: Generated columns indexed (if schema supports)
-- ==============================================================================
-- Note: Generated columns require SQLite 3.31+
-- Skip if generated columns don't exist

-- Check if generated columns exist
SELECT COUNT(*) AS test6_generated_columns
FROM pragma_table_info('goal_meta')
WHERE name IN (
    'exam_date_generated',
    'timeline_weeks_generated',
    'hours_per_day_generated',
    'intensity_generated',
    'primary_style_generated'
);
-- Expected: 5 (if generated columns implemented)

-- If indexes exist, verify they're used
EXPLAIN QUERY PLAN
SELECT goal_id
FROM goal_meta
WHERE json_extract(goal_profile_json, '$.exam_date') > date('now', '+30 days');
-- Expected: Uses index if available (SCAN vs SEARCH)

-- ==============================================================================
-- TEST 7: Per-note preferences transient behavior
-- ==============================================================================
-- Store initial note preferences
UPDATE goal_meta
SET note_preferences_json = json_object(
    'depth', 'overview',
    'focus_mode', 'practical',
    'time_budget_minutes', 15
)
WHERE goal_id = 'test-goal';

-- Copy to last_note_preferences before overwriting
UPDATE goal_meta
SET last_note_preferences_json = note_preferences_json
WHERE goal_id = 'test-goal';

-- Overwrite note_preferences (simulating new note generation)
UPDATE goal_meta
SET note_preferences_json = json_object(
    'depth', 'detailed',
    'focus_mode', 'exam-oriented',
    'time_budget_minutes', 45
)
WHERE goal_id = 'test-goal';

-- Verify last_note_preferences preserved
SELECT
    json_extract(last_note_preferences_json, '$.depth') AS test7_last_depth,
    json_extract(note_preferences_json, '$.depth') AS test7_current_depth
FROM goal_meta
WHERE goal_id = 'test-goal';
-- Expected: 'overview', 'detailed'

-- ==============================================================================
-- TEST 8: JSON array access and modification
-- ==============================================================================
-- Verify baseline_topics array
SELECT
    json_extract(goal_profile_json, '$.baseline_topics[0]') AS test8_first_topic,
    json_array_length(json_extract(goal_profile_json, '$.baseline_topics')) AS test8_topic_count
FROM goal_meta
WHERE goal_id = 'test-goal';
-- Expected: 'AWS EC2', 2

-- ==============================================================================
-- TEST 9: Combined interview status check
-- ==============================================================================
-- Single query to check all interview completion status
SELECT
    goal_id,
    CASE
        WHEN availability_json = '{}'
            OR learning_style_json = '{}'
            THEN 'onboarding_incomplete'
        WHEN goal_profile_json = '{}'
            THEN 'goal_interview_incomplete'
        WHEN onboarding_complete = 0
            THEN 'onboarding_flag_not_set'
        WHEN goal_interview_complete = 0
            THEN 'goal_flag_not_set'
        ELSE 'all_complete'
    END AS test9_interview_status
FROM goal_meta
WHERE goal_id = 'test-goal';
-- Expected: 'all_complete'

-- ==============================================================================
-- TEST 10: Update specific JSON fields without overwriting
-- ==============================================================================
-- Update only exam_date without touching other fields
UPDATE goal_meta
SET goal_profile_json = json_patch(
    goal_profile_json,
    json_object('exam_date', '2026-12-15')
)
WHERE goal_id = 'test-goal';

SELECT
    json_extract(goal_profile_json, '$.exam_date') AS test10_new_exam_date,
    json_extract(goal_profile_json, '$.exam_name') AS test10_unchanged_exam_name,
    json_extract(goal_profile_json, '$.timeline_weeks') AS test10_unchanged_weeks
FROM goal_meta
WHERE goal_id = 'test-goal';
-- Expected: '2026-12-15', 'AWS SAA-C03', 12

-- ==============================================================================
-- CLEANUP: Remove test goal
-- ==============================================================================
-- Uncomment to clean up test data
-- DELETE FROM goal_meta WHERE goal_id = 'test-goal';

-- ==============================================================================
-- TEST SUMMARY
-- ==============================================================================
-- Test 1: Schema migration columns (Expected: 7 columns)
-- Test 2: Default values (Expected: '{}', 0 defaults)
-- Test 3: JSON storage and extraction (Expected: Correct values)
-- Test 4: Enforcement check (Expected: PROCEED after data)
-- Test 5: Rollback preserves data (Expected: Column removed)
-- Test 6: Generated columns indexed (Expected: 5 columns or skip)
-- Test 7: Per-note transient behavior (Expected: Last prefs preserved)
-- Test 8: JSON array access (Expected: 'AWS EC2', 2)
-- Test 9: Combined status check (Expected: 'all_complete')
-- Test 10: Partial JSON update (Expected: Updated date, rest unchanged)
