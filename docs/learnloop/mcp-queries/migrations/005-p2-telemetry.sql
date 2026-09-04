-- ============================================
-- Migration 005: P2 Telemetry Items
-- Date: 2026-09-04
-- Advanced observability and performance tracking
-- ============================================

-- ============================================
-- 1. Metric Aggregations Table
-- ============================================

-- Aggregated metrics per phase for performance analysis
CREATE TABLE IF NOT EXISTS metric_aggregations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phase TEXT NOT NULL,
    aggregation_period TEXT NOT NULL CHECK(aggregation_period IN ('hour', 'day', 'week')),
    period_start TIMESTAMP NOT NULL,
    avg_duration_seconds REAL,
    p50_duration_seconds REAL,
    p95_duration_seconds REAL,
    p99_duration_seconds REAL,
    agent_count INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    failure_count INTEGER DEFAULT 0,
    total_executions INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(phase, aggregation_period, period_start)
);

CREATE INDEX IF NOT EXISTS idx_metric_agg_phase ON metric_aggregations(phase);
CREATE INDEX IF NOT EXISTS idx_metric_agg_period ON metric_aggregations(aggregation_period, period_start);

-- ============================================
-- 2. Stuck Phase Detection View
-- ============================================

-- View to detect phases running longer than 30 minutes
CREATE VIEW IF NOT EXISTS stuck_phase_detection AS
SELECT
    goal_id,
    phase,
    wave,
    started_at,
    (julianday(CURRENT_TIMESTAMP) - julianday(started_at)) * 86400 AS duration_seconds,
    agent_type,
    phase_status
FROM phase_telemetry
WHERE phase_status = 'running'
  AND completed_at IS NULL
  AND (julianday(CURRENT_TIMESTAMP) - julianday(started_at)) * 86400 > 1800
ORDER BY started_at ASC;

-- ============================================
-- 3. Queue Depth Tracking Table
-- ============================================

-- Track pending phases and queue backlog
CREATE TABLE IF NOT EXISTS queue_depth (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    phase TEXT NOT NULL,
    queue_status TEXT DEFAULT 'pending' CHECK(queue_status IN ('pending', 'processing', 'completed', 'cancelled')),
    priority INTEGER DEFAULT 0,
    enqueued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    wait_time_seconds INTEGER,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id)
);

CREATE INDEX IF NOT EXISTS idx_queue_depth_goal ON queue_depth(goal_id);
CREATE INDEX IF NOT EXISTS idx_queue_depth_status ON queue_depth(queue_status);
CREATE INDEX IF NOT EXISTS idx_queue_depth_enqueued ON queue_depth(enqueued_at);

-- ============================================
-- 4. Error Rate Tracking View
-- ============================================

-- View for error rates per hour by category
CREATE VIEW IF NOT EXISTS error_rate_by_hour AS
SELECT
    strftime('%Y-%m-%d %H:00:00', triggered_at) AS hour_bucket,
    er.category,
    er.severity,
    COUNT(*) AS error_count,
    COUNT(DISTINCT ae.goal_id) AS unique_goals_affected,
    SUM(CASE WHEN ae.resolved = 0 THEN 1 ELSE 0 END) AS unresolved_count
FROM alert_events ae
JOIN alert_rules ar ON ae.rule_id = ar.id
LEFT JOIN error_registry er ON ar.condition_type LIKE '%' || er.category || '%'
WHERE ae.triggered_at >= datetime('now', '-7 days')
GROUP BY hour_bucket, er.category, er.severity
ORDER BY hour_bucket DESC, error_count DESC;

-- Alternative: Direct phase_telemetry error tracking
CREATE VIEW IF NOT EXISTS error_rate_from_telemetry AS
SELECT
    strftime('%Y-%m-%d %H:00:00', started_at) AS hour_bucket,
    error_code,
    COUNT(*) AS error_count,
    COUNT(DISTINCT goal_id) AS unique_goals_affected,
    AVG(duration_seconds) AS avg_failure_duration
FROM phase_telemetry
WHERE success = 0
  AND error_code IS NOT NULL
  AND started_at >= datetime('now', '-7 days')
GROUP BY hour_bucket, error_code
ORDER BY hour_bucket DESC, error_count DESC;

-- ============================================
-- 5. Interview Abandonment Tracking Table
-- ============================================

-- Track where users abandon the interview process
CREATE TABLE IF NOT EXISTS interview_abandonment (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    interview_stage TEXT NOT NULL CHECK(interview_stage IN ('onboarding', 'per_goal', 'per_note', 'goal_interview')),
    stage_progress REAL DEFAULT 0.0 CHECK(stage_progress >= 0.0 AND stage_progress <= 1.0),
    last_question_asked TEXT,
    abandonment_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    return_count INTEGER DEFAULT 0,
    last_return_timestamp TIMESTAMP,
    completion_status TEXT DEFAULT 'abandoned' CHECK(completion_status IN ('abandoned', 'resumed', 'completed')),
    time_in_stage_seconds INTEGER,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id)
);

CREATE INDEX IF NOT EXISTS idx_abandonment_goal ON interview_abandonment(goal_id);
CREATE INDEX IF NOT EXISTS idx_abandonment_stage ON interview_abandonment(interview_stage);
CREATE INDEX IF NOT EXISTS idx_abandonment_status ON interview_abandonment(completion_status);

-- ============================================
-- 6. Database Health Metrics View
-- ============================================

-- View for database health indicators
CREATE VIEW IF NOT EXISTS database_health_metrics AS
SELECT
    'goal_meta' AS table_name,
    COUNT(*) AS row_count,
    COUNT(CASE WHEN onboarding_complete = 1 THEN 1 END) AS onboarding_complete_count,
    COUNT(CASE WHEN goal_interview_complete = 1 THEN 1 END) AS interview_complete_count,
    0 AS orphan_count
FROM goal_meta

UNION ALL

SELECT
    'topics' AS table_name,
    COUNT(*) AS row_count,
    COUNT(CASE WHEN status = 'mastered' THEN 1 END) AS mastered_count,
    COUNT(CASE WHEN is_hidden = 1 THEN 1 END) AS hidden_count,
    COUNT(CASE WHEN goal_id IS NULL THEN 1 END) AS orphan_count
FROM topics

UNION ALL

SELECT
    'phase_telemetry' AS table_name,
    COUNT(*) AS row_count,
    COUNT(CASE WHEN success = 1 THEN 1 END) AS success_count,
    COUNT(CASE WHEN phase_status = 'running' THEN 1 END) AS running_count,
    0 AS orphan_count
FROM phase_telemetry

UNION ALL

SELECT
    'execution_state' AS table_name,
    COUNT(*) AS row_count,
    COUNT(CASE WHEN phase_complete = 1 THEN 1 END) AS complete_count,
    COUNT(CASE WHEN attempts >= max_attempts THEN 1 END) AS max_attempts_count,
    0 AS orphan_count
FROM execution_state;

-- ============================================
-- 7. Vault Write Failure Tracking Table
-- ============================================

-- Track Obsidian vault write failures
CREATE TABLE IF NOT EXISTS vault_write_failures (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    note_path TEXT NOT NULL,
    operation TEXT NOT NULL CHECK(operation IN ('create', 'update', 'delete')),
    failure_reason TEXT,
    failure_code TEXT,
    attempt_count INTEGER DEFAULT 1,
    first_failure_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_failure_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved INTEGER DEFAULT 0,
    resolved_at TIMESTAMP,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id)
);

CREATE INDEX IF NOT EXISTS idx_vault_failure_goal ON vault_write_failures(goal_id);
CREATE INDEX IF NOT EXISTS idx_vault_failure_path ON vault_write_failures(note_path);
CREATE INDEX IF NOT EXISTS idx_vault_failure_resolved ON vault_write_failures(resolved);

-- ============================================
-- 8. Source Quality Metrics Table
-- ============================================

-- Track quality metrics for research sources
CREATE TABLE IF NOT EXISTS source_quality_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id INTEGER NOT NULL,
    source_url TEXT,
    relevance_score REAL CHECK(relevance_score >= 0.0 AND relevance_score <= 1.0),
    recency_days INTEGER,
    credibility_tier TEXT CHECK(credibility_tier IN ('tier_1', 'tier_2', 'tier_3', 'unverified')),
    citation_count INTEGER DEFAULT 0,
    last_verified_at TIMESTAMP,
    quality_flags TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);

CREATE INDEX IF NOT EXISTS idx_source_quality_topic ON source_quality_metrics(topic_id);
CREATE INDEX IF NOT EXISTS idx_source_quality_url ON source_quality_metrics(source_url);
CREATE INDEX IF NOT EXISTS idx_source_quality_tier ON source_quality_metrics(credibility_tier);

-- ============================================
-- Triggers and Automation
-- ============================================

-- Trigger to calculate wait time when queue item starts processing
CREATE TRIGGER IF NOT EXISTS trg_queue_wait_time
AFTER UPDATE OF started_at ON queue_depth
WHEN NEW.started_at IS NOT NULL AND OLD.started_at IS NULL
BEGIN
    UPDATE queue_depth
    SET wait_time_seconds = (julianday(NEW.started_at) - julianday(OLD.enqueued_at)) * 86400
    WHERE id = NEW.id;
END;

-- Trigger to track vault write failure patterns
CREATE TRIGGER IF NOT EXISTS trg_vault_failure_increment
BEFORE INSERT ON vault_write_failures
WHEN EXISTS (
    SELECT 1 FROM vault_write_failures
    WHERE note_path = NEW.note_path
      AND goal_id = NEW.goal_id
      AND resolved = 0
)
BEGIN
    UPDATE vault_write_failures
    SET attempt_count = attempt_count + 1,
        last_failure_at = CURRENT_TIMESTAMP
    WHERE note_path = NEW.note_path
      AND goal_id = NEW.goal_id
      AND resolved = 0;
    SELECT RAISE(IGNORE);
END;

-- ============================================
-- Utility Views for Monitoring
-- ============================================

-- Current queue status overview
CREATE VIEW IF NOT EXISTS queue_status_overview AS
SELECT
    queue_status,
    COUNT(*) AS item_count,
    AVG(wait_time_seconds) AS avg_wait_seconds,
    MAX(wait_time_seconds) AS max_wait_seconds,
    COUNT(DISTINCT goal_id) AS unique_goals
FROM queue_depth
GROUP BY queue_status;

-- Interview completion funnel
CREATE VIEW IF NOT EXISTS interview_funnel AS
SELECT
    'Stage 1: Onboarding' AS stage,
    COUNT(*) AS started,
    SUM(stage_1_complete) AS completed,
    ROUND(AVG(CASE WHEN stage_1_complete = 1 THEN 1 ELSE 0 END) * 100.0, 2) AS completion_rate
FROM goal_meta

UNION ALL

SELECT
    'Stage 2: Goal Interview' AS stage,
    SUM(stage_1_complete) AS started,
    SUM(stage_2_complete) AS completed,
    ROUND(AVG(CASE WHEN stage_2_complete = 1 THEN 1 ELSE 0 END) * 100.0, 2) AS completion_rate
FROM goal_meta

UNION ALL

SELECT
    'Stage 3: Per-Goal Preferences' AS stage,
    SUM(stage_2_complete) AS started,
    SUM(stage_3_complete) AS completed,
    ROUND(AVG(CASE WHEN stage_3_complete = 1 THEN 1 ELSE 0 END) * 100.0, 2) AS completion_rate
FROM goal_meta

UNION ALL

SELECT
    'Complete: Goal Ready' AS stage,
    SUM(stage_3_complete) AS started,
    SUM(goal_interview_complete) AS completed,
    ROUND(AVG(CASE WHEN goal_interview_complete = 1 THEN 1 ELSE 0 END) * 100.0, 2) AS completion_rate
FROM goal_meta;

-- ============================================
-- Migration Notes
-- ============================================

-- Index Strategy:
-- - All foreign keys indexed for JOIN performance
-- - Status fields indexed for filtering
-- - Timestamp fields indexed for time-based queries
-- - Composite indexes for common query patterns
--
-- Performance Considerations:
-- - Stuck phase detection uses computed column (> 30 min threshold)
-- - Error rate tracking limited to 7-day window
-- - Queue depth tracking enables wait time analytics
-- - Aggregations table supports pre-computed metrics
--
-- Monitoring Integration Points:
-- - stuck_phase_detection: Alert on long-running phases
-- - error_rate_from_telemetry: Track error trends
-- - queue_status_overview: Queue backlog monitoring
-- - interview_funnel: User onboarding drop-off analysis
-- - database_health_metrics: Table row counts and health checks
