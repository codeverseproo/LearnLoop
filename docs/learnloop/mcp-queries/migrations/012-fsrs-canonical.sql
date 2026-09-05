-- ============================================
-- LearnLoop - Canonical FSRS-6 Migration
-- ============================================
-- Replaces custom formulas with canonical FSRS-6
-- Reference: github.com/SqueakyRobot/fsrs/docs/ALGORITHM.md
-- ============================================

BEGIN TRANSACTION;

-- ============================================
-- STEP 1: Create fsrs_parameters table
-- ============================================
-- Stores 17 FSRS-6 weight parameters (w0-w16)
CREATE TABLE IF NOT EXISTS fsrs_parameters (
    id INTEGER PRIMARY KEY CHECK(id = 1),  -- Singleton row
    -- Core weights
    w0  REAL DEFAULT 0.4,    -- Initial stability (Again)
    w1  REAL DEFAULT 0.6,    -- Initial stability (Hard)
    w2  REAL DEFAULT 2.4,    -- Initial stability (Good)
    w3  REAL DEFAULT 10.0,   -- Initial stability (Easy)
    w4  REAL DEFAULT 4.93,   -- Initial difficulty base
    w5  REAL DEFAULT -0.14,  -- Difficulty mean reversion
    w6  REAL DEFAULT 0.8,    -- Difficulty update weight
    w7  REAL DEFAULT -0.1,   -- Difficulty adjustment factor
    w8  REAL DEFAULT 0.05,   -- Stability growth base
    w9  REAL DEFAULT 0.3,    -- Stability decay exponent
    w10 REAL DEFAULT 1.36,   -- Retrievability impact
    w11 REAL DEFAULT 1.75,   -- Lapse stability factor
    w12 REAL DEFAULT 0.03,   -- Lapse difficulty exponent
    w13 REAL DEFAULT 0.15,   -- Lapse stability exponent
    w14 REAL DEFAULT 0.48,   -- Lapse retrievability impact
    w15 REAL DEFAULT 2.61,   -- Hard stability factor
    w16 REAL DEFAULT 0.0,    -- Reserved
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source TEXT DEFAULT 'canonical_v6'  -- 'canonical_v6' | 'optimized'
);

-- Insert default parameter row
INSERT INTO fsrs_parameters (id) VALUES (1);

-- ============================================
-- STEP 2: Add last_rating column to fsrs_state
-- ============================================
-- Rating values: 1=Again, 2=Hard, 3=Good, 4=Easy
-- SQLite ALTER TABLE ADD COLUMN is safe if column exists (3.35+)
ALTER TABLE fsrs_state ADD COLUMN last_rating INTEGER CHECK(last_rating IN (1, 2, 3, 4));

-- ============================================
-- STEP 3: Create index for rating queries
-- ============================================
CREATE INDEX IF NOT EXISTS idx_fsrs_last_rating ON fsrs_state(last_rating);

-- ============================================
-- STEP 4: Add lapses column if not exists
-- ============================================
-- Migration 008 may not have added this column
ALTER TABLE fsrs_state ADD COLUMN lapses INTEGER DEFAULT 0;

-- ============================================
-- STEP 5: Migrate existing performance to rating
-- ============================================
-- Derive rating from most recent session performance
UPDATE fsrs_state
SET last_rating = CASE
    WHEN (SELECT performance FROM sessions WHERE sessions.topic_id = fsrs_state.topic_id ORDER BY started_at DESC LIMIT 1) < 0.3 THEN 1
    WHEN (SELECT performance FROM sessions WHERE sessions.topic_id = fsrs_state.topic_id ORDER BY started_at DESC LIMIT 1) < 0.5 THEN 2
    WHEN (SELECT performance FROM sessions WHERE sessions.topic_id = fsrs_state.topic_id ORDER BY started_at DESC LIMIT 1) < 0.8 THEN 3
    ELSE 4
END
WHERE last_rating IS NULL
  AND EXISTS (SELECT 1 FROM sessions WHERE sessions.topic_id = fsrs_state.topic_id);

COMMIT;

-- ============================================
-- Verification
-- ============================================
SELECT 'Parameters loaded:', COUNT(*) FROM fsrs_parameters;
SELECT 'Rating column added:', COUNT(*) FROM pragma_table_info('fsrs_state') WHERE name = 'last_rating';
