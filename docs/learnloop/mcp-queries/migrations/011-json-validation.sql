-- ============================================
-- Migration 011: JSON Validation for goal_meta
-- ============================================
-- Adds json_valid() triggers for goal_profile_json, availability_json, goal_json
-- Empty JSON ('{}') allowed for incomplete records
-- ============================================

-- ============================================
-- Validate goal_profile_json on INSERT
-- ============================================
CREATE TRIGGER IF NOT EXISTS trg_validate_goal_profile_json_insert
BEFORE INSERT ON goal_meta
FOR EACH ROW
WHEN NEW.goal_profile_json IS NOT NULL AND NEW.goal_profile_json != '{}' AND json_valid(NEW.goal_profile_json) = 0
BEGIN
    SELECT RAISE(ABORT, 'goal_profile_json must be valid JSON');
END;

-- ============================================
-- Validate goal_profile_json on UPDATE
-- ============================================
CREATE TRIGGER IF NOT EXISTS trg_validate_goal_profile_json_update
BEFORE UPDATE OF goal_profile_json ON goal_meta
FOR EACH ROW
WHEN NEW.goal_profile_json IS NOT NULL AND NEW.goal_profile_json != '{}' AND json_valid(NEW.goal_profile_json) = 0
BEGIN
    SELECT RAISE(ABORT, 'goal_profile_json must be valid JSON');
END;

-- ============================================
-- Validate availability_json on INSERT
-- ============================================
CREATE TRIGGER IF NOT EXISTS trg_validate_availability_json_insert
BEFORE INSERT ON goal_meta
FOR EACH ROW
WHEN NEW.availability_json IS NOT NULL AND NEW.availability_json != '{}' AND json_valid(NEW.availability_json) = 0
BEGIN
    SELECT RAISE(ABORT, 'availability_json must be valid JSON');
END;

-- ============================================
-- Validate availability_json on UPDATE
-- ============================================
CREATE TRIGGER IF NOT EXISTS trg_validate_availability_json_update
BEFORE UPDATE OF availability_json ON goal_meta
FOR EACH ROW
WHEN NEW.availability_json IS NOT NULL AND NEW.availability_json != '{}' AND json_valid(NEW.availability_json) = 0
BEGIN
    SELECT RAISE(ABORT, 'availability_json must be valid JSON');
END;

-- ============================================
-- Validate goal_json on INSERT
-- ============================================
CREATE TRIGGER IF NOT EXISTS trg_validate_goal_json_insert
BEFORE INSERT ON goal_meta
FOR EACH ROW
WHEN NEW.goal_json IS NOT NULL AND NEW.goal_json != '{}' AND json_valid(NEW.goal_json) = 0
BEGIN
    SELECT RAISE(ABORT, 'goal_json must be valid JSON');
END;

-- ============================================
-- Validate goal_json on UPDATE
-- ============================================
CREATE TRIGGER IF NOT EXISTS trg_validate_goal_json_update
BEFORE UPDATE OF goal_json ON goal_meta
FOR EACH ROW
WHEN NEW.goal_json IS NOT NULL AND NEW.goal_json != '{}' AND json_valid(NEW.goal_json) = 0
BEGIN
    SELECT RAISE(ABORT, 'goal_json must be valid JSON');
END;

-- ============================================
-- Migration Notes
-- ============================================
-- Coverage:
-- - goal_profile_json: INSERT/UPDATE triggers
-- - availability_json: INSERT/UPDATE triggers
-- - goal_json: INSERT/UPDATE triggers
--
-- Behavior:
-- - Empty JSON '{}' allowed for incomplete goal profiles
-- - NULL values allowed (for optional fields)
-- - Non-empty strings must be valid JSON
-- - Triggers fire BEFORE write operations
-- - RAISE(ABORT) prevents invalid data insertion
--
-- Integration:
-- - Complements existing CHECK on learning_style_json (schema.sql:40)
-- - SQLite json_valid() returns 1 for valid JSON, 0 for invalid
-- - Application layer should validate before INSERT/UPDATE for better UX
-- ============================================
