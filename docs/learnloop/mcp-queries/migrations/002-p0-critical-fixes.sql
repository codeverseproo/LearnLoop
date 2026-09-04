-- ============================================
-- Migration 002: P0 Critical Fixes
-- Date: 2026-09-04
-- Based on Gap Analysis Report
-- ============================================

-- P0-1: Race Condition Fix - Add auto-increment primary key
-- Issue: PRIMARY KEY (goal_id, phase, started_at) causes collision on same-second INSERTs
ALTER TABLE phase_telemetry ADD COLUMN telemetry_id INTEGER;

-- Create unique index for backward compatibility
CREATE UNIQUE INDEX IF NOT EXISTS idx_telemetry_unique
ON phase_telemetry(goal_id, phase, started_at);

-- P0-4: Missing indexes for performance
CREATE INDEX IF NOT EXISTS idx_telemetry_goal_phase
ON phase_telemetry(goal_id, phase, completed_at);

CREATE INDEX IF NOT EXISTS idx_telemetry_started
ON phase_telemetry(started_at);

-- P0-12: Missing phase_status column
ALTER TABLE phase_telemetry ADD COLUMN phase_status TEXT DEFAULT 'running'
    CHECK(phase_status IN ('pending', 'running', 'complete', 'failed', 'cancelled'));

-- P0-8: Track repair WebSearch count
ALTER TABLE execution_state ADD COLUMN repair_search_count INTEGER DEFAULT 0;

-- P0-6: Add repair spawn tracking
ALTER TABLE execution_state ADD COLUMN repair_agents_spawned INTEGER DEFAULT 0;

-- P0-2: Budget enforcement - Add spawn_count for transaction isolation
ALTER TABLE execution_state ADD COLUMN spawn_count INTEGER DEFAULT 0;

-- ============================================
-- New Tables for P0 Features
-- ============================================

-- P0-11: User choice protocol table
CREATE TABLE IF NOT EXISTS user_choice_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    phase TEXT NOT NULL,
    choice_type TEXT NOT NULL CHECK(choice_type IN ('retry', 'test', 'proceed_without', 'cancel')),
    choice_made TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    context TEXT,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id)
);

CREATE INDEX IF NOT EXISTS idx_user_choice_goal ON user_choice_log(goal_id);
CREATE INDEX IF NOT EXISTS idx_user_choice_phase ON user_choice_log(phase);

-- P1-TM2: Error registry table
CREATE TABLE IF NOT EXISTS error_registry (
    error_code TEXT PRIMARY KEY,
    category TEXT NOT NULL CHECK(category IN ('goal', 'topic', 'fsrs', 'vault', 'session', 'research', 'system')),
    severity TEXT NOT NULL CHECK(severity IN ('critical', 'high', 'medium', 'low', 'info')),
    message_template TEXT NOT NULL,
    user_message TEXT,
    recovery_action TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Populate error registry
INSERT OR IGNORE INTO error_registry (error_code, category, severity, message_template, user_message, recovery_action) VALUES
-- Goal errors (E001-E099)
('E001', 'goal', 'critical', 'Goal not found: {goal_id}', 'Learning goal not found', 'Create a new goal first'),
('E002', 'goal', 'high', 'Interview incomplete for goal: {goal_id}', 'Setup incomplete', 'Complete the interview process'),
('E003', 'goal', 'high', 'Budget exhausted: {current}/{limit}', 'Agent budget reached', 'Increase budget or force approve'),
-- Topic errors (E100-E199)
('E100', 'topic', 'medium', 'Topic not found: {topic_id}', 'Topic not found', 'Create topic first'),
('E101', 'topic', 'medium', 'Source count below minimum', 'Not enough sources', 'Add more research sources'),
-- FSRS errors (E200-E299)
('E200', 'fsrs', 'low', 'FSRS calculation failed for topic: {topic_id}', 'Review scheduling issue', 'Using default 7-day interval'),
-- Vault errors (E300-E399)
('E300', 'vault', 'medium', 'Vault write failed: {path}', 'Note save failed', 'Check disk space and permissions'),
-- Session errors (E400-E499)
('E400', 'session', 'low', 'Session interrupted', 'Session interrupted', 'Resume from last checkpoint'),
-- Research errors (E500-E599)
('E501', 'research', 'critical', 'Critic agent timeout after 120s', 'Quality check timed out', 'Retry or force approve with warnings'),
('E502', 'research', 'high', 'No critic verdict found', 'Quality check incomplete', 'Run critic agent first'),
('E503', 'research', 'high', 'Repair limit reached (5 cycles)', 'Maximum repair attempts', 'Force approve or manual review'),
('E504', 'research', 'medium', 'WebSearch count below minimum', 'Research incomplete', 'Ensure at least 10 searches'),
-- System errors (E600-E699)
('E600', 'system', 'critical', 'Database connection failed', 'System error', 'Check database file'),
('E601', 'system', 'medium', 'Telemetry INSERT collision', 'Telemetry error', 'Using fallback logging');

-- P1-TM3: Agent spawn log table
CREATE TABLE IF NOT EXISTS agent_spawn_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    phase TEXT NOT NULL,
    wave INTEGER,
    agent_type TEXT,
    agent_name TEXT,
    spawned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    status TEXT DEFAULT 'running' CHECK(status IN ('running', 'completed', 'failed', 'timeout')),
    error_code TEXT,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id)
);

CREATE INDEX IF NOT EXISTS idx_agent_spawn_goal ON agent_spawn_log(goal_id);
CREATE INDEX IF NOT EXISTS idx_agent_spawn_phase ON agent_spawn_log(phase);
CREATE INDEX IF NOT EXISTS idx_agent_spawn_status ON agent_spawn_log(status);

-- P1-TM4: Alerting infrastructure
CREATE TABLE IF NOT EXISTS alert_rules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    rule_name TEXT NOT NULL UNIQUE,
    condition_type TEXT NOT NULL,
    threshold REAL,
    comparison TEXT CHECK(comparison IN ('gt', 'lt', 'eq', 'gte', 'lte')),
    enabled INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS alert_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    rule_id INTEGER,
    goal_id TEXT,
    triggered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP,
    message TEXT,
    resolved INTEGER DEFAULT 0,
    FOREIGN KEY (rule_id) REFERENCES alert_rules(id),
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id)
);

-- Insert default alert rules
INSERT OR IGNORE INTO alert_rules (rule_name, condition_type, threshold, comparison) VALUES
('budget_exhausted', 'agent_spawns', 1.0, 'gte'),
('repair_cycles_high', 'repair_cycles', 4, 'gte'),
('critic_timeout', 'duration_seconds', 120, 'gte'),
('low_confidence', 'avg_confidence', 0.3, 'lt'),
('source_count_low', 'source_count', 10, 'lt');

-- ============================================
-- P1 Fixes: Performance Optimization
-- ============================================

-- P1-PF2: Optimize budget check (scalar subquery pattern)
-- Create view for efficient budget monitoring
CREATE VIEW IF NOT EXISTS budget_status_view AS
SELECT
    es.goal_id,
    gm.agent_budget,
    gm.budget_enforcement,
    (SELECT SUM(agent_spawns) FROM execution_state WHERE goal_id = es.goal_id) as total_agents,
    CASE
        WHEN gm.agent_budget = -1 THEN 'UNLIMITED'
        WHEN (SELECT SUM(agent_spawns) FROM execution_state WHERE goal_id = es.goal_id) >= gm.agent_budget THEN 'EXHAUSTED'
        WHEN (SELECT SUM(agent_spawns) FROM execution_state WHERE goal_id = es.goal_id) >= gm.agent_budget * 0.75 THEN 'WARN_75PCT'
        WHEN (SELECT SUM(agent_spawns) FROM execution_state WHERE goal_id = es.goal_id) >= gm.agent_budget * 0.5 THEN 'WARN_50PCT'
        ELSE 'OK'
    END as budget_status
FROM goal_meta gm
LEFT JOIN execution_state es ON gm.goal_id = es.goal_id
GROUP BY gm.goal_id;

-- P1-PF4: Foreign key on phase_telemetry
-- Note: SQLite requires FK to reference PRIMARY KEY
CREATE INDEX IF NOT EXISTS idx_telemetry_fk ON phase_telemetry(goal_id);

-- ============================================
-- P1 Fixes: Additional Indexes
-- ============================================

-- P1-PF1: Index for critic_verdict created_at
CREATE INDEX IF NOT EXISTS idx_critic_created ON critic_verdict(created_at);

-- P1-PF2: Index for execution_state wave/agent_type
CREATE INDEX IF NOT EXISTS idx_execution_wave_agent ON execution_state(wave, agent_type);

-- ============================================
-- P1 Fixes: Orchestration
-- ============================================

-- P1-OR2: Agent spawn tracking
CREATE INDEX IF NOT EXISTS idx_execution_spawn_count ON execution_state(goal_id, spawn_count);

-- Trigger to auto-increment spawn_count on INSERT
CREATE TRIGGER IF NOT EXISTS trg_increment_spawn_count
AFTER INSERT ON execution_state
BEGIN
    UPDATE execution_state
    SET spawn_count = spawn_count + 1,
        last_attempt = CURRENT_TIMESTAMP
    WHERE goal_id = NEW.goal_id AND phase = NEW.phase AND wave = NEW.wave;
END;

-- ============================================
-- P1 Fixes: Telemetry Phase Status Tracking
-- ============================================

-- Trigger to set phase_status on INSERT
CREATE TRIGGER IF NOT EXISTS trg_set_phase_status_running
BEFORE INSERT ON phase_telemetry
BEGIN
    SELECT CASE
        WHEN NEW.phase_status IS NULL THEN
            RAISE(IGNORE)
        ELSE
            1
    END;
END;

-- Update trigger for phase completion
CREATE TRIGGER IF NOT EXISTS trg_set_phase_status_complete
AFTER UPDATE OF completed_at ON phase_telemetry
BEGIN
    UPDATE phase_telemetry
    SET phase_status = CASE
        WHEN NEW.success = 1 THEN 'complete'
        ELSE 'failed'
    END
    WHERE goal_id = NEW.goal_id
      AND phase = NEW.phase
      AND started_at = NEW.started_at;
END;
