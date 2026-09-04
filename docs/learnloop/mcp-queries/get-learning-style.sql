-- ============================================
-- LS4: LEARNING STYLE EXTRACTION
-- ============================================
-- Query: Extract learning style preferences for prompt customization
-- Parameters: :goal_id

SELECT
    goal_id,
    goal_type,
    learning_style_json,
    json_extract(learning_style_json, '$.visual') AS visual_score,
    json_extract(learning_style_json, '$.auditory') AS auditory_score,
    json_extract(learning_style_json, '$.kinesthetic') AS kinesthetic_score,
    json_extract(learning_style_json, '$.reading_writing') AS reading_writing_score,
    CASE
        WHEN json_extract(learning_style_json, '$.visual') >=
             GREATEST(
                 json_extract(learning_style_json, '$.auditory'),
                 json_extract(learning_style_json, '$.kinesthetic'),
                 json_extract(learning_style_json, '$.reading_writing')
             ) THEN 'visual'
        WHEN json_extract(learning_style_json, '$.auditory') >=
             GREATEST(
                 json_extract(learning_style_json, '$.visual'),
                 json_extract(learning_style_json, '$.kinesthetic'),
                 json_extract(learning_style_json, '$.reading_writing')
             ) THEN 'auditory'
        WHEN json_extract(learning_style_json, '$.kinesthetic') >=
             GREATEST(
                 json_extract(learning_style_json, '$.visual'),
                 json_extract(learning_style_json, '$.auditory'),
                 json_extract(learning_style_json, '$.reading_writing')
             ) THEN 'kinesthetic'
        ELSE 'reading_writing'
    END AS primary_style,
    CASE
        WHEN learning_style_json IS NULL THEN 'No learning style assessed'
        WHEN json_extract(learning_style_json, '$.visual') IS NULL THEN 'Incomplete assessment'
        ELSE 'Assessment complete'
    END AS assessment_status
FROM goal_meta
WHERE goal_id = :goal_id;

-- ============================================
-- STYLE DISTRIBUTION ACROSS GOALS
-- ============================================

SELECT
    goal_type,
    primary_style,
    COUNT(*) AS goal_count,
    AVG(visual_score) AS avg_visual,
    AVG(auditory_score) AS avg_auditory,
    AVG(kinesthetic_score) AS avg_kinesthetic,
    AVG(reading_writing_score) AS avg_reading_writing
FROM (
    SELECT
        goal_type,
        CASE
            WHEN json_extract(learning_style_json, '$.visual') >=
                 GREATEST(
                     json_extract(learning_style_json, '$.auditory'),
                     json_extract(learning_style_json, '$.kinesthetic'),
                     json_extract(learning_style_json, '$.reading_writing')
                 ) THEN 'visual'
            WHEN json_extract(learning_style_json, '$.auditory') >=
                 GREATEST(
                     json_extract(learning_style_json, '$.visual'),
                     json_extract(learning_style_json, '$.kinesthetic'),
                     json_extract(learning_style_json, '$.reading_writing')
                 ) THEN 'auditory'
            WHEN json_extract(learning_style_json, '$.kinesthetic') >=
                 GREATEST(
                     json_extract(learning_style_json, '$.visual'),
                     json_extract(learning_style_json, '$.auditory'),
                     json_extract(learning_style_json, '$.reading_writing')
                 ) THEN 'kinesthetic'
            ELSE 'reading_writing'
        END AS primary_style,
        json_extract(learning_style_json, '$.visual') AS visual_score,
        json_extract(learning_style_json, '$.auditory') AS auditory_score,
        json_extract(learning_style_json, '$.kinesthetic') AS kinesthetic_score,
        json_extract(learning_style_json, '$.reading_writing') AS reading_writing_score
    FROM goal_meta
    WHERE learning_style_json IS NOT NULL
)
GROUP BY goal_type, primary_style
ORDER BY goal_type, goal_count DESC;
