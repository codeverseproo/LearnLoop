-- ============================================
-- BACKUP OPERATIONS
-- ============================================

-- Get full database export
-- Run via: sqlite3 database.db ".dump"

-- Get topics backup
SELECT
    t.id,
    t.topic_id,
    t.name,
    t.mastery,
    t.status,
    t.next_review,
    t.created_at,
    t.updated_at
FROM topics t
ORDER BY t.id;

-- Get FSRS state backup
SELECT
    f.topic_id,
    f.stability,
    f.difficulty,
    f.state,
    f.last_review,
    f.next_review,
    f.reviews
FROM fsrs_state f
ORDER BY f.topic_id;

-- Get sessions backup (last 90 days)
SELECT
    s.id,
    s.session_type,
    s.topic_id,
    s.started_at,
    s.ended_at,
    s.performance,
    s.duration_seconds,
    s.notes
FROM sessions s
WHERE s.started_at >= date('now', '-90 days')
ORDER BY s.started_at;

-- Get achievements backup
SELECT
    a.goal_id,
    a.achievement_id,
    a.unlocked_at
FROM achievements a
ORDER BY a.goal_id, a.unlocked_at;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Verify schema integrity
PRAGMA integrity_check;

-- Verify foreign keys
PRAGMA foreign_key_check;

-- Count records
SELECT 'topics' AS table_name, COUNT(*) AS count FROM topics
UNION ALL
SELECT 'fsrs_state', COUNT(*) FROM fsrs_state
UNION ALL
SELECT 'sessions', COUNT(*) FROM sessions
UNION ALL
SELECT 'achievements', COUNT(*) FROM achievements;

-- ============================================
-- RESTORE OPERATIONS
-- ============================================

-- Disable foreign keys for restore
PRAGMA foreign_keys = OFF;

-- Re-enable after restore
PRAGMA foreign_keys = ON;

-- Verify after restore
SELECT
    (SELECT COUNT(*) FROM topics) AS topics,
    (SELECT COUNT(*) FROM fsrs_state) AS fsrs,
    (SELECT COUNT(*) FROM sessions) AS sessions;
