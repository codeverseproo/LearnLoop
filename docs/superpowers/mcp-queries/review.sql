-- ============================================
-- REVIEW SESSION QUERIES
-- ============================================

-- Get review queue (due topics)
-- Parameters: :goal_id

SELECT
    t.id,
    t.topic_id,
    t.name,
    f.stability,
    f.difficulty,
    f.state,
    f.last_review,
    POWER(1 + (julianday('now') - julianday(f.last_review)) / (9.0 * f.stability), -1.0) AS retrievability
FROM topics t
JOIN fsrs_state f ON t.id = f.topic_id
WHERE t.next_review <= date('now')
ORDER BY retrievability ASC
LIMIT 20;

-- Start review session
-- Parameters: :topic_id

INSERT INTO sessions (session_type, topic_id, started_at)
VALUES ('review', :topic_id, CURRENT_TIMESTAMP);

-- End review session with performance
-- Parameters: :session_id, :performance

UPDATE sessions
SET
    ended_at = CURRENT_TIMESTAMP,
    performance = :performance,
    duration_seconds = CAST((julianday(CURRENT_TIMESTAMP) - julianday(started_at)) * 86400 AS INTEGER)
WHERE id = :session_id;

-- Update topic review status after review
-- Parameters: :topic_id, :next_review

UPDATE topics
SET
    next_review = :next_review,
    updated_at = CURRENT_TIMESTAMP
WHERE id = :topic_id;

-- ============================================
-- GET REVIEW HISTORY
-- ============================================

SELECT
    s.id,
    s.started_at,
    s.performance,
    s.duration_seconds,
    t.name AS topic_name
FROM sessions s
JOIN topics t ON s.topic_id = t.id
WHERE s.session_type = 'review'
ORDER BY s.started_at DESC
LIMIT 50;
