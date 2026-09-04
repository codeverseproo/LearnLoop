-- ============================================
-- Migration 007: P3 Observability
-- Date: 2026-09-04
-- SLI/SLO tracking, latency metrics, MTTR, agent efficiency, rate limiting, audit
-- ============================================

-- ============================================
-- 1. SLI/SLO Definitions Table
-- ============================================
-- Tracks service level objectives with current performance
CREATE TABLE IF NOT EXISTS slo_definitions (
    slo_name TEXT PRIMARY KEY,
    description TEXT NOT NULL,
    target REAL NOT NULL CHECK(target >= 0.0 AND target <= 1.0),
    current REAL DEFAULT 0.0 CHECK(current >= 0.0 AND current <= 1.0),
    status TEXT DEFAULT 'unknown' CHECK(status IN ('healthy', 'degraded', 'critical', 'unknown')),
    measurement_period TEXT DEFAULT '24h' CHECK(measurement_period IN ('1h', '24h', '7d', '30d')),
    last_measured TIMESTAMP,
    last_breach TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default SLOs
INSERT OR IGNORE INTO slo_definitions (slo_name, description, target, measurement_period) VALUES
('agent_success_rate', 'Agent spawn success rate', 0.95, '24h'),
('phase_completion_latency', 'Phase completion within SLA', 0.90, '24h'),
('critic_approval_rate', 'Critic first-pass approval rate', 0.70, '24h'),
('budget_accuracy', 'Budget prediction accuracy', 0.85, '7d'),
('interview_completion', 'Interview completion rate', 0.95, '24h'),
('fsrs_prediction_accuracy', 'FSRS scheduling accuracy', 0.80, '30d');

-- ============================================
-- 2. Percentile Latencies View
-- ============================================
-- Calculates p50, p95, p99 latencies by phase
CREATE VIEW IF NOT EXISTS phase_latency_percentiles AS
WITH phase_durations AS (
    SELECT
        phase,
        duration_seconds,
        ROW_NUMBER() OVER (PARTITION BY phase ORDER BY duration_seconds) AS row_num,
        COUNT(*) OVER (PARTITION BY phase) AS total_count
    FROM phase_telemetry
    WHERE duration_seconds IS NOT NULL
      AND completed_at IS NOT NULL
)
SELECT
    phase,
    AVG(duration_seconds) AS avg_duration_seconds,
    MIN(duration_seconds) AS min_duration_seconds,
    MAX(duration_seconds) AS max_duration_seconds,
    (SELECT duration_seconds FROM phase_durations pd2
     WHERE pd2.phase = pd.phase
       AND pd2.row_num >= CAST(pd.total_count * 0.50 AS INTEGER)
     ORDER BY duration_seconds LIMIT 1) AS p50_seconds,
    (SELECT duration_seconds FROM phase_durations pd2
     WHERE pd2.phase = pd.phase
       AND pd2.row_num >= CAST(pd.total_count * 0.95 AS INTEGER)
     ORDER BY duration_seconds LIMIT 1) AS p95_seconds,
    (SELECT duration_seconds FROM phase_durations pd2
     WHERE pd2.phase = pd.phase
       AND pd2.row_num >= CAST(pd.total_count * 0.99 AS INTEGER)
     ORDER BY duration_seconds LIMIT 1) AS p99_seconds,
    total_count AS sample_size
FROM phase_durations pd
GROUP BY phase;

-- ============================================
-- 3. MTTR Calculation View
-- ============================================
-- Mean time to recovery per error category
CREATE VIEW IF NOT EXISTS mttr_by_category AS
WITH error_events AS (
    SELECT
        er.category,
        er.error_code,
        pt.goal_id,
        pt.phase,
        pt.started_at AS error_start,
        pt.completed_at AS error_end,
        pt.duration_seconds
    FROM phase_telemetry pt
    JOIN error_registry er ON pt.error_code = er.error_code
    WHERE pt.success = 0
      AND pt.completed_at IS NOT NULL
),
recovery_times AS (
    SELECT
        category,
        error_code,
        goal_id,
        phase,
        error_start,
        error_end,
        duration_seconds,
        -- Time to next successful phase completion after error
        (SELECT MIN(pt2.started_at) - e.error_end
         FROM phase_telemetry pt2
         WHERE pt2.goal_id = e.goal_id
           AND pt2.phase = e.phase
           AND pt2.success = 1
           AND pt2.started_at > e.error_end) AS recovery_time_seconds
    FROM error_events e
)
SELECT
    category,
    error_code,
    COUNT(*) AS incident_count,
    AVG(duration_seconds) AS avg_error_duration_seconds,
    AVG(recovery_time_seconds) AS mttr_seconds,
    MAX(recovery_time_seconds) AS max_recovery_seconds,
    MIN(recovery_time_seconds) AS min_recovery_seconds
FROM recovery_times
WHERE recovery_time_seconds IS NOT NULL
GROUP BY category, error_code;

-- ============================================
-- 4. Agent Efficiency Metrics Table
-- ============================================
-- Tracks agent performance by type
CREATE TABLE IF NOT EXISTS agent_efficiency_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_type TEXT NOT NULL,
    measurement_period_start TIMESTAMP NOT NULL,
    measurement_period_end TIMESTAMP NOT NULL,
    total_runs INTEGER DEFAULT 0,
    successful_runs INTEGER DEFAULT 0,
    failed_runs INTEGER DEFAULT 0,
    timeout_runs INTEGER DEFAULT 0,
    avg_duration_seconds REAL DEFAULT 0.0,
    min_duration_seconds REAL,
    max_duration_seconds REAL,
    total_cost_usd REAL DEFAULT 0.0,
    avg_cost_per_run_usd REAL DEFAULT 0.0,
    success_rate REAL DEFAULT 0.0 CHECK(success_rate >= 0.0 AND success_rate <= 1.0),
    throughput_per_hour REAL DEFAULT 0.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(agent_type, measurement_period_start, measurement_period_end)
);

CREATE INDEX IF NOT EXISTS idx_agent_eff_type ON agent_efficiency_metrics(agent_type);
CREATE INDEX IF NOT EXISTS idx_agent_eff_period ON agent_efficiency_metrics(measurement_period_start, measurement_period_end);

-- View for current agent efficiency (last 24h)
CREATE VIEW IF NOT EXISTS agent_efficiency_current AS
SELECT
    agent_type,
    total_runs,
    successful_runs,
    failed_runs,
    timeout_runs,
    avg_duration_seconds,
    success_rate,
    avg_cost_per_run_usd,
    throughput_per_hour
FROM agent_efficiency_metrics
WHERE measurement_period_end >= datetime('now', '-24 hours')
ORDER BY measurement_period_end DESC;

-- ============================================
-- 5. Rate Limiting Config Table
-- ============================================
-- Controls agent spawn rate limiting
CREATE TABLE IF NOT EXISTS rate_limit_config (
    agent_type TEXT PRIMARY KEY,
    max_spawns_per_minute INTEGER NOT NULL DEFAULT 10 CHECK(max_spawns_per_minute > 0),
    window_start TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    current_spawns INTEGER DEFAULT 0,
    last_reset TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    enabled INTEGER DEFAULT 1 CHECK(enabled IN (0, 1)),
    cooldown_seconds INTEGER DEFAULT 60 CHECK(cooldown_seconds > 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default rate limits
INSERT OR IGNORE INTO rate_limit_config (agent_type, max_spawns_per_minute, cooldown_seconds) VALUES
('official', 20, 60),
('academic', 15, 60),
('practical', 10, 90),
('expert', 5, 120),
('critic', 10, 60),
('research', 30, 30);

-- ============================================
-- 6. Audit Log Table for Goal Deletions
-- ============================================
-- Immutable audit trail for goal deletions
CREATE TABLE IF NOT EXISTS goal_deletion_audit (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    goal_type TEXT,
    vault_path TEXT,
    topic_count INTEGER DEFAULT 0,
    session_count INTEGER DEFAULT 0,
    total_spawns INTEGER DEFAULT 0,
    deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_by TEXT NOT NULL,
    deletion_reason TEXT NOT NULL CHECK(deletion_reason IN ('user_request', 'cascade_delete', 'data_cleanup', 'archived', 'system_error')),
    notes TEXT,
    -- Store snapshot of goal metadata for forensic analysis
    goal_snapshot TEXT,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_deletion_audit_goal ON goal_deletion_audit(goal_id);
CREATE INDEX IF NOT EXISTS idx_deletion_audit_deleted_by ON goal_deletion_audit(deleted_by);
CREATE INDEX IF NOT EXISTS idx_deletion_audit_timestamp ON goal_deletion_audit(deleted_at);
CREATE INDEX IF NOT EXISTS idx_deletion_audit_reason ON goal_deletion_audit(deletion_reason);

-- ============================================
-- Additional Observability Indexes
-- ============================================

-- Index for agent spawn log time-based queries
CREATE INDEX IF NOT EXISTS idx_agent_spawn_time ON agent_spawn_log(spawned_at);

-- Index for phase telemetry success filtering
CREATE INDEX IF NOT EXISTS idx_telemetry_success ON phase_telemetry(success);

-- Index for error code lookups
CREATE INDEX IF NOT EXISTS idx_telemetry_error_code ON phase_telemetry(error_code);

-- Index for budget status tracking
CREATE INDEX IF NOT EXISTS idx_execution_budget ON execution_state(goal_id, agent_spawns, user_budget);

-- ============================================
-- Observability Views
-- ============================================

-- Current system health dashboard
CREATE VIEW IF NOT EXISTS system_health_dashboard AS
SELECT
    'agent_success_rate' AS metric,
    (SELECT ROUND(AVG(CAST(success AS REAL)), 2) FROM agent_spawn_log WHERE spawned_at >= datetime('now', '-24 hours')) AS current_value,
    0.95 AS target,
    CASE
        WHEN (SELECT AVG(CAST(success AS REAL)) FROM agent_spawn_log WHERE spawned_at >= datetime('now', '-24 hours')) >= 0.95 THEN 'healthy'
        WHEN (SELECT AVG(CAST(success AS REAL)) FROM agent_spawn_log WHERE spawned_at >= datetime('now', '-24 hours')) >= 0.85 THEN 'degraded'
        ELSE 'critical'
    END AS status
UNION ALL
SELECT
    'active_goals',
    (SELECT COUNT(DISTINCT goal_id) FROM execution_state WHERE phase_complete = 0),
    NULL,
    CASE WHEN (SELECT COUNT(DISTINCT goal_id) FROM execution_state WHERE phase_complete = 0) < 100 THEN 'healthy' ELSE 'warning' END
UNION ALL
SELECT
    'budget_utilization',
    (SELECT ROUND(SUM(agent_spawns) * 1.0 / NULLIF(SUM(user_budget), 0), 2) FROM execution_state WHERE user_budget > 0),
    0.85,
    CASE
        WHEN (SELECT SUM(agent_spawns) * 1.0 / NULLIF(SUM(user_budget), 0) FROM execution_state WHERE user_budget > 0) >= 0.90 THEN 'critical'
        WHEN (SELECT SUM(agent_spawns) * 1.0 / NULLIF(SUM(user_budget), 0) FROM execution_state WHERE user_budget > 0) >= 0.75 THEN 'warning'
        ELSE 'healthy'
    END
UNION ALL
SELECT
    'error_rate_24h',
    (SELECT ROUND(COUNT(CASE WHEN success = 0 THEN 1 END) * 1.0 / COUNT(*), 2) FROM phase_telemetry WHERE started_at >= datetime('now', '-24 hours')),
    0.05,
    CASE
        WHEN (SELECT COUNT(CASE WHEN success = 0 THEN 1 END) * 1.0 / COUNT(*) FROM phase_telemetry WHERE started_at >= datetime('now', '-24 hours')) >= 0.10 THEN 'critical'
        WHEN (SELECT COUNT(CASE WHEN success = 0 THEN 1 END) * 1.0 / COUNT(*) FROM phase_telemetry WHERE started_at >= datetime('now', '-24 hours')) >= 0.05 THEN 'degraded'
        ELSE 'healthy'
    END;

-- ============================================
-- Trigger for SLO Status Updates
-- ============================================
CREATE TRIGGER IF NOT EXISTS trg_update_slo_status
AFTER UPDATE OF current ON slo_definitions
BEGIN
    UPDATE slo_definitions
    SET status = CASE
        WHEN NEW.current >= NEW.target THEN 'healthy'
        WHEN NEW.current >= NEW.target * 0.9 THEN 'degraded'
        ELSE 'critical'
    END,
    updated_at = CURRENT_TIMESTAMP
    WHERE slo_name = NEW.slo_name;
END;

-- ============================================
-- Migration Notes
-- ============================================
--
-- P3 Observability Stack:
-- 1. SLI/SLO Tracking: slo_definitions table + auto-updating status trigger
-- 2. Latency Percentiles: phase_latency_percentiles view (p50/p95/p99 by phase)
-- 3. MTTR Metrics: mttr_by_category view (mean time to recovery per error type)
-- 4. Agent Efficiency: agent_efficiency_metrics table + current view
-- 5. Rate Limiting: rate_limit_config table for spawn throttling
-- 6. Audit Trail: goal_deletion_audit table for forensic logging
--
-- Usage:
-- - Query system_health_dashboard for real-time health check
-- - Use phase_latency_percentiles for SLA monitoring
-- - Query mttr_by_category for operational insights
-- - Insert into agent_efficiency_metrics from telemetry aggregation jobs
-- - Enforce rate limits via rate_limit_config in orchestrator
-- - Log deletions to goal_deletion_audit before DELETE operations
--
-- Next Steps:
-- - Add telemetry aggregator job to populate agent_efficiency_metrics
-- - Implement rate limiting middleware using rate_limit_config
-- - Create alerts for SLO breaches (status = 'critical')
