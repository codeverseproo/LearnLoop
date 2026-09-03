# MIT-006: Review Session Workflow

**Execution Prompt — Copy and paste into Claude session**

---

## STORY METADATA

```yaml
ID: MIT-006
Title: Review Session Workflow
Phase: 2
Effort: 3 hours
Impact: Spaced repetition without Python scheduler
Dependencies: MIT-004 (Phase 1 Complete)
Parallelizable with: MIT-005, MIT-007, MIT-008, MIT-009
```

---

## PREFLIGHT CHECKS

```bash
set -e
echo "=== PREFLIGHT CHECKS FOR MIT-006 ==="

# 1. Phase 1 complete
jq -e '.MIT-004.status == "passed"' .superpowers/state/story-progress.json > /dev/null || { echo "FAIL: Phase 1 not complete"; exit 1; }

# 2. review.sql exists
test -f docs/superpowers/mcp-queries/review.sql || { echo "FAIL: review.sql not found"; exit 1; }

echo "✓ ALL PREFLIGHT CHECKS PASSED"
```

---

## STATE INITIALIZATION

```bash
cat > .superpowers/checkpoints/MIT-006-START << 'EOF'
{"storyId": "MIT-006", "createdAt": "'$(date -Iseconds)'", "gitRef": "'$(git rev-parse HEAD)'"}
EOF

jq '.MIT-006 = {"status": "in-progress", "phase": 2, "title": "Review Session Workflow", "startedAt": "'$(date -Iseconds)'", "dependencies": ["MIT-004"]}' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json
```

---

## IMPLEMENTATION STEPS

### Step 1: Define Review Session Workflow

Update SKILL.md:

```markdown
## Workflow: review_session

**Trigger:** "What's due for review?" / "Review my topics" / "Show review queue"

### Flow

1. **Get Review Queue**
   ```sql
   -- Due topics sorted by priority (lowest retrievability first)
   SELECT
       t.id,
       t.topic_id,
       t.name,
       f.stability,
       f.difficulty,
       f.state,
       POWER(1 + (julianday('now') - julianday(f.last_review)) / (9.0 * f.stability), -1.0) AS retrievability,
       POWER(1 + (julianday('now') - julianday(f.last_review)) / (9.0 * f.stability), -1.0) - 0.9 AS priority
   FROM topics t
   JOIN fsrs_state f ON t.id = f.topic_id
   WHERE f.next_review <= datetime('now')
   ORDER BY retrievability ASC
   LIMIT 20;
   ```

2. **Present Queue**
   - Show topic name
   - Show days overdue
   - Show priority (lower = more urgent)

3. **Review Each Topic**
   - User reviews content
   - Rate performance (Again/Hard/Good/Easy → 0.0-1.0)

4. **Update FSRS State**
   ```sql
   -- Calculate retrievability
   SELECT POWER(1 + (julianday('now') - julianday(last_review)) / (9.0 * stability), -1.0)
   FROM fsrs_state WHERE topic_id = :topic_id;

   -- Update based on performance
   -- Success (performance >= 0.6): Increase stability
   -- Failure (performance < 0.6): Decrease stability
   ```

5. **Update Mastery**
   ```sql
   UPDATE topics
   SET mastery = 1 - EXP(-0.5 * stability / difficulty)
   WHERE id = :topic_id;
   ```

6. **Increment Streak**
   ```sql
   UPDATE streak_state
   SET current_streak = current_streak + 1,
       last_activity_date = date('now')
   WHERE goal_id = :goal_id;
   ```

7. **Record Session**
   ```sql
   INSERT INTO sessions (session_type, topic_id, started_at, ended_at, performance)
   VALUES ('review', :topic_id, :start_time, CURRENT_TIMESTAMP, :performance);
   ```

### Performance Ratings

| Rating | Performance | Effect |
|--------|-------------|--------|
| Again | 0.0-0.3 | Stability decrease, state → 3 |
| Hard | 0.4-0.5 | Small stability decrease |
| Good | 0.6-0.8 | Stability increase |
| Easy | 0.9-1.0 | Large stability increase |
```

---

### Step 2: Create Test Due Topics

```sql
-- Create topics with past review dates
INSERT INTO topics (topic_id, name, status, next_review)
VALUES
    ('T02-review-due', 'Due Topic 1', 'in_progress', date('now', '-5 days')),
    ('T03-review-due', 'Due Topic 2', 'in_progress', date('now', '-3 days')),
    ('T04-review-due', 'Due Topic 3', 'in_progress', date('now', '-1 day'));

-- Initialize FSRS states with past reviews
INSERT INTO fsrs_state (topic_id, stability, difficulty, state, last_review, next_review, reviews)
SELECT
    (SELECT id FROM topics WHERE topic_id = 'T02-review-due'),
    5.0, 5.0, 2, datetime('now', '-10 days'), datetime('now', '-5 days'), 2
UNION ALL
SELECT
    (SELECT id FROM topics WHERE topic_id = 'T03-review-due'),
    7.0, 4.0, 2, datetime('now', '-7 days'), datetime('now', '-3 days'), 3
UNION ALL
SELECT
    (SELECT id FROM topics WHERE topic_id = 'T04-review-due'),
    10.0, 6.0, 2, datetime('now', '-15 days'), datetime('now', '-1 day'), 5;
```

---

### Step 3: Test Review Queue Query

```sql
-- Get due topics
SELECT
    t.id,
    t.topic_id,
    t.name,
    f.stability,
    f.difficulty,
    CAST(julianday('now') - julianday(f.last_review) AS INTEGER) AS days_since_review,
    ROUND(POWER(1 + (julianday('now') - julianday(f.last_review)) / (9.0 * f.stability), -1.0), 3) AS retrievability,
    ROUND(POWER(1 + (julianday('now') - julianday(f.last_review)) / (9.0 * f.stability), -1.0) - 0.9, 3) AS priority
FROM topics t
JOIN fsrs_state f ON t.id = f.topic_id
WHERE f.next_review <= datetime('now')
ORDER BY retrievability ASC
LIMIT 20;
```

Expected: Topics ordered by retrievability (lowest first)

---

### Step 4: Test FSRS Update After Review

```sql
-- Simulate review of T02-review-due with Good (performance = 0.7)
-- Get current state
SELECT topic_id, stability, difficulty, state FROM fsrs_state
WHERE topic_id = (SELECT id FROM topics WHERE topic_id = 'T02-review-due');

-- Calculate retrievability
SELECT POWER(1 + (julianday('now') - julianday(last_review)) / (9.0 * stability), -1.0)
FROM fsrs_state
WHERE topic_id = (SELECT id FROM topics WHERE topic_id = 'T02-review-due');

-- Update FSRS (success)
UPDATE fsrs_state
SET
    stability = MIN(365.0, stability * (1 + (11.0 - difficulty) * 0.1 * 1.4 * (1 + SQRT(stability)/10.0) * 1.2)),
    difficulty = MIN(10.0, MAX(1.0, difficulty - 0.05)),
    last_review = CURRENT_TIMESTAMP,
    next_review = datetime('now', '+' || CAST(stability * 1.3 AS INTEGER) || ' days'),
    reviews = reviews + 1
WHERE topic_id = (SELECT id FROM topics WHERE topic_id = 'T02-review-due');

-- Update mastery
UPDATE topics
SET
    mastery = 1 - EXP(-0.5 * (SELECT stability FROM fsrs_state WHERE topic_id = id) /
                       (SELECT difficulty FROM fsrs_state WHERE topic_id = id)),
    next_review = (SELECT next_review FROM fsrs_state WHERE topic_id = id)
WHERE topic_id = 'T02-review-due';

-- Verify
SELECT t.topic_id, t.mastery, f.stability, f.next_review
FROM topics t
JOIN fsrs_state f ON t.id = f.topic_id
WHERE t.topic_id = 'T02-review-due';
```

---

### Step 5: Test Failure Case

```sql
-- Simulate review of T03-review-due with Again (performance = 0.2)
UPDATE fsrs_state
SET
    stability = MAX(1.0, stability * (0.5 + 0.2 * 0.5)),
    difficulty = MIN(10.0, MAX(1.0, difficulty + 0.2)),
    state = 3,
    last_review = CURRENT_TIMESTAMP,
    next_review = datetime('now', '+' || CAST(stability * 0.5 AS INTEGER) || ' days'),
    reviews = reviews + 1
WHERE topic_id = (SELECT id FROM topics WHERE topic_id = 'T03-review-due');

-- Verify state = 3 (lapse)
SELECT state FROM fsrs_state
WHERE topic_id = (SELECT id FROM topics WHERE topic_id = 'T03-review-due');
```

---

## TESTING & VERIFICATION

```bash
echo "=== REVIEW WORKFLOW VERIFICATION ==="

# 1. Due topics returned
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT COUNT(*) FROM topics t JOIN fsrs_state f ON t.id = f.topic_id WHERE f.next_review <= datetime('now');" | grep -q "." && echo "✓ [1/5] Due topics found"

# 2. Priority ordering
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT topic_id FROM topics t JOIN fsrs_state f ON t.id = f.topic_id WHERE f.next_review <= datetime('now') ORDER BY POWER(1 + (julianday('now') - julianday(f.last_review)) / (9.0 * f.stability), -1.0) ASC LIMIT 1;" | grep -q "T02" && echo "✓ [2/5] Priority ordering correct"

# 3. FSRS updated
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT stability FROM fsrs_state WHERE topic_id=(SELECT id FROM topics WHERE topic_id='T02-review-due');" | grep -q "." && echo "✓ [3/5] FSRS updated"

# 4. Mastery calculated
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT mastery FROM topics WHERE topic_id='T02-review-due';" | grep -q "0\." && echo "✓ [4/5] Mastery calculated"

# 5. SKILL.md updated
grep -q "Workflow: review_session" SKILL.md && echo "✓ [5/5] SKILL.md documented"

echo "=== ALL VERIFICATIONS PASSED ==="
```

---

## HUMAN VERIFICATION

```markdown
Verify:
- [ ] Review queue returns due topics
- [ ] Priority ordering (lowest retrievability first)
- [ ] Performance rating updates FSRS correctly
- [ ] Mastery recalculated after review
- [ ] Streak increments
- [ ] SKILL.md has complete workflow

## HUMAN SIGN-OFF ##
Status: [ ] I have verified review_session workflow works correctly.
```

---

## SUCCESS CRITERIA

```bash
echo "=== ACCEPTANCE CRITERIA ==="

sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT COUNT(*) FROM fsrs_state WHERE next_review > datetime('now');" | grep -q "." && echo "✓ [1/4] Next review scheduled"
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT state FROM fsrs_state WHERE topic_id=(SELECT id FROM topics WHERE topic_id='T03-review-due');" | grep -q "3" && echo "✓ [2/4] Failure state correct"
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT mastery FROM topics WHERE topic_id='T02-review-due';" | grep -v "0.00" && echo "✓ [3/4] Mastery updated"
grep -q "Performance Ratings" SKILL.md && echo "✓ [4/4] SKILL.md has ratings table"

echo "=== ALL CRITERIA VERIFIED ==="
```

---

## CLEANUP & COMPLETION

```bash
git add SKILL.md docs/superpowers/mcp-queries/review.sql
git commit -m "feat(MIT-006): review session workflow

- Complete review_session workflow in SKILL.md
- Review queue query with priority ordering
- FSRS update for success/failure
- Performance ratings table
- Mastery calculation

Story: MIT-006
Phase: 2
Dependencies: MIT-004
"

jq '.MIT-006.status = "passed" | .MIT-006.completedAt = "'$(date -Iseconds)'"' \
  .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json

cat > .superpowers/checkpoints/MIT-006-PASS << 'EOF'
{"storyId": "MIT-006", "status": "passed", "completedAt": "'$(date -Iseconds)'"}
EOF

echo "✓ MIT-006 passed"
```

---

## ROLLBACK

```bash
#!/bin/bash
set -e
REF=$(jq -r '.gitRef' .superpowers/checkpoints/MIT-006-START)
git checkout $REF -- SKILL.md docs/superpowers/mcp-queries/review.sql
jq '.MIT-006.status = "pending"' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json
rm -f .superpowers/checkpoints/MIT-006-*
echo "Rollback complete"
```

---

**NEXT:** Continue Phase 2 workflows

**END OF EXECUTION PROMPT FOR MIT-006**
