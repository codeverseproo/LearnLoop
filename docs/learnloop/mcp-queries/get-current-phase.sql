-- ============================================
-- Current Phase Progress Dashboard (UX1)
-- ============================================
-- Zero-state progress dashboard showing current phase and progress percentage

SELECT
    gm.goal_id,
    COALESCE(pt.phase, 'ONBOARDING') AS current_phase,
    COALESCE(pt.phase_status, 'pending') AS phase_status,
    CASE
        WHEN pt.phase IS NULL THEN 0
        WHEN pt.phase = 'WAVE1_RUNNING' THEN 20
        WHEN pt.phase = 'WAVE2_RUNNING' THEN 40
        WHEN pt.phase = 'WAVE3_RUNNING' THEN 60
        WHEN pt.phase = 'WAVE4_REPAIR' THEN 80
        WHEN pt.phase = 'WAVE5_OUTPUT' THEN 95
        ELSE 100
    END AS progress_pct,
    gm.goal_type,
    gm.created_at,
    pt.started_at AS phase_started,
    gm.agent_budget,
    gm.budget_enforcement
FROM goal_meta gm
LEFT JOIN phase_telemetry pt
    ON gm.goal_id = pt.goal_id
    AND pt.completed_at IS NULL
WHERE gm.goal_id = :goal_id;
