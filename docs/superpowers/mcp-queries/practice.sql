-- ============================================
-- PRACTICE SESSION QUERIES
-- ============================================

-- Start practice session
-- Parameters: :topic_id

INSERT INTO sessions (session_type, topic_id, started_at)
VALUES ('practice', :topic_id, CURRENT_TIMESTAMP);

-- End practice session with performance
-- Parameters: :session_id, :performance, :notes

UPDATE sessions
SET
    ended_at = CURRENT_TIMESTAMP,
    performance = :performance,
    duration_seconds = CAST((julianday(CURRENT_TIMESTAMP) - julianday(started_at)) * 86400 AS INTEGER),
    notes = :notes
WHERE id = :session_id;

-- Get interleaved practice topics
-- Select topics from different areas for interleaved practice
-- Parameters: :goal_id, :limit

SELECT t.id, t.topic_id, t.name, t.mastery
FROM topics t
WHERE t.status = 'in_progress'
ORDER BY RANDOM()
LIMIT :limit;

-- Get practice history for topic
-- Parameters: :topic_id

SELECT
    s.id,
    s.started_at,
    s.performance,
    s.duration_seconds
FROM sessions s
WHERE s.topic_id = :topic_id
AND s.session_type = 'practice'
ORDER BY s.started_at DESC
LIMIT 20;

-- ============================================
-- GET WEAK TOPICS FOR PRACTICE
-- ============================================

SELECT t.id, t.topic_id, t.name, t.mastery
FROM topics t
WHERE t.mastery < 0.5
AND t.status = 'in_progress'
ORDER BY t.mastery ASC
LIMIT 10;
