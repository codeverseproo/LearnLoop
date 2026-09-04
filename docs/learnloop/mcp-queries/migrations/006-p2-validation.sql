-- ============================================
-- Migration 006: P2 Validation Constraints
-- Date: 2026-09-04
-- Depends on: 002-p0-critical-fixes.sql (error_registry, agent_spawn_log)
-- ============================================

-- Dependency verification: Migration 002 must have run (error_registry, agent_spawn_log)
-- These tables are required for validation triggers and constraints

-- ============================================
-- P2-1: Error Code Format Validation
-- ============================================
-- Constraint: error_code must match pattern E\d{3}
-- SQLite CHECK uses REGEXP extension or LIKE pattern

-- Add CHECK constraint for error_code format
-- Note: SQLite doesn't support ALTER TABLE ADD CONSTRAINT after creation
-- Application layer MUST validate format before INSERT
-- This trigger enforces format at INSERT/UPDATE time

CREATE TRIGGER IF NOT EXISTS trg_validate_error_code_format
BEFORE INSERT ON error_registry
FOR EACH ROW
BEGIN
    SELECT CASE
        WHEN NEW.error_code NOT LIKE 'E___' THEN
            RAISE(ABORT, 'Invalid error_code format: must be E followed by 3 digits')
        WHEN NEW.error_code NOT GLOB 'E[0-9][0-9][0-9]' THEN
            RAISE(ABORT, 'Invalid error_code format: must be E followed by 3 digits')
        ELSE
            1
    END;
END;

CREATE TRIGGER IF NOT EXISTS trg_validate_error_code_update
BEFORE UPDATE OF error_code ON error_registry
FOR EACH ROW
BEGIN
    SELECT CASE
        WHEN NEW.error_code NOT LIKE 'E___' THEN
            RAISE(ABORT, 'Invalid error_code format: must be E followed by 3 digits')
        WHEN NEW.error_code NOT GLOB 'E[0-9][0-9][0-9]' THEN
            RAISE(ABORT, 'Invalid error_code format: must be E followed by 3 digits')
        ELSE
            1
    END;
END;

-- ============================================
-- P2-2: Empty Challenges Validation
-- ============================================
-- Constraint: challenges JSON array must have length > 0 when verdict = 'REJECT'

CREATE TRIGGER IF NOT EXISTS trg_validate_challenges_not_empty
BEFORE INSERT ON critic_verdict
FOR EACH ROW
WHEN NEW.verdict = 'REJECT'
BEGIN
    SELECT CASE
        WHEN NEW.challenges IS NULL THEN
            RAISE(ABORT, 'challenges field required when verdict is REJECT')
        WHEN json_valid(NEW.challenges) = 0 THEN
            RAISE(ABORT, 'challenges must be valid JSON array')
        WHEN json_array_length(NEW.challenges) = 0 THEN
            RAISE(ABORT, 'challenges array cannot be empty for REJECT verdict')
        ELSE
            1
    END;
END;

CREATE TRIGGER IF NOT EXISTS trg_validate_challenges_update
BEFORE UPDATE OF verdict, challenges ON critic_verdict
FOR EACH ROW
WHEN NEW.verdict = 'REJECT'
BEGIN
    SELECT CASE
        WHEN NEW.challenges IS NULL THEN
            RAISE(ABORT, 'challenges field required when verdict is REJECT')
        WHEN json_valid(NEW.challenges) = 0 THEN
            RAISE(ABORT, 'challenges must be valid JSON array')
        WHEN json_array_length(NEW.challenges) = 0 THEN
            RAISE(ABORT, 'challenges array cannot be empty for REJECT verdict')
        ELSE
            1
    END;
END;

-- ============================================
-- P2-3: Topic Complexity Normalization
-- ============================================
-- Normalize complexity scores to 0.0-1.0 scale
-- Add complexity column if not exists (compatibility with migration 002)

-- Add complexity columns to topics table
ALTER TABLE topics ADD COLUMN complexity REAL DEFAULT 0.5 CHECK(complexity >= 0.0 AND complexity <= 1.0);
ALTER TABLE topics ADD COLUMN complexity_category TEXT CHECK(complexity_category IN ('beginner', 'intermediate', 'advanced'));

-- Trigger to auto-populate complexity_category
CREATE TRIGGER IF NOT EXISTS trg_set_complexity_category
AFTER INSERT ON topics
FOR EACH ROW
WHEN NEW.complexity_category IS NULL
BEGIN
    UPDATE topics
    SET complexity_category = CASE
        WHEN NEW.complexity < 0.33 THEN 'beginner'
        WHEN NEW.complexity < 0.67 THEN 'intermediate'
        ELSE 'advanced'
    END
    WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS trg_update_complexity_category
AFTER UPDATE OF complexity ON topics
FOR EACH ROW
BEGIN
    UPDATE topics
    SET complexity_category = CASE
        WHEN NEW.complexity < 0.33 THEN 'beginner'
        WHEN NEW.complexity < 0.67 THEN 'intermediate'
        ELSE 'advanced'
    END
    WHERE id = NEW.id;
END;

-- Index on complexity for filtering
CREATE INDEX IF NOT EXISTS idx_topics_complexity ON topics(complexity);
CREATE INDEX IF NOT EXISTS idx_topics_complexity_cat ON topics(complexity_category);

-- ============================================
-- P2-4: Guard Retry Limit Consistency
-- ============================================
-- Ensure max_retries = 2 in all execution_state records

-- Update existing records to enforce max_retries = 2
UPDATE execution_state
SET max_attempts = 2
WHERE max_attempts != 2;

-- Add CHECK constraint enforcement via trigger
CREATE TRIGGER IF NOT EXISTS trg_enforce_max_retries
BEFORE INSERT ON execution_state
FOR EACH ROW
BEGIN
    SELECT CASE
        WHEN NEW.max_attempts != 2 THEN
            RAISE(ABORT, 'max_attempts must be 2 for retry consistency')
        ELSE
            1
    END;
END;

CREATE TRIGGER IF NOT EXISTS trg_enforce_max_retries_update
BEFORE UPDATE OF max_attempts ON execution_state
FOR EACH ROW
BEGIN
    SELECT CASE
        WHEN NEW.max_attempts != 2 THEN
            RAISE(ABORT, 'max_attempts must be 2 for retry consistency')
        ELSE
            1
    END;
END;

-- ============================================
-- P2-5: Source Recency in Average Calculation
-- ============================================
-- Track source creation dates for recency-weighted averages
-- Exclude NULL created_at from calculations

-- Create view for source-weighted topic quality (excludes NULL dates)
CREATE VIEW IF NOT EXISTS topic_quality_metrics AS
SELECT
    t.id,
    t.topic_id,
    t.name,
    t.mastery,
    t.confidence,
    t.source_count,
    -- Average confidence from non-NULL sources
    (SELECT AVG(ts.confidence)
     FROM topic_sources ts
     WHERE ts.topic_id = t.id
       AND ts.cited_at IS NOT NULL) AS avg_source_confidence,
    -- Days since most recent source
    (SELECT julianday('now') - julianday(MAX(ts.cited_at))
     FROM topic_sources ts
     WHERE ts.topic_id = t.id
       AND ts.cited_at IS NOT NULL) AS days_since_last_source,
    -- Source quality score (recency-weighted)
    CASE
        WHEN t.source_count = 0 THEN 0.0
        ELSE
            t.confidence *
            (1.0 - LEAST((
                SELECT julianday('now') - julianday(MAX(ts.cited_at))
                FROM topic_sources ts
                WHERE ts.topic_id = t.id
                  AND ts.cited_at IS NOT NULL
            ) / 365.0, 0.5))
    END AS quality_score
FROM topics t
WHERE t.is_hidden = 0;

CREATE INDEX IF NOT EXISTS idx_topic_sources_cited ON topic_sources(topic_id, cited_at);

-- ============================================
-- P2-6: Interview Session Save/Resume Support
-- ============================================
-- Track interview sessions for resumability

CREATE TABLE IF NOT EXISTS interview_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    session_stage TEXT NOT NULL CHECK(session_stage IN ('stage_1', 'stage_2', 'stage_3', 'complete')),
    session_data TEXT, -- JSON blob of partial responses
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    resume_token TEXT UNIQUE, -- UUID for resuming
    expires_at TIMESTAMP, -- Token expiration (7 days default)
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id)
);

CREATE INDEX IF NOT EXISTS idx_interview_sessions_goal ON interview_sessions(goal_id);
CREATE INDEX IF NOT EXISTS idx_interview_sessions_token ON interview_sessions(resume_token);
CREATE INDEX IF NOT EXISTS idx_interview_sessions_expires ON interview_sessions(expires_at);

-- Trigger to auto-generate resume token
CREATE TRIGGER IF NOT EXISTS trg_generate_resume_token
AFTER INSERT ON interview_sessions
FOR EACH ROW
WHEN NEW.resume_token IS NULL
BEGIN
    UPDATE interview_sessions
    SET resume_token = lower(hex(randomblob(16))),
        expires_at = datetime('now', '+7 days')
    WHERE id = NEW.id;
END;

-- Trigger to update last_updated timestamp
CREATE TRIGGER IF NOT EXISTS trg_update_interview_session
AFTER UPDATE ON interview_sessions
FOR EACH ROW
BEGIN
    UPDATE interview_sessions
    SET last_updated = CURRENT_TIMESTAMP
    WHERE id = NEW.id;
END;

-- ============================================
-- P2-7: Domain-Specific Mastery Thresholds
-- ============================================
-- Store mastery thresholds per domain/goal type

CREATE TABLE IF NOT EXISTS mastery_thresholds (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    domain_type TEXT NOT NULL CHECK(domain_type IN ('exam', 'skill', 'degree', 'topic')),
    domain_name TEXT NOT NULL, -- e.g., 'programming', 'mathematics', 'literature'
    mastery_threshold REAL NOT NULL CHECK(mastery_threshold >= 0.0 AND mastery_threshold <= 1.0),
    passing_threshold REAL NOT NULL CHECK(passing_threshold >= 0.0 AND passing_threshold <= 1.0),
    confidence_threshold REAL DEFAULT 0.7 CHECK(confidence_threshold >= 0.0 AND confidence_threshold <= 1.0),
    source_count_minimum INTEGER DEFAULT 3,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(domain_type, domain_name)
);

-- Insert default thresholds
INSERT OR IGNORE INTO mastery_thresholds (domain_type, domain_name, mastery_threshold, passing_threshold) VALUES
('exam', 'default', 0.85, 0.70),
('skill', 'default', 0.80, 0.65),
('degree', 'default', 0.75, 0.60),
('topic', 'default', 0.70, 0.55),
-- Domain-specific examples
('exam', 'programming', 0.90, 0.75),
('skill', 'programming', 0.85, 0.70),
('topic', 'mathematics', 0.80, 0.65);

CREATE INDEX IF NOT EXISTS idx_mastery_thresholds_domain ON mastery_thresholds(domain_type, domain_name);

-- Trigger to update timestamp
CREATE TRIGGER IF NOT EXISTS trg_update_mastery_thresholds
AFTER UPDATE ON mastery_thresholds
FOR EACH ROW
BEGIN
    UPDATE mastery_thresholds
    SET updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.id;
END;

-- ============================================
-- P2 Validation Views
-- ============================================

-- View: Topics requiring sources
CREATE VIEW IF NOT EXISTS topics_needing_sources AS
SELECT
    t.id,
    t.topic_id,
    t.name,
    t.mastery,
    t.confidence,
    t.source_count,
    mt.source_count_minimum,
    t.source_count - mt.source_count_minimum AS source_gap
FROM topics t
CROSS JOIN mastery_thresholds mt
WHERE mt.domain_type = 'topic'
  AND mt.domain_name = 'default'
  AND t.source_count < mt.source_count_minimum;

-- View: Quality metrics summary
CREATE VIEW IF NOT EXISTS quality_metrics_summary AS
SELECT
    COUNT(*) as total_topics,
    AVG(mastery) as avg_mastery,
    AVG(confidence) as avg_confidence,
    SUM(CASE WHEN source_count >= 3 THEN 1 ELSE 0 END) as topics_with_sources,
    SUM(CASE WHEN complexity >= 0.67 THEN 1 ELSE 0 END) as advanced_topics
FROM topics
WHERE is_hidden = 0;

-- ============================================
-- Migration Complete
-- ============================================
