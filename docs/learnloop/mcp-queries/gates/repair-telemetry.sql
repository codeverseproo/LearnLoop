-- ============================================
-- P0-6: Repair Agent Spawn Telemetry
-- Track WAVE4 repair loop execution
-- ============================================

-- On repair agent spawn
INSERT INTO phase_telemetry (
    goal_id, phase, wave, agent_type, started_at, phase_status
) VALUES (
    :goal_id, 'WAVE4_REPAIR', 4, 'repair', CURRENT_TIMESTAMP, 'running'
);

-- Track repair agent in execution_state
UPDATE execution_state
SET
    repair_agents_spawned = repair_agents_spawned + 1,
    last_attempt = CURRENT_TIMESTAMP
WHERE goal_id = :goal_id AND phase = 'WAVE4_REPAIR';

-- Log to agent_spawn_log
INSERT INTO agent_spawn_log (
    goal_id, phase, wave, agent_type, agent_name, spawned_at, status
) VALUES (
    :goal_id, 'WAVE4_REPAIR', 4, 'repair', :agent_name, CURRENT_TIMESTAMP, 'running'
);

-- On repair completion
UPDATE phase_telemetry
SET
    completed_at = CURRENT_TIMESTAMP,
    duration_seconds = CAST((julianday(CURRENT_TIMESTAMP) - julianday(started_at)) * 86400 AS INTEGER),
    success = :success,
    gate_result = CASE WHEN :success = 1 THEN 'PASS' ELSE 'FAIL' END,
    phase_status = CASE WHEN :success = 1 THEN 'complete' ELSE 'failed' END
WHERE goal_id = :goal_id
  AND phase = 'WAVE4_REPAIR'
  AND completed_at IS NULL
ORDER BY started_at DESC
LIMIT 1;
