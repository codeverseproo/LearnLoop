-- ============================================
-- Migration 008: P0 Audit Fixes - Schema Level
-- ============================================
-- Fixes P0-1 and P0-2 from audit gap analysis
-- Reference: docs/learnloop/mcp-queries/schema.sql
-- ============================================

-- P0-1: Enable foreign key enforcement
-- CRITICAL: Must be at start of every session
PRAGMA foreign_keys = ON;

-- P0-2: Add ON DELETE CASCADE to existing FK constraints
-- SQLite requires table recreation for FK constraint changes
-- Pattern: CREATE TABLE new → INSERT from old → DROP old → RENAME

-- 1. fsrs_state (line 67): topic_id -> topics.id
ALTER TABLE fsrs_state RENAME TO fsrs_state_old;
CREATE TABLE fsrs_state (
    topic_id INTEGER PRIMARY KEY,
    stability REAL DEFAULT 2.5 CHECK(stability >= 0.0 AND stability <= 365.0),
    difficulty REAL DEFAULT 5.0 CHECK(difficulty >= 1.0 AND difficulty <= 10.0),
    state INTEGER DEFAULT 0 CHECK(state IN (0, 1, 2, 3)),
    last_review TIMESTAMP,
    next_review TIMESTAMP,
    reviews INTEGER DEFAULT 0,
    FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
);
INSERT INTO fsrs_state SELECT * FROM fsrs_state_old;
DROP TABLE fsrs_state_old;

-- 2. sessions (line 80): topic_id -> topics.id
ALTER TABLE sessions RENAME TO sessions_old;
CREATE TABLE sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_type TEXT NOT NULL CHECK(session_type IN ('review', 'practice', 'assessment', 'learning')),
    topic_id INTEGER,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP,
    performance REAL CHECK(performance >= 0.0 AND performance <= 1.0),
    duration_seconds INTEGER,
    notes TEXT,
    FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
);
INSERT INTO sessions SELECT * FROM sessions_old;
DROP TABLE sessions_old;

-- 3. prerequisites (line 89): topic_id -> topics.id
-- 4. prerequisites (line 90): prerequisite_id -> topics.id
ALTER TABLE prerequisites RENAME TO prerequisites_old;
CREATE TABLE prerequisites (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id INTEGER NOT NULL,
    prerequisite_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE,
    FOREIGN KEY (prerequisite_id) REFERENCES topics(id) ON DELETE CASCADE,
    UNIQUE(topic_id, prerequisite_id)
);
INSERT INTO prerequisites SELECT * FROM prerequisites_old;
DROP TABLE prerequisites_old;

-- 5. note_registry (line 101): topic_id -> topics.id
ALTER TABLE note_registry RENAME TO note_registry_old;
CREATE TABLE note_registry (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id INTEGER NOT NULL,
    note_path TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
);
INSERT INTO note_registry SELECT * FROM note_registry_old;
DROP TABLE note_registry_old;

-- 6. streak_state (line 112): goal_id -> goal_meta.goal_id
ALTER TABLE streak_state RENAME TO streak_state_old;
CREATE TABLE streak_state (
    goal_id TEXT PRIMARY KEY,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_activity_date DATE,
    streak_freeze_available INTEGER DEFAULT 1,
    streak_freeze_used_date DATE,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id) ON DELETE CASCADE
);
INSERT INTO streak_state SELECT * FROM streak_state_old;
DROP TABLE streak_state_old;

-- 7. achievements (line 121): goal_id -> goal_meta.goal_id
ALTER TABLE achievements RENAME TO achievements_old;
CREATE TABLE achievements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    achievement_id TEXT NOT NULL,
    unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id) ON DELETE CASCADE,
    UNIQUE(goal_id, achievement_id)
);
INSERT INTO achievements SELECT * FROM achievements_old;
DROP TABLE achievements_old;

-- 8. topic_links (line 134): from_topic -> topics.id
-- 9. topic_links (line 135): to_topic -> topics.id
ALTER TABLE topic_links RENAME TO topic_links_old;
CREATE TABLE topic_links (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_topic INTEGER NOT NULL,
    to_topic INTEGER NOT NULL,
    link_type TEXT NOT NULL CHECK(link_type IN ('enabled_by', 'related_to', 'cross_domain')),
    confidence REAL DEFAULT 1.0 CHECK(confidence >= 0.0 AND confidence <= 1.0),
    source TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_topic) REFERENCES topics(id) ON DELETE CASCADE,
    FOREIGN KEY (to_topic) REFERENCES topics(id) ON DELETE CASCADE,
    UNIQUE(from_topic, to_topic, link_type)
);
INSERT INTO topic_links SELECT * FROM topic_links_old;
DROP TABLE topic_links_old;

-- 10. topic_sources (line 148): topic_id -> topics.id
ALTER TABLE topic_sources RENAME TO topic_sources_old;
CREATE TABLE topic_sources (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id INTEGER NOT NULL,
    source_type TEXT NOT NULL CHECK(source_type IN ('official', 'academic', 'practical', 'expert')),
    source_title TEXT NOT NULL,
    source_url TEXT,
    source_date DATE,
    cited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
);
INSERT INTO topic_sources SELECT * FROM topic_sources_old;
DROP TABLE topic_sources_old;

-- 11. research_metadata (line 174): goal_id -> goal_meta.goal_id
ALTER TABLE research_metadata RENAME TO research_metadata_old;
CREATE TABLE research_metadata (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    agent_type TEXT NOT NULL CHECK(agent_type IN ('official', 'academic', 'practical', 'expert')),
    search_iterations INTEGER DEFAULT 0,
    research_dir TEXT,
    artifacts_saved INTEGER DEFAULT 0,
    researched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id) ON DELETE CASCADE,
    UNIQUE(goal_id, agent_type)
);
INSERT INTO research_metadata SELECT * FROM research_metadata_old;
DROP TABLE research_metadata_old;

-- 12. execution_state (line 203): goal_id -> goal_meta.goal_id
-- Note: Migration 002 added repair_search_count, repair_agents_spawned, spawn_count
ALTER TABLE execution_state RENAME TO execution_state_old;
CREATE TABLE execution_state (
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
    repair_cycles INTEGER DEFAULT 0,
    user_budget INTEGER DEFAULT -1,
    budget_enforcement TEXT DEFAULT 'warning',
    error_code TEXT,
    repair_search_count INTEGER DEFAULT 0,
    repair_agents_spawned INTEGER DEFAULT 0,
    spawn_count INTEGER DEFAULT 0,
    PRIMARY KEY (goal_id, phase, wave),
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id) ON DELETE CASCADE
);
INSERT INTO execution_state SELECT * FROM execution_state_old;
DROP TABLE execution_state_old;

-- 13. critic_verdict (line 232): goal_id -> goal_meta.goal_id
ALTER TABLE critic_verdict RENAME TO critic_verdict_old;
CREATE TABLE critic_verdict (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    verdict TEXT NOT NULL CHECK(verdict IN ('APPROVED', 'APPROVED_WITH_WARNINGS', 'REJECT')),
    confidence REAL CHECK(confidence >= 0.0 AND confidence <= 1.0),
    warnings_count INTEGER DEFAULT 0,
    challenges TEXT,
    repair_cycle INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id) ON DELETE CASCADE
);
INSERT INTO critic_verdict SELECT * FROM critic_verdict_old;
DROP TABLE critic_verdict_old;

-- Recreate indexes after table recreation
CREATE INDEX IF NOT EXISTS idx_fsrs_next_review ON fsrs_state(next_review);
CREATE INDEX IF NOT EXISTS idx_sessions_topic ON sessions(topic_id);
CREATE INDEX IF NOT EXISTS idx_sessions_started ON sessions(started_at);
CREATE INDEX IF NOT EXISTS idx_topic_links_from ON topic_links(from_topic);
CREATE INDEX IF NOT EXISTS idx_topic_links_to ON topic_links(to_topic);
CREATE INDEX IF NOT EXISTS idx_topic_links_type ON topic_links(link_type);
CREATE INDEX IF NOT EXISTS idx_topic_sources_topic ON topic_sources(topic_id);
CREATE INDEX IF NOT EXISTS idx_topic_sources_type ON topic_sources(source_type);
CREATE INDEX IF NOT EXISTS idx_research_goal ON research_metadata(goal_id);
CREATE INDEX IF NOT EXISTS idx_research_agent ON research_metadata(agent_type);
CREATE INDEX IF NOT EXISTS idx_execution_goal ON execution_state(goal_id);
CREATE INDEX IF NOT EXISTS idx_execution_phase ON execution_state(phase);
CREATE INDEX IF NOT EXISTS idx_critic_goal ON critic_verdict(goal_id);
CREATE INDEX IF NOT EXISTS idx_critic_verdict ON critic_verdict(verdict);

-- ============================================
-- P0-4: Add Missing Error Codes (Part 3)
-- ============================================
-- These codes are referenced in codebase but missing from error_registry

INSERT OR IGNORE INTO error_registry (error_code, category, severity, message_template, user_message, recovery_action) VALUES
-- Topic errors (E100-E199)
('E102', 'topic', 'medium', 'Prerequisite not satisfied for topic: {topic_id}', 'Prerequisites incomplete', 'Complete prerequisite topics first'),

-- Research errors (E500-E599)
('E505', 'research', 'medium', 'Repair agent spawn limit reached', 'Repair limit reached', 'Approve with warnings or force repair'),
('E510', 'research', 'high', 'Research quality below threshold: {confidence}', 'Research quality insufficient', 'Run additional research agents'),
('E511', 'research', 'medium', 'Source diversity below minimum: {source_types}', 'Need diverse sources', 'Add sources from different tiers');

-- ============================================
-- P0-5: WAVE4_REPAIR Execution State Template (Part 3)
-- ============================================
-- Template row for WAVE4_REPAIR phase initialization
-- Orchestrator should UPSERT this row when entering repair phase

-- Pattern: INSERT with ON CONFLICT DO UPDATE (UPSERT)
-- SQLite >= 3.24.0 syntax. execution_state PK is (goal_id, phase, wave)
-- Note: Use :goal_id parameter substitution at runtime
-- INSERT INTO execution_state (
--     goal_id, phase, wave, agent_spawns, agent_type, attempts, max_attempts,
--     last_attempt, last_failure_reason, phase_complete, repair_cycles,
--     user_budget, budget_enforcement, error_code, repair_agents_spawned,
--     repair_search_count, spawn_count
-- ) VALUES (
--     :goal_id, 'WAVE4_REPAIR', 4, 0, 'repair', 0, 5,
--     CURRENT_TIMESTAMP, NULL, 0, 0,
--     -1, 'warning', NULL, 0,
--     0, 0
-- ) ON CONFLICT(goal_id, phase, wave) DO UPDATE SET
--     last_attempt = CURRENT_TIMESTAMP,
--     repair_agents_spawned = MAX(repair_agents_spawned, 0),
--     repair_search_count = MAX(repair_search_count, 0);

-- ============================================
-- P0-7: Strengthen Resume Token Generation
-- ============================================
-- Problem: randomblob(16) generates 128-bit tokens using SQLite's PRNG
-- which may not be cryptographically secure on all platforms.
--
-- Solution: Replace trigger with application-layer token generation.
-- Remove auto-generation trigger, require token to be provided.

DROP TRIGGER IF EXISTS trg_generate_resume_token;

-- Create new trigger that validates token presence
CREATE TRIGGER IF NOT EXISTS trg_validate_resume_token
BEFORE INSERT ON interview_sessions
FOR EACH ROW
WHEN NEW.resume_token IS NULL
BEGIN
    SELECT RAISE(ABORT, 'resume_token required: application must generate using secrets.token_urlsafe(32)');
END;

-- ============================================
-- Migration Notes (Part 3)
-- ============================================
--
-- Error Codes Added (P0-4):
-- - E102: Prerequisite validation (topic category)
-- - E505: Repair spawn limit (research category)
-- - E510: Research quality threshold (research category)
-- - E511: Source diversity minimum (research category)
-- Note: E200 (FSRS calculation failed) already exists in migration 002
--
-- WAVE4_REPAIR Template (P0-5):
-- - wave: 4 (matches phase numbering)
-- - agent_type: 'repair'
-- - max_attempts: 5 (repair cycle cap)
-- - repair_agents_spawned: tracked column (added in migration 002)
-- - repair_search_count: tracked column (added in migration 002)
-- - spawn_count: transaction-safe counter (added in migration 002)
--
-- Usage:
-- - Error codes: SELECT FROM error_registry WHERE error_code = 'E102'
-- - Execution state: Query execution_state WHERE phase = 'WAVE4_REPAIR'
-- - UPSERT pattern ensures idempotent initialization

-- ============================================
-- P0-3: Fix phase_telemetry race condition
-- ============================================
-- Problem: Composite PRIMARY KEY (goal_id, phase, started_at) causes
-- "UNIQUE constraint failed" when concurrent inserts happen within same
-- timestamp granularity (SQLite timestamps have ~1ms resolution).
--
-- Solution: Replace with INTEGER PRIMARY KEY AUTOINCREMENT + unique constraint
-- on (goal_id, phase, started_at). AUTOINCREMENT guarantees uniqueness even
-- under concurrent inserts.

-- Create new table with AUTOINCREMENT PK
CREATE TABLE IF NOT EXISTS phase_telemetry_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    phase TEXT NOT NULL,
    wave INTEGER,
    agent_type TEXT,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    duration_seconds INTEGER,
    success INTEGER DEFAULT 1,
    error_message TEXT,
    error_code TEXT,
    gate_result TEXT CHECK(gate_result IN ('PASS', 'FAIL', 'SKIP')),
    UNIQUE(goal_id, phase, started_at),
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id) ON DELETE CASCADE
);

-- Copy data from old table
INSERT INTO phase_telemetry_new (
    goal_id, phase, wave, agent_type, started_at, completed_at,
    duration_seconds, success, error_message, error_code, gate_result
)
SELECT
    goal_id, phase, wave, agent_type, started_at, completed_at,
    duration_seconds, success, error_message, error_code, gate_result
FROM phase_telemetry;

-- Drop old table
DROP TABLE phase_telemetry;

-- Rename new table
ALTER TABLE phase_telemetry_new RENAME TO phase_telemetry;

-- Recreate indexes
CREATE INDEX IF NOT EXISTS idx_telemetry_goal ON phase_telemetry(goal_id);
CREATE INDEX IF NOT EXISTS idx_telemetry_phase ON phase_telemetry(phase);
CREATE INDEX IF NOT EXISTS idx_telemetry_started ON phase_telemetry(started_at);
