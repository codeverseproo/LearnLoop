-- ============================================
-- LEARNING SESSION QUERIES
-- ============================================

-- Get or create topic
-- Parameters: :topic_name, :goal_id

INSERT INTO topics (topic_id, name, status, created_at)
VALUES (
    'T' || strftime('%Y%m%d%H%M%S', 'now') || '-' || LOWER(REPLACE(:topic_name, ' ', '-')),
    :topic_name,
    'in_progress',
    CURRENT_TIMESTAMP
)
ON CONFLICT(topic_id) DO UPDATE SET updated_at = CURRENT_TIMESTAMP;

-- Initialize FSRS state for new topic
-- Parameters: :topic_id (internal id)

INSERT INTO fsrs_state (topic_id, stability, difficulty, state, last_review)
VALUES (:topic_id, 2.5, 5.0, 0, CURRENT_TIMESTAMP)
ON CONFLICT(topic_id) DO NOTHING;

-- Start learning session
-- Parameters: :topic_id

INSERT INTO sessions (session_type, topic_id, started_at)
VALUES ('learning', :topic_id, CURRENT_TIMESTAMP);

-- End learning session with performance
-- Parameters: :session_id, :performance, :notes

UPDATE sessions
SET
    ended_at = CURRENT_TIMESTAMP,
    performance = :performance,
    duration_seconds = CAST((julianday(CURRENT_TIMESTAMP) - julianday(started_at)) * 86400 AS INTEGER),
    notes = :notes
WHERE id = :session_id;

-- Get related topics (prerequisites)
-- Parameters: :topic_id

SELECT t.topic_id, t.name, t.mastery
FROM topics t
JOIN prerequisites p ON t.id = p.prerequisite_id
WHERE p.topic_id = :topic_id
ORDER BY t.mastery ASC;

-- ============================================
-- GET TOPIC BY ID
-- ============================================

SELECT t.id, t.topic_id, t.name, t.mastery, t.status, f.stability, f.difficulty, f.state
FROM topics t
LEFT JOIN fsrs_state f ON t.id = f.topic_id
WHERE t.topic_id = :topic_id;

-- ============================================
-- GET ALL TOPICS FOR GOAL
-- ============================================

SELECT id, topic_id, name, mastery, status, next_review
FROM topics
WHERE topic_id LIKE :goal_id || '%'
ORDER BY mastery DESC;
