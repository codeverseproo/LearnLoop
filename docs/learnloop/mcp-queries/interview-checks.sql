-- Interview Enforcement Checks
-- Plan: ralplan-note-generation-interview-system
-- Purpose: Pre-workflow validation queries for mandatory interview completion

--------------------------------------------------------------------------------
-- 1. Onboarding Status Check
-- Returns: 1 if complete, 0 if incomplete
-- Usage: Run before any goal creation workflow
--------------------------------------------------------------------------------

SELECT onboarding_complete
FROM goal_meta
WHERE goal_id = ?;

--------------------------------------------------------------------------------
-- 2. Goal Interview Status Check
-- Returns: 1 if complete, 0 if incomplete
-- Usage: Run before syllabus generation workflow
--------------------------------------------------------------------------------

SELECT goal_interview_complete
FROM goal_meta
WHERE goal_id = ?;

--------------------------------------------------------------------------------
-- 3. Full Interview Data Retrieval
-- Returns: All interview JSON for note generation
-- Usage: Run before note generation to apply preferences
--------------------------------------------------------------------------------

SELECT
    availability_json,
    learning_style_json,
    goal_profile_json,
    note_preferences_json,
    last_note_preferences_json
FROM goal_meta
WHERE goal_id = ?;

--------------------------------------------------------------------------------
-- 4. Onboarding Validation
-- Returns: 'COMPLETE' or 'INCOMPLETE'
-- Usage: Comprehensive check of onboarding data
--------------------------------------------------------------------------------

SELECT
    CASE
        WHEN availability_json = '{}' THEN 'INCOMPLETE'
        WHEN learning_style_json = '{}' THEN 'INCOMPLETE'
        WHEN json_extract(availability_json, '$.hours_per_day') IS NULL THEN 'INCOMPLETE'
        WHEN json_extract(learning_style_json, '$.primary_style') IS NULL THEN 'INCOMPLETE'
        ELSE 'COMPLETE'
    END AS onboarding_status,
    availability_json,
    learning_style_json
FROM goal_meta
WHERE goal_id = ?;

--------------------------------------------------------------------------------
-- 5. Goal Interview Validation
-- Returns: 'COMPLETE' or 'INCOMPLETE'
-- Usage: Comprehensive check of per-goal interview data
--------------------------------------------------------------------------------

SELECT
    CASE
        WHEN goal_profile_json = '{}' THEN 'INCOMPLETE'
        WHEN json_extract(goal_profile_json, '$.intensity') IS NULL THEN 'INCOMPLETE'
        -- P0 fix: goal_type-specific validation
        WHEN goal_type = 'exam' AND json_extract(goal_profile_json, '$.exam_date') IS NULL THEN 'INCOMPLETE'
        WHEN goal_type = 'exam' AND json_extract(goal_profile_json, '$.passing_score') IS NULL THEN 'INCOMPLETE'
        WHEN goal_type IN ('skill', 'degree', 'topic') AND json_extract(goal_profile_json, '$.timeline_weeks') IS NULL THEN 'INCOMPLETE'
        WHEN goal_type IN ('skill', 'degree', 'topic') AND json_extract(goal_profile_json, '$.baseline_knowledge') IS NULL THEN 'INCOMPLETE'
        ELSE 'COMPLETE'
    END AS goal_interview_status,
    goal_profile_json,
    goal_type
FROM goal_meta
WHERE goal_id = ?;

--------------------------------------------------------------------------------
-- 6. Note Preferences Check
-- Returns: Current preferences or last used preferences
-- Usage: Per-note interview is NOT mandatory - falls back to last used
--------------------------------------------------------------------------------

SELECT
    CASE
        WHEN note_preferences_json != '{}' THEN note_preferences_json
        ELSE last_note_preferences_json
    END AS effective_preferences
FROM goal_meta
WHERE goal_id = ?;

--------------------------------------------------------------------------------
-- 7. Blocking Status Summary
-- Returns: What's blocking workflow (if anything)
-- Usage: Single query for workflow routing
--------------------------------------------------------------------------------

SELECT
    goal_id,
    CASE
        WHEN onboarding_complete = 0 THEN 'BLOCK: onboarding_required'
        WHEN goal_interview_complete = 0 THEN 'BLOCK: goal_interview_required'
        ELSE 'PROCEED'
    END AS workflow_status,
    onboarding_complete,
    goal_interview_complete
FROM goal_meta
WHERE goal_id = ?;

--------------------------------------------------------------------------------
-- 8. Get Interview Data for Syllabus Generation
-- Returns: Merged interview data for syllabus personalization
-- Usage: Pass to discovery agents and syllabus generation
--------------------------------------------------------------------------------

SELECT
    json_extract(availability_json, '$.hours_per_day') AS hours_per_day,
    json_extract(availability_json, '$.days_per_week') AS days_per_week,
    json_extract(availability_json, '$.preferred_times') AS preferred_times,
    json_extract(learning_style_json, '$.primary_style') AS learning_style,
    json_extract(learning_style_json, '$.pacing') AS pacing,
    json_extract(learning_style_json, '$.note_format') AS note_format,
    json_extract(goal_profile_json, '$.baseline_knowledge') AS baseline_knowledge,
    json_extract(goal_profile_json, '$.exam_date') AS exam_date,
    json_extract(goal_profile_json, '$.exam_name') AS exam_name,
    json_extract(goal_profile_json, '$.passing_score') AS passing_score,
    json_extract(goal_profile_json, '$.timeline_weeks') AS timeline_weeks,
    json_extract(goal_profile_json, '$.intensity') AS intensity,
    json_extract(goal_profile_json, '$.default_depth') AS default_depth
FROM goal_meta
WHERE goal_id = ?;

--------------------------------------------------------------------------------
-- 9. Update Onboarding Complete Flag
-- Usage: After both availability and learning_style interviews complete
--------------------------------------------------------------------------------

UPDATE goal_meta
SET onboarding_complete = 1
WHERE goal_id = ?
  AND availability_json != '{}'
  AND learning_style_json != '{}';

--------------------------------------------------------------------------------
-- 10. Update Goal Interview Complete Flag
-- Usage: After all 4 per-goal interviews complete
--------------------------------------------------------------------------------

UPDATE goal_meta
SET goal_interview_complete = 1
WHERE goal_id = ?
  AND goal_profile_json != '{}'
  AND onboarding_complete = 1;

--------------------------------------------------------------------------------
-- 11. Store Note Preferences (Transient)
-- Usage: Before each note generation (overwrites previous)
--------------------------------------------------------------------------------

UPDATE goal_meta
SET note_preferences_json = json(?)
WHERE goal_id = ?;

--------------------------------------------------------------------------------
-- 12. Archive Last Note Preferences
-- Usage: After note generation, save for reuse
--------------------------------------------------------------------------------

UPDATE goal_meta
SET last_note_preferences_json = note_preferences_json,
    note_preferences_json = '{}'
WHERE goal_id = ?;

--------------------------------------------------------------------------------
-- 13. Check User Has Any Complete Onboarding
-- Usage: Determine if this is first skill use across all goals
--------------------------------------------------------------------------------

SELECT COUNT(*) AS goals_with_onboarding
FROM goal_meta
WHERE onboarding_complete = 1;

--------------------------------------------------------------------------------
-- 14. Get All Goals Requiring Interview
-- Usage: Dashboard/alert for incomplete interviews
--------------------------------------------------------------------------------

SELECT
    goal_id,
    CASE
        WHEN onboarding_complete = 0 THEN 'onboarding'
        WHEN goal_interview_complete = 0 THEN 'goal_interview'
        ELSE 'complete'
    END AS interview_status,
    created_at
FROM goal_meta
WHERE goal_id = ?
ORDER BY created_at DESC;
