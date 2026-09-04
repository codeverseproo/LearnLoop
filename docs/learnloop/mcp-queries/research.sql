-- ============================================
-- RESEARCH WORKFLOW QUERIES
-- ============================================

-- Register research note
-- Parameters: :topic_id, :note_path

INSERT INTO note_registry (topic_id, note_path, created_at)
VALUES (:topic_id, :note_path, CURRENT_TIMESTAMP);

-- Get research notes for topic
-- Parameters: :topic_id

SELECT id, note_path, created_at, updated_at
FROM note_registry
WHERE topic_id = :topic_id
ORDER BY created_at DESC;

-- Update research note
-- Parameters: :note_id, :note_path

UPDATE note_registry
SET
    note_path = :note_path,
    updated_at = CURRENT_TIMESTAMP
WHERE id = :note_id;

-- ============================================
-- CLAIM TRIANGULATION
-- ============================================

-- Store claim with source
-- This would be used in Obsidian notes primarily
-- but we track the metadata here

-- Get all sources for a topic
SELECT n.note_path, n.created_at
FROM note_registry n
WHERE n.topic_id = :topic_id
ORDER BY n.created_at DESC;

-- ============================================
-- CURRENT AFFAIRS DIGEST
-- ============================================

-- Get recent research activity
SELECT
    t.topic_id,
    t.name,
    COUNT(n.id) AS note_count,
    MAX(n.created_at) AS last_note
FROM topics t
LEFT JOIN note_registry n ON t.id = n.topic_id
GROUP BY t.id
ORDER BY last_note DESC
LIMIT 10;
