-- ============================================
-- FSRS-6 CALCULATIONS
-- ============================================

-- Retrievability calculation: R(t, S) = (1 + t/(9*S))^(-1)
-- Query: Calculate retrievability for all due topics
-- Parameters: :goal_id

-- Optimized with CTE to avoid duplicate POWER() calculation
WITH fsrs_retrievability AS (
    SELECT
        t.id,
        t.topic_id,
        t.name,
        f.stability,
        f.difficulty,
        f.state,
        f.last_review,
        CAST(julianday('now') - julianday(f.last_review) AS REAL) AS days_since_review,
        POWER(1 + (julianday('now') - julianday(f.last_review)) / (9.0 * f.stability), -1.0) AS retrievability
    FROM topics t
    JOIN fsrs_state f ON t.id = f.topic_id
    WHERE t.next_review <= date('now')
)
SELECT
    id,
    topic_id,
    name,
    stability,
    difficulty,
    state,
    last_review,
    days_since_review,
    retrievability,
    retrievability - 0.9 AS priority
FROM fsrs_retrievability
ORDER BY priority ASC
LIMIT 20;

-- ============================================
-- STABILITY UPDATE (Success: performance >= 0.6)
-- ============================================
-- Formula: S' = S * (1 + f(D) * 0.1 * p_factor * f(S) * f(R))
-- Parameters: :topic_id, :performance, :retrievability

UPDATE fsrs_state
SET
    stability = MIN(365.0, stability * (1 + (11.0 - difficulty) * 0.1 * (1 + (:performance - 0.6) * 2) * (1 + SQRT(stability)/10.0) * (0.5 + :retrievability))),
    difficulty = MIN(10.0, MAX(1.0, difficulty + (5.0 - difficulty) * 0.15 + (1 - :performance) * 0.2)),
    state = CASE
        WHEN state = 0 THEN 1
        WHEN state = 1 AND :performance >= 0.6 THEN 2
        WHEN state = 2 AND :performance < 0.6 THEN 3
        WHEN state = 3 AND :performance >= 0.6 THEN 2
        ELSE state
    END,
    last_review = CURRENT_TIMESTAMP,
    next_review = datetime('now', '+' || CAST(ROUND(9.0 * stability * (POWER(0.9, -1) - 1)) AS INTEGER) || ' days'),
    reviews = reviews + 1
WHERE topic_id = :topic_id AND :performance >= 0.6;

-- ============================================
-- STABILITY UPDATE (Failure: performance < 0.6)
-- ============================================
-- Formula: S' = S * (0.5 + performance * 0.5)

UPDATE fsrs_state
SET
    stability = MAX(1.0, stability * (0.5 + :performance * 0.5)),
    difficulty = MIN(10.0, MAX(1.0, difficulty + (5.0 - difficulty) * 0.15 + (1 - :performance) * 0.2)),
    state = CASE
        WHEN state = 2 THEN 3
        WHEN state = 1 THEN 1
        ELSE state
    END,
    last_review = CURRENT_TIMESTAMP,
    next_review = datetime('now', '+' || CAST(stability AS INTEGER) || ' days'),
    reviews = reviews + 1
WHERE topic_id = :topic_id AND :performance < 0.6;

-- ============================================
-- MASTERY SCORE CALCULATION
-- ============================================
-- Formula: mastery = 1 - exp(-0.5 * stability / difficulty)

UPDATE topics
SET
    mastery = 1 - EXP(-0.5 * (SELECT stability FROM fsrs_state WHERE topic_id = id) /
                       (SELECT difficulty FROM fsrs_state WHERE topic_id = id)),
    status = CASE
        WHEN mastery >= 0.9 THEN 'mastered'
        WHEN mastery > 0.0 THEN 'in_progress'
        ELSE 'pending'
    END,
    updated_at = CURRENT_TIMESTAMP
WHERE id = :topic_id;

-- ============================================
-- GET DUE TOPICS FOR REVIEW
-- ============================================

-- Optimized with CTE for retrievability calculation
WITH due_topics AS (
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
    WHERE f.next_review <= datetime('now')
)
SELECT
    id,
    topic_id,
    name,
    stability,
    difficulty,
    state,
    retrievability
FROM due_topics
ORDER BY retrievability ASC
LIMIT 20;
