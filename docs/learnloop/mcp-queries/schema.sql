-- ============================================
-- LearnLoop - Database Schema
-- ============================================
--
-- SECURITY: All queries use parameterized syntax (:param_name).
-- SQLite MCP handles escaping. Never concatenate user input into queries.
-- ============================================

-- P0-1: Enable foreign key enforcement (MUST run on every connection)
-- Note: PRAGMA does not persist; application must execute this after connect
-- PRAGMA foreign_keys = ON;

-- Goal metadata
CREATE TABLE IF NOT EXISTS goal_meta (
    goal_id TEXT PRIMARY KEY,
    goal_type TEXT NOT NULL CHECK(goal_type IN ('exam', 'skill', 'degree', 'topic')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    vault_path TEXT,
    total_topics INTEGER DEFAULT 0,
    mastered_topics INTEGER DEFAULT 0,
    baseline TEXT,
    timeline TEXT,
    daily_availability TEXT,
    interview_complete INTEGER DEFAULT 0,
    -- Interview stage tracking
    stage_1_complete INTEGER DEFAULT 0,
    stage_2_complete INTEGER DEFAULT 0,
    stage_3_complete INTEGER DEFAULT 0,
    goal_interview_complete INTEGER DEFAULT 0,
    -- Budget configuration from interview
    agent_budget INTEGER DEFAULT -1,
    budget_enforcement TEXT DEFAULT 'warning' CHECK(budget_enforcement IN ('warning', 'hard_limit')),
    goal_json TEXT,
    availability_json TEXT,
    learning_style_json TEXT,
    goal_profile_json TEXT,
    onboarding_complete INTEGER DEFAULT 0,
    -- Budget explanation for user-facing display
    budget_explanation TEXT,
    -- JSON validation: Ensure learning_style_json contains valid keys
    CHECK(learning_style_json IS NULL OR learning_style_json LIKE '%"primary"%')
);

-- Topics with mastery tracking
-- UPSERT pattern: ON CONFLICT(topic_name) DO UPDATE ensures idempotent inserts.
-- Collisions resolve to UPDATE, preventing duplicates.
CREATE TABLE IF NOT EXISTS topics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    mastery REAL DEFAULT 0.0 CHECK(mastery >= 0.0 AND mastery <= 1.0),
    status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'in_progress', 'mastered')),
    next_review DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    confidence REAL DEFAULT 1.0,
    source_count INTEGER DEFAULT 0,
    is_hidden INTEGER DEFAULT 0,
    detection_method TEXT CHECK(detection_method IN ('complexity_analysis', 'error_pattern', 'expert_practice'))
);

-- FSRS-6 parameters (canonical weights)
CREATE TABLE IF NOT EXISTS fsrs_parameters (
    id INTEGER PRIMARY KEY CHECK(id = 1),
    w0  REAL DEFAULT 0.4,
    w1  REAL DEFAULT 0.6,
    w2  REAL DEFAULT 2.4,
    w3  REAL DEFAULT 10.0,
    w4  REAL DEFAULT 4.93,
    w5  REAL DEFAULT -0.14,
    w6  REAL DEFAULT 0.8,
    w7  REAL DEFAULT -0.1,
    w8  REAL DEFAULT 0.05,
    w9  REAL DEFAULT 0.3,
    w10 REAL DEFAULT 1.36,
    w11 REAL DEFAULT 1.75,
    w12 REAL DEFAULT 0.03,
    w13 REAL DEFAULT 0.15,
    w14 REAL DEFAULT 0.48,
    w15 REAL DEFAULT 2.61,
    w16 REAL DEFAULT 0.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source TEXT DEFAULT 'canonical_v6'
);

-- FSRS-6 state tracking
CREATE TABLE IF NOT EXISTS fsrs_state (
    topic_id INTEGER PRIMARY KEY,
    stability REAL DEFAULT 2.5 CHECK(stability >= 1.0 AND stability <= 365.0),
    difficulty REAL DEFAULT 5.0 CHECK(difficulty >= 1.0 AND difficulty <= 10.0),
    state INTEGER DEFAULT 0 CHECK(state IN (0, 1, 2, 3)),
    last_review TIMESTAMP,
    next_review TIMESTAMP,
    reviews INTEGER DEFAULT 0,
    lapses INTEGER DEFAULT 0,
    last_rating INTEGER CHECK(last_rating IN (1, 2, 3, 4)),
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);
-- P1-1 Fix: Stability lower bound raised from 0.0 to 1.0 (see migration 009-fsrs-hardening.sql)

-- Insert default FSRS parameters if not exists
INSERT OR IGNORE INTO fsrs_parameters (id) VALUES (1);

-- Session history
CREATE TABLE IF NOT EXISTS sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_type TEXT NOT NULL CHECK(session_type IN ('review', 'practice', 'assessment', 'learning')),
    topic_id INTEGER,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP,
    performance REAL CHECK(performance >= 0.0 AND performance <= 1.0),
    duration_seconds INTEGER,
    notes TEXT,
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);

-- Prerequisites graph
CREATE TABLE IF NOT EXISTS prerequisites (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id INTEGER NOT NULL,
    prerequisite_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (topic_id) REFERENCES topics(id),
    FOREIGN KEY (prerequisite_id) REFERENCES topics(id),
    UNIQUE(topic_id, prerequisite_id)
);

-- Note registry (Obsidian vault links)
CREATE TABLE IF NOT EXISTS note_registry (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id INTEGER NOT NULL,
    note_path TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);

-- Streak tracking
CREATE TABLE IF NOT EXISTS streak_state (
    goal_id TEXT PRIMARY KEY,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_activity_date DATE,
    streak_freeze_available INTEGER DEFAULT 1,
    streak_freeze_used_date DATE,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id)
);

-- Achievements
CREATE TABLE IF NOT EXISTS achievements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    achievement_id TEXT NOT NULL,
    unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id),
    UNIQUE(goal_id, achievement_id)
);

-- Topic links (non-prerequisite relationships)
CREATE TABLE IF NOT EXISTS topic_links (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_topic INTEGER NOT NULL,
    to_topic INTEGER NOT NULL,
    link_type TEXT NOT NULL CHECK(link_type IN ('enabled_by', 'related_to', 'cross_domain')),
    confidence REAL DEFAULT 1.0 CHECK(confidence >= 0.0 AND confidence <= 1.0),
    source TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_topic) REFERENCES topics(id),
    FOREIGN KEY (to_topic) REFERENCES topics(id),
    UNIQUE(from_topic, to_topic, link_type)
);

-- Topic sources (source citations)
CREATE TABLE IF NOT EXISTS topic_sources (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id INTEGER NOT NULL,
    source_type TEXT NOT NULL CHECK(source_type IN ('official', 'academic', 'practical', 'expert')),
    source_title TEXT NOT NULL,
    source_url TEXT,
    source_date DATE,
    cited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_topics_status ON topics(status);
CREATE INDEX IF NOT EXISTS idx_topics_next_review ON topics(next_review);
CREATE INDEX IF NOT EXISTS idx_fsrs_next_review ON fsrs_state(next_review);
CREATE INDEX IF NOT EXISTS idx_fsrs_last_rating ON fsrs_state(last_rating);
CREATE INDEX IF NOT EXISTS idx_sessions_topic ON sessions(topic_id);
CREATE INDEX IF NOT EXISTS idx_sessions_started ON sessions(started_at);
CREATE INDEX IF NOT EXISTS idx_topic_links_from ON topic_links(from_topic);
CREATE INDEX IF NOT EXISTS idx_topic_links_to ON topic_links(to_topic);
CREATE INDEX IF NOT EXISTS idx_topic_links_type ON topic_links(link_type);
CREATE INDEX IF NOT EXISTS idx_topic_sources_topic ON topic_sources(topic_id);
CREATE INDEX IF NOT EXISTS idx_topic_sources_type ON topic_sources(source_type);
CREATE INDEX IF NOT EXISTS idx_topics_hidden ON topics(is_hidden);
CREATE INDEX IF NOT EXISTS idx_topics_detection ON topics(detection_method);

-- Research execution metadata
CREATE TABLE IF NOT EXISTS research_metadata (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    agent_type TEXT NOT NULL CHECK(agent_type IN ('official', 'academic', 'practical', 'expert')),
    search_iterations INTEGER DEFAULT 0,
    research_dir TEXT,
    artifacts_saved INTEGER DEFAULT 0,
    researched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id),
    UNIQUE(goal_id, agent_type)
);

-- Indexes for research_metadata
CREATE INDEX IF NOT EXISTS idx_research_goal ON research_metadata(goal_id);
CREATE INDEX IF NOT EXISTS idx_research_agent ON research_metadata(agent_type);

-- ============================================
-- EXECUTION STATE TRACKING (Two-Tier Agent)
-- ============================================

-- Execution state for agent spawns and phase tracking
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
    repair_cycles INTEGER DEFAULT 0,
    user_budget INTEGER DEFAULT -1,
    budget_enforcement TEXT DEFAULT 'warning',
    error_code TEXT,
    PRIMARY KEY (goal_id, phase, wave),
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id)
);

-- Phase telemetry for observability
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
    error_code TEXT,
    gate_result TEXT CHECK(gate_result IN ('PASS', 'FAIL', 'SKIP')),
    PRIMARY KEY (goal_id, phase, started_at)
);

-- Critic verdict storage
CREATE TABLE IF NOT EXISTS critic_verdict (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    verdict TEXT NOT NULL CHECK(verdict IN ('APPROVED', 'APPROVED_WITH_WARNINGS', 'REJECT')),
    confidence REAL CHECK(confidence >= 0.0 AND confidence <= 1.0),
    warnings_count INTEGER DEFAULT 0,
    challenges TEXT,
    repair_cycle INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id)
);

CREATE INDEX IF NOT EXISTS idx_critic_goal ON critic_verdict(goal_id);
CREATE INDEX IF NOT EXISTS idx_critic_verdict ON critic_verdict(verdict);

-- Indexes for execution tracking
CREATE INDEX IF NOT EXISTS idx_execution_goal ON execution_state(goal_id);
CREATE INDEX IF NOT EXISTS idx_execution_phase ON execution_state(phase);
CREATE INDEX IF NOT EXISTS idx_telemetry_goal ON phase_telemetry(goal_id);
