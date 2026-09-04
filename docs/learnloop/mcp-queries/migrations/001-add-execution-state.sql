-- Migration: Add execution state tracking
-- Date: 2026-09-04

-- 1. Add execution_state table for agent tracking
CREATE TABLE IF NOT EXISTS execution_state (
    goal_id TEXT NOT NULL,
    phase TEXT NOT NULL,
    wave INTEGER DEFAULT 0,
    agent_spawns INTEGER DEFAULT 0,
    agent_type TEXT,
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    last_attempt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_failure_reason TEXT,
    phase_complete INTEGER DEFAULT 0,
    PRIMARY KEY (goal_id, phase, wave),
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id)
);

-- 2. Add phase_telemetry for observability
CREATE TABLE IF NOT EXISTS phase_telemetry (
    goal_id TEXT NOT NULL,
    phase TEXT NOT NULL,
    wave INTEGER,
    agent_type TEXT,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    duration_seconds INTEGER,
    success INTEGER DEFAULT 1,
    error_message TEXT,
    PRIMARY KEY (goal_id, phase, started_at)
);

-- 3. Add research_metadata table (if not exists)
CREATE TABLE IF NOT EXISTS research_metadata (
    goal_id TEXT NOT NULL,
    agent_type TEXT NOT NULL,
    search_iterations INTEGER DEFAULT 0,
    artifacts_saved INTEGER DEFAULT 0,
    research_dir TEXT,
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (goal_id, agent_type)
);

-- 4. Add interview fields to goal_meta
ALTER TABLE goal_meta ADD COLUMN baseline TEXT;
ALTER TABLE goal_meta ADD COLUMN timeline TEXT;
ALTER TABLE goal_meta ADD COLUMN daily_availability TEXT;
ALTER TABLE goal_meta ADD COLUMN interview_complete INTEGER DEFAULT 0;

-- 5. Add indexes
CREATE INDEX IF NOT EXISTS idx_execution_goal ON execution_state(goal_id);
CREATE INDEX IF NOT EXISTS idx_execution_phase ON execution_state(phase);
CREATE INDEX IF NOT EXISTS idx_telemetry_goal ON phase_telemetry(goal_id);
CREATE INDEX IF NOT EXISTS idx_research_goal ON research_metadata(goal_id);
