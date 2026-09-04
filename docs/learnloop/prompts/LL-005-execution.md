# LL-005: Learning Session Workflow

**Execution Prompt — Copy and paste into Claude session**

---

## STORY METADATA

```yaml
ID: LL-005
Title: Learning Session Workflow
Phase: 2
Effort: 3 hours
Impact: Core learning functionality via pure MCP
Dependencies: LL-004 (Phase 1 Complete)
Parallelizable with: LL-006, LL-007, LL-008, LL-009
```

---

## PREFLIGHT CHECKS

```bash
set -e
echo "=== PREFLIGHT CHECKS FOR LL-005 ==="

# 1. Phase 1 complete (LL-004 passed)
jq -e '.LL-004.status == "passed"' .superpowers/state/story-progress.json > /dev/null || { echo "FAIL: Phase 1 not complete"; exit 1; }

# 2. learning.sql exists
test -f docs/learnloop/mcp-queries/learning.sql || { echo "FAIL: learning.sql not found"; exit 1; }

echo "✓ ALL PREFLIGHT CHECKS PASSED"
```

---

## STATE INITIALIZATION

```bash
cat > .superpowers/checkpoints/LL-005-START << 'EOF'
{"storyId": "LL-005", "createdAt": "'$(date -Iseconds)'", "gitRef": "'$(git rev-parse HEAD)'"}
EOF

jq '.LL-005 = {"status": "in-progress", "phase": 2, "title": "Learning Session Workflow", "startedAt": "'$(date -Iseconds)'", "dependencies": ["LL-004"]}' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json
```

---

## IMPLEMENTATION STEPS

### Step 1: Define Learning Session Workflow

Update SKILL.md with complete workflow:

```markdown
## Workflow: learning_session

**Trigger:** "Learn [topic]" / "Start learning [topic]" / "I want to learn [topic]"

### Flow

1. **Check/Create Topic**
   ```sql
   -- Check if topic exists
   SELECT id, topic_id, name, mastery FROM topics WHERE name LIKE :topic_name;

   -- Create if not exists
   INSERT INTO topics (topic_id, name, status)
   VALUES ('T' || strftime('%Y%m%d%H%M%S', 'now') || '-' || LOWER(REPLACE(:topic_name, ' ', '-')), :topic_name, 'in_progress');
   ```

2. **Initialize FSRS State**
   ```sql
   INSERT INTO fsrs_state (topic_id, stability, difficulty, state, last_review)
   VALUES (:topic_id, 2.5, 5.0, 0, CURRENT_TIMESTAMP);
   ```

3. **Get Prerequisites**
   ```sql
   SELECT t.topic_id, t.name, t.mastery
   FROM topics t
   JOIN prerequisites p ON t.id = p.prerequisite_id
   WHERE p.topic_id = :current_topic_id
   ORDER BY t.mastery ASC;
   ```

4. **Start Session**
   ```sql
   INSERT INTO sessions (session_type, topic_id, started_at)
   VALUES ('learning', :topic_id, CURRENT_TIMESTAMP);
   SELECT last_insert_rowid() AS session_id;
   ```

5. **During Learning**
   - User studies topic content
   - Claude tracks time informally
   - Periodic comprehension checks

6. **End Session**
   ```sql
   UPDATE sessions
   SET ended_at = CURRENT_TIMESTAMP,
       performance = :performance,
       duration_seconds = :duration,
       notes = :notes
   WHERE id = :session_id;
   ```

7. **Update Mastery**
   ```sql
   -- FSRS update from fsrs.sql
   UPDATE fsrs_state SET ...;
   UPDATE topics SET mastery = ...;
   ```

8. **Increment Streak**
   ```sql
   UPDATE streak_state
   SET current_streak = CASE
       WHEN last_activity_date = date('now') THEN current_streak
       WHEN last_activity_date = date('now', '-1 day') THEN current_streak + 1
       ELSE 1
   END,
   longest_streak = MAX(longest_streak, current_streak + 1),
   last_activity_date = date('now')
   WHERE goal_id = :goal_id;
   ```
```

---

### Step 2: Test Topic Creation

```sql
-- Test: Create topic
INSERT INTO topics (topic_id, name, status, created_at)
VALUES ('T01-learn-test', 'Python Basics', 'in_progress', CURRENT_TIMESTAMP);

-- Verify
SELECT * FROM topics WHERE topic_id = 'T01-learn-test';
```

Execute via MCP:
```markdown
mcp__sqlite__query({
  database: "~/.mit-learning/goals/test/memory.db",
  query: "INSERT INTO topics (topic_id, name, status) VALUES ('T01-learn-test', 'Python Basics', 'in_progress');"
})
```

---

### Step 3: Test Session Tracking

```sql
-- Start session
INSERT INTO sessions (session_type, topic_id, started_at)
VALUES ('learning', (SELECT id FROM topics WHERE topic_id = 'T01-learn-test'), CURRENT_TIMESTAMP);

-- Get session ID
SELECT last_insert_rowid();

-- End session (assume session_id = 1)
UPDATE sessions
SET ended_at = datetime('now', '+30 minutes'),
    performance = 0.75,
    duration_seconds = 1800,
    notes = 'Good understanding of basics'
WHERE id = 1;

-- Verify
SELECT * FROM sessions WHERE topic_id = (SELECT id FROM topics WHERE topic_id = 'T01-learn-test');
```

---

### Step 4: Test Mastery Update

```sql
-- Initialize FSRS
INSERT INTO fsrs_state (topic_id, stability, difficulty, state, last_review, reviews)
VALUES ((SELECT id FROM topics WHERE topic_id = 'T01-learn-test'), 2.5, 5.0, 1, CURRENT_TIMESTAMP, 0);

-- Update after session (performance = 0.75, success)
UPDATE fsrs_state
SET
    stability = MIN(365.0, stability * (1 + (11.0 - difficulty) * 0.1 * 1.3 * (1 + SQRT(stability)/10.0) * 1.25)),
    difficulty = MIN(10.0, MAX(1.0, difficulty + 0.05)),
    state = 2,
    last_review = CURRENT_TIMESTAMP,
    next_review = datetime('now', '+' || CAST(stability AS INTEGER) || ' days'),
    reviews = reviews + 1
WHERE topic_id = (SELECT id FROM topics WHERE topic_id = 'T01-learn-test');

-- Update mastery
UPDATE topics
SET
    mastery = 1 - EXP(-0.5 * (SELECT stability FROM fsrs_state WHERE topic_id = id) /
                       (SELECT difficulty FROM fsrs_state WHERE topic_id = id)),
    status = 'in_progress',
    updated_at = CURRENT_TIMESTAMP
WHERE topic_id = 'T01-learn-test';

-- Verify
SELECT t.topic_id, t.name, t.mastery, t.status, f.stability, f.difficulty, f.next_review
FROM topics t
JOIN fsrs_state f ON t.id = f.topic_id
WHERE t.topic_id = 'T01-learn-test';
```

---

### Step 5: Test Streak Increment

```sql
-- Initialize streak
INSERT INTO streak_state (goal_id, current_streak, last_activity_date)
VALUES ('test', 0, date('now', '-1 day'));

-- After activity
UPDATE streak_state
SET
    current_streak = current_streak + 1,
    longest_streak = MAX(longest_streak, current_streak + 1),
    last_activity_date = date('now')
WHERE goal_id = 'test';

-- Verify
SELECT * FROM streak_state WHERE goal_id = 'test';
```

---

## TESTING & VERIFICATION

```bash
echo "=== LEARNING WORKFLOW VERIFICATION ==="

# 1. Topic created
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT name FROM topics WHERE topic_id='T01-learn-test';" | grep -q "Python" && echo "✓ [1/5] Topic created"

# 2. Session recorded
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT session_type FROM sessions WHERE topic_id=(SELECT id FROM topics WHERE topic_id='T01-learn-test');" | grep -q "learning" && echo "✓ [2/5] Session recorded"

# 3. FSRS initialized
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT stability FROM fsrs_state WHERE topic_id=(SELECT id FROM topics WHERE topic_id='T01-learn-test');" | grep -q "." && echo "✓ [3/5] FSRS initialized"

# 4. Mastery updated
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT mastery FROM topics WHERE topic_id='T01-learn-test';" | grep -q "0\." && echo "✓ [4/5] Mastery calculated"

# 5. Streak incremented
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT current_streak FROM streak_state WHERE goal_id='test';" | grep -q "1" && echo "✓ [5/5] Streak incremented"

echo "=== ALL VERIFICATIONS PASSED ==="
```

---

## HUMAN VERIFICATION

```markdown
Verify:
- [ ] Topic creation works via MCP
- [ ] Session start/end tracked
- [ ] FSRS state initialized correctly
- [ ] Mastery updated after session
- [ ] Streak increments on activity
- [ ] SKILL.md has complete workflow

## HUMAN SIGN-OFF ##
Status: [ ] I have verified learning_session workflow works end-to-end.
```

---

## SUCCESS CRITERIA

```bash
echo "=== ACCEPTANCE CRITERIA ==="

sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT COUNT(*) FROM topics WHERE topic_id='T01-learn-test';" | grep -q "1" && echo "✓ [1/5] Topic exists"
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT COUNT(*) FROM sessions WHERE session_type='learning';" | grep -q "1" && echo "✓ [2/5] Session recorded"
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT COUNT(*) FROM fsrs_state;" | grep -q "." && echo "✓ [3/5] FSRS state exists"
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT mastery FROM topics WHERE topic_id='T01-learn-test';" | grep -v "0.00" && echo "✓ [4/5] Mastery updated"
grep -q "Workflow: learning_session" SKILL.md && echo "✓ [5/5] SKILL.md documented"

echo "=== ALL CRITERIA VERIFIED ==="
```

---

## CLEANUP & COMPLETION

```bash
git add SKILL.md docs/learnloop/mcp-queries/learning.sql
git commit -m "feat(LL-005): learning session workflow

- Complete learning_session workflow in SKILL.md
- Topic creation via MCP
- Session tracking
- FSRS state initialization
- Mastery calculation
- Streak increment

Story: LL-005
Phase: 2
Dependencies: LL-004
"

jq '.LL-005.status = "passed" | .LL-005.completedAt = "'$(date -Iseconds)'"' \
  .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json

cat > .superpowers/checkpoints/LL-005-PASS << 'EOF'
{"storyId": "LL-005", "status": "passed", "completedAt": "'$(date -Iseconds)'"}
EOF

echo "✓ LL-005 passed"
```

---

## ROLLBACK

```bash
#!/bin/bash
set -e
REF=$(jq -r '.gitRef' .superpowers/checkpoints/LL-005-START)
git checkout $REF -- SKILL.md
jq '.LL-005.status = "pending"' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json
rm -f .superpowers/checkpoints/LL-005-*
echo "Rollback complete"
```

---

**NEXT:** LL-006 (can run in parallel)

**END OF EXECUTION PROMPT FOR LL-005**
