-- ============================================
-- Migration 003: JSON Normalization for Interview Data
-- Date: 2026-09-04
-- P1-PF3: Optimize JSON queries with normalized table
-- ============================================

-- Create normalized interview_data table
CREATE TABLE IF NOT EXISTS interview_data (
    goal_id TEXT NOT NULL,
    stage TEXT NOT NULL CHECK(stage IN ('onboarding', 'per_goal', 'per_note')),
    key TEXT NOT NULL,
    value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (goal_id, stage, key),
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id)
);

-- Index for efficient stage+key lookups
CREATE INDEX IF NOT EXISTS idx_interview_stage_key ON interview_data(stage, key);

-- ============================================
-- Migration: Extract existing JSON data
-- ============================================

-- Extract goal_json fields
INSERT OR IGNORE INTO interview_data (goal_id, stage, key, value)
SELECT
    goal_id,
    'per_goal',
    'goal_title',
    JSON_EXTRACT(goal_json, '$.title')
FROM goal_meta
WHERE goal_json IS NOT NULL AND JSON_EXTRACT(goal_json, '$.title') IS NOT NULL;

INSERT OR IGNORE INTO interview_data (goal_id, stage, key, value)
SELECT
    goal_id,
    'per_goal',
    'goal_description',
    JSON_EXTRACT(goal_json, '$.description')
FROM goal_meta
WHERE goal_json IS NOT NULL AND JSON_EXTRACT(goal_json, '$.description') IS NOT NULL;

INSERT OR IGNORE INTO interview_data (goal_id, stage, key, value)
SELECT
    goal_id,
    'per_goal',
    'goal_priority',
    JSON_EXTRACT(goal_json, '$.priority')
FROM goal_meta
WHERE goal_json IS NOT NULL AND JSON_EXTRACT(goal_json, '$.priority') IS NOT NULL;

-- Extract availability_json fields
INSERT OR IGNORE INTO interview_data (goal_id, stage, key, value)
SELECT
    goal_id,
    'onboarding',
    'daily_minutes',
    JSON_EXTRACT(availability_json, '$.dailyMinutes')
FROM goal_meta
WHERE availability_json IS NOT NULL AND JSON_EXTRACT(availability_json, '$.dailyMinutes') IS NOT NULL;

INSERT OR IGNORE INTO interview_data (goal_id, stage, key, value)
SELECT
    goal_id,
    'onboarding',
    'preferred_time',
    JSON_EXTRACT(availability_json, '$.preferredTime')
FROM goal_meta
WHERE availability_json IS NOT NULL AND JSON_EXTRACT(availability_json, '$.preferredTime') IS NOT NULL;

INSERT OR IGNORE INTO interview_data (goal_id, stage, key, value)
SELECT
    goal_id,
    'onboarding',
    'timezone',
    JSON_EXTRACT(availability_json, '$.timezone')
FROM goal_meta
WHERE availability_json IS NOT NULL AND JSON_EXTRACT(availability_json, '$.timezone') IS NOT NULL;

-- Extract learning_style_json fields
INSERT OR IGNORE INTO interview_data (goal_id, stage, key, value)
SELECT
    goal_id,
    'per_goal',
    'learning_style',
    JSON_EXTRACT(learning_style_json, '$.style')
FROM goal_meta
WHERE learning_style_json IS NOT NULL AND JSON_EXTRACT(learning_style_json, '$.style') IS NOT NULL;

INSERT OR IGNORE INTO interview_data (goal_id, stage, key, value)
SELECT
    goal_id,
    'per_goal',
    'pacing_preference',
    JSON_EXTRACT(learning_style_json, '$.pacing')
FROM goal_meta
WHERE learning_style_json IS NOT NULL AND JSON_EXTRACT(learning_style_json, '$.pacing') IS NOT NULL;

-- Extract goal_profile_json fields (stage-specific)
INSERT OR IGNORE INTO interview_data (goal_id, stage, key, value)
SELECT
    goal_id,
    'per_note',
    'depth_level',
    JSON_EXTRACT(goal_profile_json, '$.depth')
FROM goal_meta
WHERE goal_profile_json IS NOT NULL AND JSON_EXTRACT(goal_profile_json, '$.depth') IS NOT NULL;

INSERT OR IGNORE INTO interview_data (goal_id, stage, key, value)
SELECT
    goal_id,
    'per_note',
    'detail_preference',
    JSON_EXTRACT(goal_profile_json, '$.detail')
FROM goal_meta
WHERE goal_profile_json IS NOT NULL AND JSON_EXTRACT(goal_profile_json, '$.detail') IS NOT NULL;

-- ============================================
-- Backward Compatibility View
-- ============================================

-- View to reconstruct JSON from normalized table (for backward compatibility)
CREATE VIEW IF NOT EXISTS interview_data_json AS
SELECT
    goal_id,
    (SELECT JSON_GROUP_OBJECT(key, value)
     FROM interview_data
     WHERE goal_id = id.goal_id AND stage = 'onboarding') AS onboarding_data,
    (SELECT JSON_GROUP_OBJECT(key, value)
     FROM interview_data
     WHERE goal_id = id.goal_id AND stage = 'per_goal') AS per_goal_data,
    (SELECT JSON_GROUP_OBJECT(key, value)
     FROM interview_data
     WHERE goal_id = id.goal_id AND stage = 'per_note') AS per_note_data
FROM (SELECT DISTINCT goal_id FROM interview_data) AS id;

-- ============================================
-- Upsert Helper Function (SQLite trigger-based)
-- ============================================

-- Trigger to auto-update timestamp on UPSERT
CREATE TRIGGER IF NOT EXISTS trg_interview_data_updated
AFTER UPDATE ON interview_data
BEGIN
    UPDATE interview_data
    SET updated_at = CURRENT_TIMESTAMP
    WHERE goal_id = NEW.goal_id
      AND stage = NEW.stage
      AND key = NEW.key;
END;

-- ============================================
-- Migration Notes
-- ============================================

-- Backward Compatibility:
-- - Original JSON columns (goal_json, availability_json, learning_style_json, goal_profile_json)
--   remain in goal_meta table and are NOT dropped
-- - New interview_data table provides normalized access for performance
-- - Use interview_data_json view for JSON reconstruction if needed
-- - Applications can query either normalized table or original JSON
--
-- Performance Benefits:
-- - Eliminates JSON_EXTRACT() calls in hot paths
-- - Enables indexed lookups on specific keys
-- - Reduces query complexity from O(JSON_size) to O(1) indexed lookup
-- - Facilitates partial updates without full JSON rewrite
--
-- Migration Strategy:
-- - Run migration once to populate initial data
-- - Application code updated to write to both locations
-- - Future: deprecate JSON columns after full migration
