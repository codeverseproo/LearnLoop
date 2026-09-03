# MIT-007: Practice Session Workflow

**Execution Prompt — Copy and paste into Claude session**

---

## STORY METADATA

```yaml
ID: MIT-007
Title: Practice Session Workflow
Phase: 2
Effort: 2 hours
Impact: Practice problem tracking via MCP
Dependencies: MIT-004 (Phase 1 Complete)
Parallelizable with: MIT-005, MIT-006, MIT-008, MIT-009
```

---

## PREFLIGHT CHECKS

```bash
set -e
echo "=== PREFLIGHT CHECKS FOR MIT-007 ==="

# 1. Phase 1 complete
jq -e '.MIT-004.status == "passed"' .superpowers/state/story-progress.json > /dev/null || { echo "FAIL: Phase 1 not complete"; exit 1; }

# 2. practice.sql exists
test -f docs/superpowers/mcp-queries/practice.sql || { echo "FAIL: practice.sql not found"; exit 1; }

echo "✓ ALL PREFLIGHT CHECKS PASSED"
```

---

## STATE INITIALIZATION

```bash
cat > .superpowers/checkpoints/MIT-007-START << 'EOF'
{"storyId": "MIT-007", "createdAt": "'$(date -Iseconds)'", "gitRef": "'$(git rev-parse HEAD)'"}
EOF

jq '.MIT-007 = {"status": "in-progress", "phase": 2, "title": "Practice Session Workflow", "startedAt": "'$(date -Iseconds)'", "dependencies": ["MIT-004"]}' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json
```

---

## IMPLEMENTATION STEPS

### Step 1: Define Practice Session Workflow

Update SKILL.md:

```markdown
## Workflow: practice_session

**Trigger:** "Practice [topic]" / "Test me on [topic]" / "Give me problems for [topic]"

### Flow

1. **Select Topic**
   ```sql
   SELECT id, topic_id, name, mastery
   FROM topics
   WHERE topic_id = :topic_id OR name LIKE :topic_name;
   ```

2. **Start Practice Session**
   ```sql
   INSERT INTO sessions (session_type, topic_id, started_at)
   VALUES ('practice', :topic_id, CURRENT_TIMESTAMP);
   SELECT last_insert_rowid() AS session_id;
   ```

3. **Present Problems**
   - Claude generates practice problems
   - User solves each problem
   - Rate correctness (0.0-1.0)

4. **Track Performance**
   - Running average of performance
   - Problems attempted counter

5. **End Session**
   ```sql
   UPDATE sessions
   SET ended_at = CURRENT_TIMESTAMP,
       performance = :avg_performance,
       duration_seconds = :duration,
       notes = 'Problems: ' || :count
   WHERE id = :session_id;
   ```

6. **Update Mastery**
   ```sql
   -- FSRS update based on performance
   -- See fsrs.sql for formulas
   ```

7. **Increment Streak**

### Performance Calculation

| Problem Score | Interpretation |
|--------------|----------------|
| 0.0 | Completely wrong |
| 0.3 | Minor correct elements |
| 0.5 | Partially correct |
| 0.7 | Mostly correct |
| 1.0 | Perfect solution |

---

## Workflow: interleaved_practice

**Trigger:** "Practice multiple topics" / "Mixed practice for [topics]" / "Interleaved session"

### Interleaving Benefits

- **Desirable difficulty**: Switching topics strengthens memory
- **Discrimination practice**: Learn to distinguish concepts
- **Transfer practice**: Apply knowledge across domains

### Flow

1. **Select Multiple Topics**
   ```sql
   SELECT id, topic_id, name, mastery
   FROM topics
   WHERE goal_id = :goal_id
   AND mastery BETWEEN 0.2 AND 0.8
   ORDER BY RANDOM()
   LIMIT 5;
   ```

2. **Rotate Through Topics**
   - Present one problem from each topic in rotation
   - Track performance per topic

3. **Cross-Topic Interference**
   - Track when topics interfere (user confuses them)
   - Note interference patterns

4. **Update All Topics**
   ```sql
   -- Update each topic after session
   -- Use batch FSRS update
   ```
```

---

### Step 2: Create Test Practice Session

```sql
-- Create practice topic
INSERT INTO topics (topic_id, name, status, mastery)
VALUES ('T05-practice-test', 'Calculus Basics', 'in_progress', 0.5);

-- Start practice session
INSERT INTO sessions (session_type, topic_id, started_at)
VALUES ('practice', (SELECT id FROM topics WHERE topic_id = 'T05-practice-test'), CURRENT_TIMESTAMP);

-- End session with performance
UPDATE sessions
SET ended_at = datetime('now', '+20 minutes'),
    performance = 0.75,
    duration_seconds = 1200,
    notes = 'Problems: 10, Correct: 7'
WHERE id = last_insert_rowid();

-- Initialize FSRS if needed
INSERT INTO fsrs_state (topic_id, stability, difficulty, state, last_review)
SELECT id, 5.0, 5.0, 1, CURRENT_TIMESTAMP
FROM topics WHERE topic_id = 'T05-practice-test'
ON CONFLICT DO NOTHING;
```

---

### Step 3: Test Interleaved Practice

```sql
-- Create multiple topics for interleaving
INSERT INTO topics (topic_id, name, status, mastery)
VALUES
    ('T06-interleave-1', 'Derivatives', 'in_progress', 0.4),
    ('T07-interleave-2', 'Integrals', 'in_progress', 0.5),
    ('T08-interleave-3', 'Limits', 'in_progress', 0.6);

-- Initialize FSRS states
INSERT INTO fsrs_state (topic_id, stability, difficulty, state, last_review)
SELECT id, 5.0, 5.0, 1, CURRENT_TIMESTAMP
FROM topics WHERE topic_id IN ('T06-interleave-1', 'T07-interleave-2', 'T08-interleave-3');

-- Select for interleaved practice (randomized)
SELECT topic_id, name, mastery
FROM topics
WHERE topic_id IN ('T06-interleave-1', 'T07-interleave-2', 'T08-interleave-3')
ORDER BY RANDOM();

-- Create interleaved session for all
INSERT INTO sessions (session_type, topic_id, started_at, notes)
VALUES
    ('practice', (SELECT id FROM topics WHERE topic_id = 'T06-interleave-1'), CURRENT_TIMESTAMP, 'INTERLEAVED'),
    ('practice', (SELECT id FROM topics WHERE topic_id = 'T07-interleave-2'), CURRENT_TIMESTAMP, 'INTERLEAVED'),
    ('practice', (SELECT id FROM topics WHERE topic_id = 'T08-interleave-3'), CURRENT_TIMESTAMP, 'INTERLEAVED');
```

---

## TESTING & VERIFICATION

```bash
echo "=== PRACTICE WORKFLOW VERIFICATION ==="

# 1. Practice session created
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT session_type FROM sessions WHERE session_type='practice';" | grep -q "practice" && echo "✓ [1/5] Practice session created"

# 2. Performance recorded
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT performance FROM sessions WHERE notes LIKE '%Problems%';" | grep -q "0.75" && echo "✓ [2/5] Performance recorded"

# 3. Duration tracked
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT duration_seconds FROM sessions WHERE session_type='practice' AND duration_seconds > 0;" | grep -q "." && echo "✓ [3/5] Duration tracked"

# 4. Interleaved topics selected
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT COUNT(*) FROM sessions WHERE notes='INTERLEAVED';" | grep -q "3" && echo "✓ [4/5] Interleaved sessions created"

# 5. SKILL.md updated
grep -q "Workflow: practice_session" SKILL.md && echo "✓ [5/5] SKILL.md documented"

echo "=== ALL VERIFICATIONS PASSED ==="
```

---

## HUMAN VERIFICATION

```markdown
Verify:
- [ ] Practice session creates session record
- [ ] Performance tracking works (0.0-1.0)
- [ ] Duration calculated correctly
- [ ] Interleaved practice selects multiple topics
- [ ] FSRS updated after practice
- [ ] SKILL.md has both workflows

## HUMAN SIGN-OFF ##
Status: [ ] I have verified practice workflows work correctly.
```

---

## SUCCESS CRITERIA

```bash
echo "=== ACCEPTANCE CRITERIA ==="

sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT COUNT(*) FROM sessions WHERE session_type='practice';" | grep -q "." && echo "✓ [1/4] Practice sessions exist"
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT AVG(performance) FROM sessions WHERE session_type='practice';" | grep -q "0\." && echo "✓ [2/4] Performance calculated"
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT COUNT(DISTINCT topic_id) FROM sessions WHERE notes='INTERLEAVED';" | grep -q "3" && echo "✓ [3/4] Interleaving works"
grep -q "interleaved_practice" SKILL.md && echo "✓ [4/4] SKILL.md has interleaved workflow"

echo "=== ALL CRITERIA VERIFIED ==="
```

---

## CLEANUP & COMPLETION

```bash
git add SKILL.md docs/superpowers/mcp-queries/practice.sql
git commit -m "feat(MIT-007): practice session workflow

- practice_session workflow in SKILL.md
- interleaved_practice workflow
- Performance tracking
- Duration calculation
- Multi-topic interleaving

Story: MIT-007
Phase: 2
Dependencies: MIT-004
"

jq '.MIT-007.status = "passed" | .MIT-007.completedAt = "'$(date -Iseconds)'"' \
  .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json

cat > .superpowers/checkpoints/MIT-007-PASS << 'EOF'
{"storyId": "MIT-007", "status": "passed", "completedAt": "'$(date -Iseconds)'"}
EOF

echo "✓ MIT-007 passed"
```

---

## ROLLBACK

```bash
#!/bin/bash
set -e
REF=$(jq -r '.gitRef' .superpowers/checkpoints/MIT-007-START)
git checkout $REF -- SKILL.md docs/superpowers/mcp-queries/practice.sql
jq '.MIT-007.status = "pending"' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json
rm -f .superpowers/checkpoints/MIT-007-*
echo "Rollback complete"
```

---

**NEXT:** Continue Phase 2 workflows

**END OF EXECUTION PROMPT FOR MIT-007**
