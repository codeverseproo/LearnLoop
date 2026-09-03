-- ============================================
-- STREAK TRACKING QUERIES
-- ============================================

-- Initialize streak for goal
-- Parameters: :goal_id

INSERT INTO streak_state (goal_id, current_streak, longest_streak, last_activity_date, streak_freeze_available)
VALUES (:goal_id, 0, 0, date('now'), 1)
ON CONFLICT(goal_id) DO NOTHING;

-- Increment streak (activity logged)
-- Parameters: :goal_id

UPDATE streak_state
SET
    current_streak = CASE
        WHEN last_activity_date = date('now') THEN current_streak
        WHEN last_activity_date = date('now', '-1 day') THEN current_streak + 1
        ELSE 1
    END,
    longest_streak = MAX(longest_streak,
        CASE
            WHEN last_activity_date = date('now', '-1 day') THEN current_streak + 1
            ELSE 1
        END
    ),
    last_activity_date = date('now')
WHERE goal_id = :goal_id;

-- Use streak freeze
-- Parameters: :goal_id

UPDATE streak_state
SET
    streak_freeze_available = 0,
    streak_freeze_used_date = date('now')
WHERE goal_id = :goal_id
AND streak_freeze_available = 1;

-- Get streak status
-- Parameters: :goal_id

SELECT
    current_streak,
    longest_streak,
    last_activity_date,
    streak_freeze_available
FROM streak_state
WHERE goal_id = :goal_id;

-- ============================================
-- ACHIEVEMENT QUERIES
-- ============================================

-- Unlock achievement
-- Parameters: :goal_id, :achievement_id

INSERT INTO achievements (goal_id, achievement_id, unlocked_at)
VALUES (:goal_id, :achievement_id, CURRENT_TIMESTAMP)
ON CONFLICT(goal_id, achievement_id) DO NOTHING;

-- Get achievements for goal
-- Parameters: :goal_id

SELECT achievement_id, unlocked_at
FROM achievements
WHERE goal_id = :goal_id
ORDER BY unlocked_at DESC;

-- Check and unlock streak achievements
INSERT INTO achievements (goal_id, achievement_id)
SELECT goal_id, 'streak_7'
FROM streak_state
WHERE current_streak >= 7
AND NOT EXISTS (
    SELECT 1 FROM achievements
    WHERE goal_id = streak_state.goal_id
    AND achievement_id = 'streak_7'
);

INSERT INTO achievements (goal_id, achievement_id)
SELECT goal_id, 'streak_30'
FROM streak_state
WHERE current_streak >= 30
AND NOT EXISTS (
    SELECT 1 FROM achievements
    WHERE goal_id = streak_state.goal_id
    AND achievement_id = 'streak_30'
);

-- ============================================
-- PROGRESS DASHBOARD
-- ============================================

-- Get full progress report
SELECT
    s.current_streak,
    s.longest_streak,
    s.last_activity_date,
    (SELECT COUNT(*) FROM topics WHERE status = 'mastered') AS mastered,
    (SELECT COUNT(*) FROM achievements WHERE goal_id = :goal_id) AS achievements
FROM streak_state s
WHERE s.goal_id = :goal_id;

-- Recent activity
SELECT date(started_at) AS day, COUNT(*) AS sessions
FROM sessions
WHERE started_at >= date('now', '-7 days')
GROUP BY date(started_at)
ORDER BY day DESC;
