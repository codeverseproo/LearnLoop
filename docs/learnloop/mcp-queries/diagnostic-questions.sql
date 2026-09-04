-- ============================================
-- LS5: DIAGNOSTIC PLACEMENT TEST DESIGN
-- ============================================
-- Query: Generate diagnostic questions covering goal prerequisites
-- Parameters: :goal_id, :question_limit (default 10)

WITH goal_prerequisites AS (
    -- Get all prerequisites for topics in this goal
    SELECT DISTINCT
        p.prerequisite_id,
        t.name AS prerequisite_name,
        t.mastery,
        t.status,
        COUNT(*) AS dependency_count
    FROM topics t
    JOIN prerequisites p ON p.topic_id = t.id
    WHERE t.id IN (
        SELECT id FROM topics WHERE topic_id LIKE '%' || :goal_id || '%'
    )
    GROUP BY p.prerequisite_id
    ORDER BY dependency_count DESC, t.mastery ASC
    LIMIT :question_limit
),
difficulty_tiers AS (
    -- Assign difficulty tiers based on mastery and dependency count
    SELECT
        gp.*,
        CASE
            WHEN gp.mastery < 0.3 THEN 'foundational'
            WHEN gp.mastery < 0.6 THEN 'intermediate'
            ELSE 'advanced'
        END AS difficulty_tier
    FROM goal_prerequisites gp
)
SELECT
    dt.prerequisite_id,
    dt.prerequisite_name,
    dt.difficulty_tier,
    dt.dependency_count,
    dt.mastery,
    CASE dt.difficulty_tier
        WHEN 'foundational' THEN 'Basic recall and recognition'
        WHEN 'intermediate' THEN 'Application and analysis'
        WHEN 'advanced' THEN 'Synthesis and evaluation'
    END AS question_type,
    CASE dt.difficulty_tier
        WHEN 'foundational' THEN 3
        WHEN 'intermediate' THEN 5
        WHEN 'advanced' THEN 7
    END AS estimated_difficulty,
    'Diagnostic question for ' || dt.prerequisite_name || ' (' || dt.difficulty_tier || ' level)' AS question_placeholder
FROM difficulty_tiers dt
ORDER BY dt.dependency_count DESC, dt.mastery ASC;

-- ============================================
-- DIAGNOSTIC RESULTS STORAGE
-- ============================================
-- Run this after diagnostic test completion

INSERT INTO diagnostic_results (
    goal_id,
    topic_id,
    question_tier,
    performance,
    completed_at
)
SELECT
    :goal_id,
    dt.prerequisite_id,
    dt.difficulty_tier,
    :performance,
    CURRENT_TIMESTAMP
FROM difficulty_tiers dt;

-- ============================================
-- DIAGNOSTIC RESULT SUMMARY
-- ============================================

SELECT
    goal_id,
    question_tier,
    COUNT(*) AS questions_attempted,
    AVG(performance) AS avg_performance,
    SUM(CASE WHEN performance >= 0.7 THEN 1 ELSE 0 END) AS passed_count,
    SUM(CASE WHEN performance < 0.5 THEN 1 ELSE 0 END) AS failed_count
FROM diagnostic_results
WHERE goal_id = :goal_id
GROUP BY goal_id, question_tier
ORDER BY
    CASE question_tier
        WHEN 'foundational' THEN 1
        WHEN 'intermediate' THEN 2
        WHEN 'advanced' THEN 3
    END;

-- ============================================
-- PLACEMENT RECOMMENDATION
-- ============================================

SELECT
    :goal_id AS goal_id,
    CASE
        WHEN AVG(CASE WHEN question_tier = 'foundational' THEN performance END) < 0.5 THEN 'remedial'
        WHEN AVG(CASE WHEN question_tier = 'intermediate' THEN performance END) < 0.6 THEN 'foundational'
        WHEN AVG(CASE WHEN question_tier = 'advanced' THEN performance END) < 0.7 THEN 'intermediate'
        ELSE 'advanced'
    END AS placement_level,
    AVG(performance) AS overall_score
FROM diagnostic_results
WHERE goal_id = :goal_id;

-- Note: Requires diagnostic_results table (add to schema if needed)
-- CREATE TABLE IF NOT EXISTS diagnostic_results (
--     id INTEGER PRIMARY KEY AUTOINCREMENT,
--     goal_id TEXT NOT NULL,
--     topic_id INTEGER NOT NULL,
--     question_tier TEXT NOT NULL,
--     performance REAL NOT NULL CHECK(performance >= 0.0 AND performance <= 1.0),
--     completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id),
--     FOREIGN KEY (topic_id) REFERENCES topics(id)
-- );
