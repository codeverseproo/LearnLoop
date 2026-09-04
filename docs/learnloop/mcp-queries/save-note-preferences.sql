-- ============================================
-- LS6: PER-NOTE INTERVIEW PERSISTENCE
-- ============================================
-- Query: Save note-specific interview preferences
-- Parameters: :goal_id, :topic_id, :preferences_json

-- Insert new preferences
INSERT INTO note_preferences (
    goal_id,
    topic_id,
    note_preferences_json,
    created_at,
    updated_at
)
VALUES (
    :goal_id,
    :topic_id,
    :preferences_json,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
)
ON CONFLICT(goal_id, topic_id) DO UPDATE SET
    note_preferences_json = excluded.note_preferences_json,
    last_note_preferences_json = note_preferences_json,
    updated_at = CURRENT_TIMESTAMP;

-- ============================================
-- RETRIEVE CURRENT PREFERENCES
-- ============================================

SELECT
    np.goal_id,
    np.topic_id,
    t.name AS topic_name,
    np.note_preferences_json,
    np.last_note_preferences_json,
    json_extract(np.note_preferences_json, '$.difficulty_level') AS difficulty_level,
    json_extract(np.note_preferences_json, '$.preferred_format') AS preferred_format,
    json_extract(np.note_preferences_json, '$.detail_level') AS detail_level,
    json_extract(np.note_preferences_json, '$.examples_count') AS examples_count,
    json_extract(np.note_preferences_json, '$.include_diagrams') AS include_diagrams,
    json_extract(np.note_preferences_json, '$.code_snippets') AS code_snippets,
    np.created_at,
    np.updated_at,
    CASE
        WHEN np.last_note_preferences_json IS NULL THEN 'Initial preferences'
        WHEN np.note_preferences_json != np.last_note_preferences_json THEN 'Updated since last interview'
        ELSE 'No changes since last interview'
    END AS preference_status
FROM note_preferences np
JOIN topics t ON t.id = np.topic_id
WHERE np.goal_id = :goal_id
  AND np.topic_id = :topic_id;

-- ============================================
-- GET ALL PREFERENCES FOR GOAL
-- ============================================

SELECT
    np.topic_id,
    t.name AS topic_name,
    np.note_preferences_json,
    json_extract(np.note_preferences_json, '$.difficulty_level') AS difficulty_level,
    json_extract(np.note_preferences_json, '$.preferred_format') AS preferred_format,
    np.updated_at
FROM note_preferences np
JOIN topics t ON t.id = np.topic_id
WHERE np.goal_id = :goal_id
ORDER BY t.name ASC;

-- ============================================
-- PREFERENCE CHANGE HISTORY
-- ============================================

SELECT
    np.topic_id,
    t.name AS topic_name,
    np.note_preferences_json AS current_preferences,
    np.last_note_preferences_json AS previous_preferences,
    np.updated_at AS change_date,
    JULIANDAY(np.updated_at) - JULIANDAY(np.created_at) AS days_since_initial
FROM note_preferences np
JOIN topics t ON t.id = np.topic_id
WHERE np.goal_id = :goal_id
  AND np.last_note_preferences_json IS NOT NULL
ORDER BY np.updated_at DESC;

-- Note: Requires note_preferences table (add to schema)
-- CREATE TABLE IF NOT EXISTS note_preferences (
--     goal_id TEXT NOT NULL,
--     topic_id INTEGER NOT NULL,
--     note_preferences_json TEXT NOT NULL,
--     last_note_preferences_json TEXT,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     PRIMARY KEY (goal_id, topic_id),
--     FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id),
--     FOREIGN KEY (topic_id) REFERENCES topics(id)
-- );
