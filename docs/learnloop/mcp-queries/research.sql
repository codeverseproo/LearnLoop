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

-- ============================================
-- SATISFACTION CRITERIA VERIFICATION
-- ============================================

-- Criterion 1: Minimum sources (≥3 per core topic)
-- Returns topics failing criterion
SELECT t.topic_id, t.name, COUNT(ts.id) AS source_count
FROM topics t
LEFT JOIN topic_sources ts ON t.id = ts.topic_id
WHERE t.is_hidden = 0
GROUP BY t.id
HAVING source_count < 3;

-- Criterion 2: Hidden topic detection (all 3 methods ran)
-- Returns count per method
SELECT detection_method, COUNT(*) AS count
FROM topics
WHERE is_hidden = 1
GROUP BY detection_method;

-- Returns 1 if all 3 methods have entries
SELECT CASE
    WHEN COUNT(DISTINCT detection_method) = 3 THEN 1
    ELSE 0
END AS all_methods_ran
FROM topics
WHERE is_hidden = 1 AND detection_method IS NOT NULL;

-- Criterion 3: Prerequisites coverage
-- Returns topics without prerequisite entry
SELECT t.topic_id, t.name
FROM topics t
LEFT JOIN prerequisites p ON t.id = p.topic_id
WHERE p.id IS NULL AND t.is_hidden = 0;

-- Criterion 5: Cross-validation (≥50% topic overlap)
-- Returns overlap ratio
WITH agent_topics AS (
    SELECT DISTINCT topic_id
    FROM topic_sources
)
SELECT
    COUNT(DISTINCT ts1.topic_id) AS topics_with_multiple_sources,
    (SELECT COUNT(*) FROM topics WHERE is_hidden = 0) AS total_core_topics,
    CAST(COUNT(DISTINCT ts1.topic_id) AS REAL) /
    (SELECT COUNT(*) FROM topics WHERE is_hidden = 0) AS overlap_ratio
FROM topic_sources ts1
WHERE EXISTS (
    SELECT 1 FROM topic_sources ts2
    WHERE ts2.topic_id = ts1.topic_id
    AND ts2.source_type != ts1.source_type
);

-- Criterion 6: Recency (sources ≤2 years old)
-- Returns old sources
SELECT t.topic_id, t.name, ts.source_title, ts.source_date
FROM topics t
JOIN topic_sources ts ON t.id = ts.topic_id
WHERE ts.source_date < DATE('now', '-2 years');

-- Returns avg age in months
SELECT AVG((julianday('now') - julianday(source_date)) / 30) AS avg_age_months
FROM topic_sources
WHERE source_date IS NOT NULL;

-- Criterion 7: Goal type fit
-- Returns topic count vs expected range
SELECT
    gm.goal_type,
    COUNT(t.id) AS topic_count,
    CASE gm.goal_type
        WHEN 'exam' THEN CASE
            WHEN COUNT(t.id) BETWEEN 30 AND 60 THEN 'PASS'
            ELSE 'FAIL'
        END
        WHEN 'skill' THEN CASE
            WHEN COUNT(t.id) BETWEEN 20 AND 40 THEN 'PASS'
            ELSE 'FAIL'
        END
        WHEN 'degree' THEN CASE
            WHEN COUNT(t.id) BETWEEN 80 AND 150 THEN 'PASS'
            ELSE 'FAIL'
        END
        WHEN 'topic' THEN CASE
            WHEN COUNT(t.id) BETWEEN 15 AND 30 THEN 'PASS'
            ELSE 'FAIL'
        END
    END AS fit_status
FROM topics t
JOIN goal_meta gm ON 1=1
WHERE t.is_hidden = 0;
