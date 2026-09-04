-- ============================================
-- Migration 004: P1 Tables and JSON Fixes
-- Date: 2026-09-04
-- ============================================

-- ============================================
-- LS5: Diagnostic Results Table
-- ============================================
-- Stores placement test results for topic-level assessment
CREATE TABLE IF NOT EXISTS diagnostic_results (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    topic_id TEXT NOT NULL,
    question_id TEXT NOT NULL,
    user_answer TEXT,
    correct_answer TEXT,
    is_correct INTEGER CHECK(is_correct IN (0, 1)),
    confidence_level REAL CHECK(confidence_level >= 0.0 AND confidence_level <= 1.0),
    answered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id),
    FOREIGN KEY (topic_id) REFERENCES topics(topic_id)
);

CREATE INDEX IF NOT EXISTS idx_diagnostic_goal ON diagnostic_results(goal_id);
CREATE INDEX IF NOT EXISTS idx_diagnostic_topic ON diagnostic_results(topic_id);
CREATE INDEX IF NOT EXISTS idx_diagnostic_question ON diagnostic_results(question_id);

-- ============================================
-- LS6: Note Preferences Table
-- ============================================
-- Stores per-note interview preferences
CREATE TABLE IF NOT EXISTS note_preferences (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    note_path TEXT NOT NULL,
    preference_type TEXT NOT NULL CHECK(preference_type IN ('detail_level', 'format', 'examples', 'pace')),
    preference_value TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id),
    UNIQUE(goal_id, note_path, preference_type)
);

CREATE INDEX IF NOT EXISTS idx_note_prefs_goal ON note_preferences(goal_id);
CREATE INDEX IF NOT EXISTS idx_note_prefs_note ON note_preferences(note_path);

-- ============================================
-- JSON Validation Fix (SC3)
-- ============================================
-- SQLite doesn't support ALTER TABLE ADD CONSTRAINT for CHECK
-- Application layer MUST use validate-json.sql before INSERT
-- This view enforces JSON validity at read time

CREATE VIEW IF NOT EXISTS valid_learning_styles AS
SELECT
    goal_id,
    goal_type,
    learning_style_json,
    CASE
        WHEN learning_style_json IS NULL THEN 'not_assessed'
        WHEN json_valid(learning_style_json) = 0 THEN 'invalid_json'
        WHEN json_extract(learning_style_json, '$.primary') IS NOT NULL THEN 'valid_v1'
        WHEN json_extract(learning_style_json, '$.visual') IS NOT NULL THEN 'valid_v2'
        ELSE 'missing_keys'
    END AS validation_status
FROM goal_meta
WHERE learning_style_json IS NOT NULL;

-- ============================================
-- Learning Style JSON Schema Documentation
-- ============================================
-- Expected format (V2 - multi-dimensional):
-- {
--   "visual": 0.8,           -- 0.0 to 1.0
--   "auditory": 0.5,         -- 0.0 to 1.0
--   "kinesthetic": 0.6,      -- 0.0 to 1.0
--   "reading_writing": 0.7,  -- 0.0 to 1.0
--   "primary": "visual"      -- derived from max score
-- }
--
-- Legacy format (V1 - single primary key):
-- {"primary": "visual"}
--
-- Application must handle both formats for backward compatibility.
