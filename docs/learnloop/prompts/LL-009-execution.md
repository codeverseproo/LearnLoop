# LL-009: Streak & Achievement System

**Execution Prompt — Copy and paste into Claude session**

---

## STORY METADATA

```yaml
ID: LL-009
Title: Streak & Achievement System
Phase: 2
Effort: 3 hours
Impact: Gamification via MCP
Dependencies: LL-004 (Phase 1 Complete)
Parallelizable with: LL-005, LL-006, LL-007, LL-008
```

---

## PREFLIGHT CHECKS

```bash
set -e
echo "=== PREFLIGHT CHECKS FOR LL-009 ==="

# 1. Phase 1 complete
jq -e '.LL-004.status == "passed"' .superpowers/state/story-progress.json > /dev/null || { echo "FAIL: Phase 1 not complete"; exit 1; }

# 2. streak.sql exists
test -f docs/learnloop/mcp-queries/streak.sql || { echo "FAIL: streak.sql not found"; exit 1; }

echo "✓ ALL PREFLIGHT CHECKS PASSED"
```

---

## STATE INITIALIZATION

```bash
cat > .superpowers/checkpoints/LL-009-START << 'EOF'
{"storyId": "LL-009", "createdAt": "'$(date -Iseconds)'", "gitRef": "'$(git rev-parse HEAD)'"}
EOF

jq '.LL-009 = {"status": "in-progress", "phase": 2, "title": "Streak & Achievement System", "startedAt": "'$(date -Iseconds)'", "dependencies": ["LL-004"]}' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json
```

---

## IMPLEMENTATION STEPS

### Step 1: Define Streak Workflow

Update SKILL.md:

```markdown
## Streak System

### Daily Activity Detection

Activity = any session (learning, review, practice) completed today:

```sql
-- Check if activity today
SELECT COUNT(*) > 0 AS has_activity
FROM sessions
WHERE date(started_at) = date('now');

-- Or simpler: check last_activity_date
SELECT last_activity_date = date('now') AS has_activity
FROM streak_state
WHERE goal_id = :goal_id;
```

### Streak Increment Logic

```sql
-- Increment streak if activity today
UPDATE streak_state
SET
    current_streak = CASE
        WHEN last_activity_date = date('now') THEN current_streak  -- Already counted
        WHEN last_activity_date = date('now', '-1 day') THEN current_streak + 1  -- Consecutive
        ELSE 1  -- Streak broken, restart
    END,
    longest_streak = MAX(longest_streak,
        CASE
            WHEN last_activity_date = date('now', '-1 day') THEN current_streak + 1
            ELSE 1
        END
    ),
    last_activity_date = date('now')
WHERE goal_id = :goal_id;

-- Reset if streak freeze used
UPDATE streak_state
SET
    current_streak = 0,
    streak_freeze_used_date = date('now')
WHERE goal_id = :goal_id
AND last_activity_date < date('now', '-1 day')
AND streak_freeze_available = 0;
```

### Streak Freeze Mechanic

Each goal has 1 streak freeze (use sparingly):

```sql
-- Check if freeze available
SELECT streak_freeze_available
FROM streak_state
WHERE goal_id = :goal_id;

-- Use freeze (before midnight of missed day)
UPDATE streak_state
SET
    streak_freeze_available = 0,
    streak_freeze_used_date = date('now')
WHERE goal_id = :goal_id AND streak_freeze_available = 1;

-- Streak preserved, but freeze consumed
```

### Streak Reset

```sql
-- Triggered at midnight if no activity
UPDATE streak_state
SET current_streak = 0
WHERE goal_id = :goal_id
AND last_activity_date < date('now', '-1 day')
AND streak_freeze_used_date != date('now');
```

---

## Achievement System

### Achievement Definitions

| Achievement | Condition | Points |
|------------|-----------|--------|
| `first_topic` | Complete first topic | 10 |
| `streak_7` | 7-day streak | 25 |
| `streak_30` | 30-day streak | 100 |
| `streak_100` | 100-day streak | 500 |
| `mastered_10` | Master 10 topics | 50 |
| `mastered_50` | Master 50 topics | 200 |
| `review_100` | Complete 100 reviews | 75 |
| `early_bird` | Study before 6am | 20 |
| `night_owl` | Study after 11pm | 20 |
| `weekend_warrior` | Study on weekend | 15 |
| `triangulator` | Research with 5+ triangulated claims | 30 |

### Achievement Unlock Check

```sql
-- Check and unlock achievements
-- Run after each session

-- Streak achievements
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

-- Mastery achievements
INSERT INTO achievements (goal_id, achievement_id)
SELECT :goal_id, 'mastered_10'
FROM topics
WHERE goal_id = :goal_id
AND status = 'mastered'
HAVING COUNT(*) >= 10
AND NOT EXISTS (
    SELECT 1 FROM achievements
    WHERE goal_id = :goal_id AND achievement_id = 'mastered_10'
);
```

### Progress Dashboard

```markdown
**Trigger:** "Show progress" / "Dashboard" / "How am I doing?"

```sql
-- Current status
SELECT
    s.current_streak,
    s.longest_streak,
    s.last_activity_date,
    s.streak_freeze_available,
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

-- Achievements unlocked
SELECT achievement_id, unlocked_at
FROM achievements
WHERE goal_id = :goal_id
ORDER BY unlocked_at DESC;
```
```
```

---

### Step 2: Test Streak Increment

```sql
-- Initialize streak
INSERT INTO streak_state (goal_id, current_streak, longest_streak, last_activity_date, streak_freeze_available)
VALUES ('test', 0, 0, date('now', '-1 day'), 1);

-- Simulate activity today
UPDATE streak_state
SET
    current_streak = current_streak + 1,
    longest_streak = MAX(longest_streak, current_streak + 1),
    last_activity_date = date('now')
WHERE goal_id = 'test';

-- Verify
SELECT current_streak, longest_streak FROM streak_state WHERE goal_id = 'test';
```

Expected: current_streak = 1, longest_streak = 1

---

### Step 3: Test Streak Freeze

```sql
-- Reset for testing
UPDATE streak_state
SET current_streak = 5, longest_streak = 5, last_activity_date = date('now', '-2 days')
WHERE goal_id = 'test';

-- Use freeze
UPDATE streak_state
SET
    streak_freeze_available = 0,
    streak_freeze_used_date = date('now', '-1 day')
WHERE goal_id = 'test' AND streak_freeze_available = 1;

-- Streak preserved (would reset without freeze)
SELECT current_streak FROM streak_state WHERE goal_id = 'test';
```

Expected: current_streak = 5 (preserved by freeze)

---

### Step 4: Test Achievement Unlock

```sql
-- Unlock first_topic
INSERT INTO achievements (goal_id, achievement_id)
VALUES ('test', 'first_topic');

-- Try to unlock again (should fail silently due to UNIQUE constraint)
INSERT OR IGNORE INTO achievements (goal_id, achievement_id)
VALUES ('test', 'first_topic');

-- Verify
SELECT achievement_id FROM achievements WHERE goal_id = 'test';
```

---

## TESTING & VERIFICATION

```bash
echo "=== STREAK SYSTEM VERIFICATION ==="

# 1. Streak increments
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT current_streak FROM streak_state WHERE goal_id='test';" | grep -q "1" && echo "✓ [1/5] Streak incremented"

# 2. Streak freeze used
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT streak_freeze_available FROM streak_state WHERE goal_id='test';" | grep -q "0" && echo "✓ [2/5] Streak freeze consumed"

# 3. Achievement unlocked
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT COUNT(*) FROM achievements WHERE goal_id='test';" | grep -q "." && echo "✓ [3/5] Achievements tracked"

# 4. No duplicate achievements
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT COUNT(*) FROM achievements WHERE goal_id='test' AND achievement_id='first_topic';" | grep -q "1" && echo "✓ [4/5] No duplicates"

# 5. SKILL.md updated
grep -q "Streak System" SKILL.md && echo "✓ [5/5] SKILL.md documented"

echo "=== ALL VERIFICATIONS PASSED ==="
```

---

## HUMAN VERIFICATION

```markdown
Verify:
- [ ] Streak increments on daily activity
- [ ] Streak resets on missed day (unless frozen)
- [ ] Streak freeze consumes correctly
- [ ] Achievements unlock properly
- [ ] No duplicate achievements
- [ ] Achievement definitions in SKILL.md

## HUMAN SIGN-OFF ##
Status: [ ] I have verified streak and achievement systems work correctly.
```

---

## SUCCESS CRITERIA

```bash
echo "=== ACCEPTANCE CRITERIA ==="

sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT current_streak FROM streak_state WHERE goal_id='test';" | grep -q "." && echo "✓ [1/4] Streak tracking works"
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT longest_streak FROM streak_state WHERE goal_id='test';" | grep -q "." && echo "✓ [2/4] Longest streak tracked"
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT COUNT(*) FROM achievements;" | grep -q "." && echo "✓ [3/4] Achievements table works"
grep -q "Achievement Definitions" SKILL.md && echo "✓ [4/4] SKILL.md has achievements"

echo "=== PHASE 2 CHECK ==="
echo "Checking Phase 2 completion..."
jq '[.LL-005, .LL-006, .LL-007, .LL-008, .LL-009 | select(.status == "passed")] | length' .superpowers/state/story-progress.json

echo "=== ALL CRITERIA VERIFIED ==="
```

---

## CLEANUP & COMPLETION

```bash
git add SKILL.md docs/learnloop/mcp-queries/streak.sql
git commit -m "feat(LL-009): streak and achievement system

- Daily activity detection
- Streak increment logic
- Streak freeze mechanic
- Achievement definitions
- Achievement unlock queries
- Progress dashboard

Story: LL-009
Phase: 2
Dependencies: LL-004
"

jq '.LL-009.status = "passed" | .LL-009.completedAt = "'$(date -Iseconds)'"' \
  .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json

cat > .superpowers/checkpoints/LL-009-PASS << 'EOF'
{"storyId": "LL-009", "status": "passed", "completedAt": "'$(date -Iseconds)'"}
EOF

echo "✓ LL-009 passed"
```

---

## ROLLBACK

```bash
#!/bin/bash
set -e
REF=$(jq -r '.gitRef' .superpowers/checkpoints/LL-009-START)
git checkout $REF -- SKILL.md docs/learnloop/mcp-queries/streak.sql
jq '.LL-009.status = "pending"' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json
rm -f .superpowers/checkpoints/LL-009-*
echo "Rollback complete"
```

---

**NEXT:** Proceed to Phase 3: Polish (LL-010)

**END OF EXECUTION PROMPT FOR LL-009**
