-- Guard: Interview Complete Check
-- Blocks WAVE1 if interview stages incomplete
-- Must return 1 for both columns to proceed

SELECT
    onboarding_complete,
    goal_interview_complete,
    agent_budget,
    CASE
        WHEN onboarding_complete = 0 THEN 'BLOCK: Stage 1-2 Interview Required'
        WHEN goal_interview_complete = 0 THEN 'BLOCK: Stage 3 Goal Interview Required'
        ELSE 'PASS'
    END AS guard_status,
    CASE
        WHEN onboarding_complete = 0 THEN 'Interview incomplete. Run: /learnloop to start interview.'
        WHEN goal_interview_complete = 0 THEN 'Goal profile needed. Complete Stage 3 interview.'
        ELSE 'Interview complete. Proceed to WAVE1.'
    END AS message
FROM goal_meta
WHERE goal_id = :goal_id;
