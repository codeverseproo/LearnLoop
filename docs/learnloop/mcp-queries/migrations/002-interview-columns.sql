-- Migration: Add interview data columns
-- Plan: ralplan-note-generation-interview-system

--------------------------------------------------------------------------------
-- JSON Columns for Interview Data Storage
--------------------------------------------------------------------------------

ALTER TABLE goal_meta ADD COLUMN availability_json TEXT DEFAULT '{}';
ALTER TABLE goal_meta ADD COLUMN learning_style_json TEXT DEFAULT '{}';
ALTER TABLE goal_meta ADD COLUMN goal_profile_json TEXT DEFAULT '{}';
ALTER TABLE goal_meta ADD COLUMN note_preferences_json TEXT DEFAULT '{}';
ALTER TABLE goal_meta ADD COLUMN last_note_preferences_json TEXT DEFAULT '{}';

--------------------------------------------------------------------------------
-- Completion Flags
--------------------------------------------------------------------------------

ALTER TABLE goal_meta ADD COLUMN onboarding_complete INTEGER DEFAULT 0;
ALTER TABLE goal_meta ADD COLUMN goal_interview_complete INTEGER DEFAULT 0;

--------------------------------------------------------------------------------
-- Generated Columns for Performance (Virtual)
-- Top 5 queried fields for enforcement checks
--------------------------------------------------------------------------------

ALTER TABLE goal_meta ADD COLUMN exam_date_generated TEXT
  GENERATED ALWAYS AS (json_extract(goal_profile_json, '$.exam_date')) VIRTUAL;

ALTER TABLE goal_meta ADD COLUMN timeline_weeks_generated INTEGER
  GENERATED ALWAYS AS (json_extract(goal_profile_json, '$.timeline_weeks')) VIRTUAL;

ALTER TABLE goal_meta ADD COLUMN hours_per_day_generated INTEGER
  GENERATED ALWAYS AS (json_extract(availability_json, '$.hours_per_day')) VIRTUAL;

ALTER TABLE goal_meta ADD COLUMN intensity_generated TEXT
  GENERATED ALWAYS AS (json_extract(goal_profile_json, '$.intensity')) VIRTUAL;

ALTER TABLE goal_meta ADD COLUMN primary_style_generated TEXT
  GENERATED ALWAYS AS (json_extract(learning_style_json, '$.primary_style')) VIRTUAL;

--------------------------------------------------------------------------------
-- Indexes on Generated Columns (O(log n) queries)
--------------------------------------------------------------------------------

CREATE INDEX idx_exam_date ON goal_meta(exam_date_generated);
CREATE INDEX idx_timeline ON goal_meta(timeline_weeks_generated);
