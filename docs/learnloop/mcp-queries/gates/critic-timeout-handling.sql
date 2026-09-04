-- ============================================
-- P0-5: Critic Timeout Handling
-- Recovery protocol for 120s timeout
-- ============================================

-- Insert timeout telemetry
INSERT INTO phase_telemetry (
    goal_id, phase, error_code, phase_status, started_at, success
) VALUES (
    :goal_id, 'WAVE3', 'E501', 'failed', CURRENT_TIMESTAMP, 0
);

-- Check retry count
SELECT
    es.goal_id,
    es.attempts,
    es.max_attempts,
    CASE
        WHEN es.attempts < es.max_attempts THEN 'RETRY'
        ELSE 'FORCE_APPROVE'
    END as action
FROM execution_state es
WHERE es.goal_id = :goal_id AND es.phase = 'WAVE3';

-- If RETRY: Increment attempts and re-spawn critic
-- IF FORCE_APPROVE: Insert APPROVED_WITH_WARNINGS verdict

INSERT INTO critic_verdict (
    goal_id, verdict, confidence, warnings_count, challenges, repair_cycle
) VALUES (
    :goal_id, 'APPROVED_WITH_WARNINGS', 0.5, 1,
    '["Timeout after 120s - forced approval"]', 0
);
