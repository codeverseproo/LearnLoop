-- ============================================
-- LearnLoop - FSRS-6 Algorithm Hardening (P1)
-- ============================================
-- Addresses audit findings for FSRS-6 implementation:
-- P1-1: Missing stability constraint (should be >= 1.0)
-- P1-2: Mean reversion too slow (15% -> 25%, app-layer change)
-- P1-3: Performance factor unclamped (should max at 1.8)
-- ============================================

-- ============================================
-- P1-1: Stability Lower Bound Constraint
-- ============================================
-- Issue: Original constraint allowed stability >= 0.0
-- Fix: Add CHECK constraint ensuring stability >= 1.0
-- Rationale: FSRS-6 minimum stability is 1 day (meaningful retention)
-- Impact: Prevents invalid states where review intervals become fractions of days

-- SQLite does not support ALTER TABLE ADD CONSTRAINT
-- Must recreate table with new constraint
BEGIN TRANSACTION;

-- Create temporary table with correct constraint
CREATE TABLE fsrs_state_new (
    topic_id INTEGER PRIMARY KEY,
    stability REAL DEFAULT 2.5 CHECK(stability >= 1.0 AND stability <= 365.0),
    difficulty REAL DEFAULT 5.0 CHECK(difficulty >= 1.0 AND difficulty <= 10.0),
    state INTEGER DEFAULT 0 CHECK(state IN (0, 1, 2, 3)),
    last_review TIMESTAMP,
    next_review TIMESTAMP,
    reviews INTEGER DEFAULT 0,
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);

-- Copy existing data (enforcing constraint)
-- Set any invalid stability values to minimum of 1.0
INSERT INTO fsrs_state_new
SELECT
    topic_id,
    MAX(1.0, stability) AS stability,
    difficulty,
    state,
    last_review,
    next_review,
    reviews
FROM fsrs_state;

-- Drop old table
DROP TABLE fsrs_state;

-- Rename new table
ALTER TABLE fsrs_state_new RENAME TO fsrs_state;

COMMIT;

-- ============================================
-- P1-2: Mean Reversion Rate (App-Layer Change)
-- ============================================
-- Issue: Difficulty reverts 15% toward 5.5, should be 25%
-- Fix: Update FSRS scheduler in application code
-- Location: SKILL.md §5 (difficulty update formula)
-- Old formula: D' = D + (5.5 - D) * 0.15 + (1 - performance) * 0.3
-- New formula: D' = D + (5.5 - D) * 0.25 + (1 - performance) * 0.3
-- Rationale: Faster mean reversion prevents difficulty drift
-- Implementation: Requires updating fsrs_scheduler.py or prompts
-- Note: Migration documents the change; actual code update separate

-- ============================================
-- P1-3: Performance Factor Clamp (App-Layer Change)
-- ============================================
-- Issue: Performance factor unbounded in stability update
-- Fix: Clamp performance_factor to max 1.8
-- Location: SKILL.md §5 (stability update on success)
-- Old formula: p_factor = 1 + (performance - 0.6) * 2
-- New formula: p_factor = MIN(1.8, 1 + (performance - 0.6) * 2)
-- Rationale: Prevents excessive stability growth on perfect scores
-- Example: performance=1.0 -> p_factor=1.8 (capped from 2.2)
-- Implementation: Requires updating fsrs_scheduler.py or prompts
-- Note: Migration documents the change; actual code update separate

-- ============================================
-- Verification Query
-- ============================================
-- Query to verify constraint after migration
-- Expected: No rows returned (all stability values >= 1.0)
-- ============================================
-- SELECT COUNT(*) AS violations FROM fsrs_state WHERE stability < 1.0;

-- ============================================
-- Migration Metadata
-- ============================================
-- Version: 009
-- Date: 2026-09-05
-- Author: FSRS Hardening Audit
-- Priority: P1 (High - Algorithm Correctness)
-- Breaking: No (backward compatible, only tightens constraints)
-- Rollback: Revert to previous constraint (stability >= 0.0) if needed
-- ============================================
