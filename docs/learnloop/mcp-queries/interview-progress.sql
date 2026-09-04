-- ============================================
-- Interview Progress Indicator (UX3)
-- ============================================
-- Returns "Step X of 3" for current interview stage

SELECT
    goal_id,
    goal_type,
    CASE
        WHEN stage_1_complete = 0 THEN 'Step 1 of 3: Goal Definition'
        WHEN stage_2_complete = 0 THEN 'Step 2 of 3: Timeline & Availability'
        WHEN stage_3_complete = 0 THEN 'Step 3 of 3: Learning Preferences'
        ELSE 'Interview Complete'
    END AS current_step,
    stage_1_complete,
    stage_2_complete,
    stage_3_complete,
    goal_interview_complete,
    (stage_1_complete + stage_2_complete + stage_3_complete) * 33 AS progress_pct
FROM goal_meta
WHERE goal_id = :goal_id;
