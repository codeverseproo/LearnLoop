-- ============================================
-- MIT Learning Skill - Database Schema
-- ============================================

-- Goal metadata
CREATE TABLE IF NOT EXISTS goal_meta (
    goal_id TEXT PRIMARY KEY,
    goal_type TEXT NOT NULL CHECK(goal_type IN ('exam', 'skill', 'degree', 'topic')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    vault_path TEXT,
    total_topics INTEGER DEFAULT 0,
    mastered_topics INTEGER DEFAULT 0
);

-- Topics with mastery tracking
CREATE TABLE IF NOT EXISTS topics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    mastery REAL DEFAULT 0.0 CHECK(mastery >= 0.0 AND mastery <= 1.0),
    status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'in_progress', 'mastered')),
    next_review DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- FSRS-6 state tracking
CREATE TABLE IF NOT EXISTS fsrs_state (
    topic_id INTEGER PRIMARY KEY,
    stability REAL DEFAULT 2.5 CHECK(stability >= 0.0 AND stability <= 365.0),
    difficulty REAL DEFAULT 5.0 CHECK(difficulty >= 1.0 AND difficulty <= 10.0),
    state INTEGER DEFAULT 0 CHECK(state IN (0, 1, 2, 3)),
    last_review TIMESTAMP,
    next_review TIMESTAMP,
    reviews INTEGER DEFAULT 0,
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);

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

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_topics_status ON topics(status);
CREATE INDEX IF NOT EXISTS idx_topics_next_review ON topics(next_review);
CREATE INDEX IF NOT EXISTS idx_fsrs_next_review ON fsrs_state(next_review);
CREATE INDEX IF NOT EXISTS idx_sessions_topic ON sessions(topic_id);
CREATE INDEX IF NOT EXISTS idx_sessions_started ON sessions(started_at);
