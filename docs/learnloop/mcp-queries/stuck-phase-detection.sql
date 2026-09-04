-- ============================================
-- Stuck Phase Detection - Operational Alert
-- ============================================
-- Identify phases running longer than 30 minutes without completion
-- Detects hung agent spawns, failed executions, and timeout conditions
--
-- Parameters: :timeout_minutes (default: 30)
--
-- Returns: Active phases exceeding threshold with diagnostic info
--
-- Usage: Run every 5 minutes for operational monitoring
-- ============================================

SELECT
    es.goal_id,
    es.phase,
    es.wave,
    es.agent_type,
    es.attempts,
    es.max_attempts,
    es.last_attempt,
    es.last_failure_reason,
    es.error_code,
    es.repair_cycles,
    CAST((julianday('now') - julianday(es.last_attempt)) * 24 * 60 AS INTEGER) AS minutes_running,
    gm.goal_type,
    gm.agent_budget,
    gm.budget_enforcement
FROM execution_state es
JOIN goal_meta gm ON es.goal_id = gm.goal_id
WHERE es.phase_complete = 0
  AND CAST((julianday('now') - julianday(es.last_attempt)) * 24 * 60 AS INTEGER) > :timeout_minutes
ORDER BY minutes_running DESC;
