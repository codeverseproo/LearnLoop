-- ============================================
-- FSRS-6 CALCULATIONS (Canonical)
-- ============================================
-- Reference: github.com/SqueakyRobot/fsrs/docs/ALGORITHM.md
-- Formula parameters stored in fsrs_parameters table
-- ============================================

-- ============================================
-- RETRIEVABILITY CALCULATION
-- ============================================
-- R(t, S) = (1 + F*t/S)^(-0.5) where F = 19/81
-- Query: Calculate retrievability for all due topics
-- Parameters: :goal_id

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
        POWER(1 + (19.0/81.0) * (julianday('now') - julianday(f.last_review)) / f.stability, -0.5) AS retrievability
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
-- PERFORMANCE TO RATING MAPPING
-- ============================================
-- Returns: 1=Again, 2=Hard, 3=Good, 4=Easy
-- :performance is bound parameter (0.0-1.0)
SELECT CASE
    WHEN :performance < 0.3 THEN 1
    WHEN :performance < 0.5 THEN 2
    WHEN :performance < 0.8 THEN 3
    ELSE 4
END AS rating;

-- ============================================
-- INITIAL STABILITY (New Cards)
-- ============================================
-- :rating is bound parameter (1-4)
SELECT CASE :rating
    WHEN 1 THEN w0  -- Again: 0.4 days
    WHEN 2 THEN w1  -- Hard: 0.6 days
    WHEN 3 THEN w2  -- Good: 2.4 days
    WHEN 4 THEN w3  -- Easy: 10.0 days
END AS initial_stability
FROM fsrs_parameters WHERE id = 1;

-- ============================================
-- INITIAL DIFFICULTY (New Cards)
-- ============================================
-- D_0 = w4 - w5 * (rating - 3)
SELECT
    w4 - w5 * (:rating - 3) AS initial_difficulty
FROM fsrs_parameters WHERE id = 1;

-- ============================================
-- STABILITY UPDATE (Success: rating >= 2)
-- ============================================
-- S' = S * (1 + exp(w8) * (11-D) * S^(-w9) * (exp(w10*(1-R)) - 1) * h * b)
-- Hard (2): h=1.2, b=1.0
-- Good (3):  h=1.0, b=1.0
-- Easy (4):  h=1.0, b=1.3
WITH params AS (
    SELECT w4, w5, w7, w8, w9, w10 FROM fsrs_parameters WHERE id = 1
),
rating_factors AS (
    SELECT
        CASE :rating
            WHEN 2 THEN 1.2
            WHEN 3 THEN 1.0
            WHEN 4 THEN 1.0
        END AS h,
        CASE :rating
            WHEN 2 THEN 1.0
            WHEN 3 THEN 1.0
            WHEN 4 THEN 1.3
        END AS b
)
UPDATE fsrs_state
SET
    stability = MIN(365.0,
        stability * (1 + EXP(p.w8) * (11.0 - difficulty) * POWER(stability, -p.w9)
                     * (EXP(p.w10 * (1 - :retrievability)) - 1) * rf.h * rf.b)
    ),
    difficulty = MAX(1.0, MIN(10.0,
        p.w7 * difficulty + (1 - p.w7) * (p.w4 - p.w5 * (:rating - 3))
    )),
    state = CASE
        WHEN state = 0 THEN 1
        WHEN state = 1 THEN 2
        WHEN state = 3 THEN 2
        ELSE state
    END,
    last_review = CURRENT_TIMESTAMP,
    last_rating = :rating,
    next_review = datetime('now', '+' || CAST(ROUND(stability) AS INTEGER) || ' days'),
    reviews = reviews + 1
FROM fsrs_parameters p, rating_factors rf
WHERE topic_id = :topic_id AND :rating >= 2;

-- ============================================
-- STABILITY UPDATE (Lapse: rating = 1)
-- ============================================
-- S' = w11 * D^(-w12) * ((S+1)^w13 - 1) * exp(w14*(1-R))
WITH params AS (
    SELECT w4, w5, w7, w11, w12, w13, w14 FROM fsrs_parameters WHERE id = 1
)
UPDATE fsrs_state
SET
    stability = MAX(1.0,
        p.w11 * POWER(difficulty, -p.w12) * (POWER(stability + 1, p.w13) - 1)
        * EXP(p.w14 * (1 - :retrievability))
    ),
    difficulty = MAX(1.0, MIN(10.0,
        (SELECT w7 FROM fsrs_parameters WHERE id = 1) * difficulty
        + (1 - (SELECT w7 FROM fsrs_parameters WHERE id = 1))
        * ((SELECT w4 FROM fsrs_parameters WHERE id = 1) - (SELECT w5 FROM fsrs_parameters WHERE id = 1) * (1 - 3))
    )),
    state = CASE
        WHEN state = 2 THEN 3
        ELSE 1
    END,
    last_review = CURRENT_TIMESTAMP,
    last_rating = 1,
    next_review = datetime('now', '+' || CAST(ROUND(stability) AS INTEGER) || ' days'),
    reviews = reviews + 1,
    lapses = lapses + 1
FROM params p
WHERE topic_id = :topic_id AND :rating = 1;

-- ============================================
-- MASTERY SCORE CALCULATION
-- ============================================
-- mastery = 1 - exp(-0.5 * stability / difficulty)
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
WITH due_topics AS (
    SELECT
        t.id,
        t.topic_id,
        t.name,
        f.stability,
        f.difficulty,
        f.state,
        f.last_review,
        f.last_rating,
        POWER(1 + (19.0/81.0) * (julianday('now') - julianday(f.last_review)) / f.stability, -0.5) AS retrievability
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
    last_rating,
    retrievability
FROM due_topics
ORDER BY retrievability ASC
LIMIT 20;
