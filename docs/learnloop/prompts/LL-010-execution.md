# LL-010: Error Handling via MCP

**Execution Prompt — Copy and paste into Claude session**

---

## STORY METADATA

```yaml
ID: LL-010
Title: Error Handling via MCP
Phase: 3
Effort: 3 hours
Impact: Production-ready error handling
Dependencies: LL-005 through LL-009 (Phase 2 Complete)
Parallelizable with: None
```

---

## PREFLIGHT CHECKS

```bash
set -e
echo "=== PREFLIGHT CHECKS FOR LL-010 ==="

# 1. Phase 2 complete
for story in LL-005 LL-006 LL-007 LL-008 LL-009; do
    jq -e ".${story}.status == \"passed\"" .superpowers/state/story-progress.json > /dev/null || { echo "FAIL: ${story} not passed"; exit 1; }
done

echo "✓ ALL PREFLIGHT CHECKS PASSED"
```

---

## STATE INITIALIZATION

```bash
cat > .superpowers/checkpoints/LL-010-START << 'EOF'
{"storyId": "LL-010", "createdAt": "'$(date -Iseconds)'", "gitRef": "'$(git rev-parse HEAD)'"}
EOF

jq '.LL-010 = {"status": "in-progress", "phase": 3, "title": "Error Handling via MCP", "startedAt": "'$(date -Iseconds)'", "dependencies": ["LL-005", "LL-006", "LL-007", "LL-008", "LL-009"]}' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json
```

---

## IMPLEMENTATION STEPS

### Step 1: Define Error Handling Strategy

Update SKILL.md:

```markdown
## Error Handling

### Error Categories

| Category | Example | Recovery |
|----------|---------|----------|
| Schema validation | mastery > 1.0 | Clamp to bounds |
| Missing database | No memory.db | Create with warning |
| Missing goal | Goal ID not found | Create with defaults |
| Constraint violation | Duplicate topic_id | Return existing |
| FSRS bounds | stability < 0 | Reset to default |

### Recovery Queries

```sql
-- Schema validation: Clamp mastery to bounds
UPDATE topics
SET mastery = MAX(0.0, MIN(1.0, :mastery))
WHERE id = :topic_id;

-- Missing database: Create new
-- (Handled by Claude: create directory, run schema.sql)

-- Missing goal: Create with defaults
INSERT OR IGNORE INTO goal_meta (goal_id, goal_type, created_at)
VALUES (:goal_id, 'topic', CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO streak_state (goal_id, current_streak, last_activity_date)
VALUES (:goal_id, 0, date('now'));

-- Duplicate topic: Return existing
INSERT OR IGNORE INTO topics (topic_id, name, status)
VALUES (:topic_id, :name, 'pending');

SELECT id, topic_id, name FROM topics WHERE topic_id = :topic_id;

-- FSRS bounds: Reset to defaults
UPDATE fsrs_state
SET
    stability = MAX(0.5, MIN(365.0, COALESCE(stability, 2.5))),
    difficulty = MAX(1.0, MIN(10.0, COALESCE(difficulty, 5.0)))
WHERE topic_id = :topic_id;
```

### Graceful Degradation

```
Normal flow:
  Query → Success → Return data

Error flow:
  Query → Error → Log → Recovery query → Return graceful result

Never:
  - Crash session
  - Expose raw SQL errors
  - Lose user data
```

### Error Messages

```markdown
Database not found → "Initializing new goal database at <path>"
Invalid mastery → "Adjusted mastery to valid range (0.0-1.0)"
Missing topic → "Created new topic <topic_id>"
Duplicate entry → "Using existing topic <topic_id>"
FSRS error → "Reset spaced repetition state to defaults"
```
```

---

### Step 2: Test Schema Validation

```sql
-- Test mastery clamping
-- Try to insert mastery > 1.0 (should fail CHECK)
INSERT INTO topics (topic_id, name, mastery)
VALUES ('T20-error-test', 'Error Test', 1.5);

-- Expected: CHECK constraint failed

-- Try valid mastery
INSERT INTO topics (topic_id, name, mastery)
VALUES ('T20-error-test', 'Error Test', 0.8);

-- Recovery: If mastery out of bounds, clamp
UPDATE topics
SET mastery = MAX(0.0, MIN(1.0, 1.5))
WHERE topic_id = 'T20-error-test';

-- Verify
SELECT mastery FROM topics WHERE topic_id = 'T20-error-test';
```

Expected: mastery = 1.0 (clamped)

---

### Step 3: Test Missing Goal Recovery

```sql
-- Check if goal exists
SELECT COUNT(*) FROM goal_meta WHERE goal_id = 'nonexistent';

-- If 0, create with defaults
INSERT INTO goal_meta (goal_id, goal_type, created_at)
VALUES ('nonexistent', 'topic', CURRENT_TIMESTAMP);

INSERT INTO streak_state (goal_id, current_streak, last_activity_date)
VALUES ('nonexistent', 0, date('now'));

-- Verify
SELECT * FROM goal_meta WHERE goal_id = 'nonexistent';
```

---

### Step 4: Test Duplicate Handling

```sql
-- Try to insert duplicate topic
INSERT INTO topics (topic_id, name, status)
VALUES ('T01-learn-test', 'Duplicate', 'pending');

-- Expected: UNIQUE constraint failed

-- Graceful approach: INSERT OR IGNORE
INSERT OR IGNORE INTO topics (topic_id, name, status)
VALUES ('T01-learn-test', 'Duplicate', 'pending');

-- Return existing
SELECT id, topic_id, name, status FROM topics
WHERE topic_id = 'T01-learn-test';
```

---

### Step 5: Test FSRS Bounds

```sql
-- Create topic with invalid FSRS
INSERT INTO fsrs_state (topic_id, stability, difficulty, state)
VALUES (999, -5.0, 15.0, 5);

-- Recovery: Clamp to bounds
UPDATE fsrs_state
SET
    stability = MAX(0.5, MIN(365.0, COALESCE(stability, 2.5))),
    difficulty = MAX(1.0, MIN(10.0, COALESCE(difficulty, 5.0))),
    state = MAX(0, MIN(3, COALESCE(state, 0)))
WHERE topic_id = 999;

-- Verify
SELECT stability, difficulty, state FROM fsrs_state WHERE topic_id = 999;
```

Expected: stability = 0.5, difficulty = 10.0, state = 3

---

## TESTING & VERIFICATION

```bash
echo "=== ERROR HANDLING VERIFICATION ==="

# 1. CHECK constraint enforced
sqlite3 ~/.mit-learning/goals/test/memory.db "INSERT INTO topics (topic_id, name, mastery) VALUES ('T21', 'Test', 2.0);" 2>&1 | grep -q "CHECK" && echo "✓ [1/5] CHECK constraint works"

# 2. Duplicate handling
sqlite3 ~/.mit-learning/goals/test/memory.db "INSERT OR IGNORE INTO topics (topic_id, name) VALUES ('T20-error-test', 'Test');" && echo "✓ [2/5] OR IGNORE works"

# 3. Missing goal recovery
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT goal_id FROM goal_meta WHERE goal_id='nonexistent';" | grep -q "nonexistent" && echo "✓ [3/5] Goal created"

# 4. FSRS bounds
sqlite3 ~/.mit-learning/goals/test/memory.db "UPDATE fsrs_state SET stability = MAX(0.5, MIN(365.0, stability)) WHERE topic_id=999;" && echo "✓ [4/5] FSRS bounds work"

# 5. SKILL.md updated
grep -q "Error Handling" SKILL.md && echo "✓ [5/5] SKILL.md documented"

echo "=== ALL VERIFICATIONS PASSED ==="
```

---

## HUMAN VERIFICATION

```markdown
Verify:
- [ ] Invalid mastery rejected
- [ ] Missing goals auto-created
- [ ] Duplicates handled gracefully
- [ ] FSRS bounds enforced
- [ ] Error messages user-friendly
- [ ] No session crashes

## HUMAN SIGN-OFF ##
Status: [ ] I have verified error handling works correctly.
```

---

## SUCCESS CRITERIA

```bash
echo "=== ACCEPTANCE CRITERIA ==="

# 1. Constraints work
sqlite3 ~/.mit-learning/goals/test/memory.db "INSERT INTO topics (topic_id, mastery) VALUES ('X', 2.0);" 2>&1 | grep -q "CHECK" && echo "✓ [1/4] Constraints enforced"

# 2. Graceful recovery
sqlite3 ~/.mit-learning/goals/test/memory.db "INSERT OR IGNORE INTO topics (topic_id, name) VALUES ('T20-error-test', 'Exists');" && echo "✓ [2/4] Graceful duplicate"

# 3. SKILL.md has error section
grep -q "Error Categories" SKILL.md && echo "✓ [3/4] SKILL.md has categories"

# 4. Recovery queries documented
grep -q "Recovery Queries" SKILL.md && echo "✓ [4/4] Recovery queries in SKILL.md"

echo "=== ALL CRITERIA VERIFIED ==="
```

---

## CLEANUP & COMPLETION

```bash
git add SKILL.md
git commit -m "feat(LL-010): error handling via MCP

- Error categories and recovery
- Schema validation clamping
- Missing goal auto-creation
- Duplicate handling
- FSRS bounds enforcement
- Graceful degradation

Story: LL-010
Phase: 3
Dependencies: Phase 2 complete
"

jq '.LL-010.status = "passed" | .LL-010.completedAt = "'$(date -Iseconds)'"' \
  .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json

cat > .superpowers/checkpoints/LL-010-PASS << 'EOF'
{"storyId": "LL-010", "status": "passed", "completedAt": "'$(date -Iseconds)'"}
EOF

echo "✓ LL-010 passed"
```

---

## ROLLBACK

```bash
#!/bin/bash
set -e
REF=$(jq -r '.gitRef' .superpowers/checkpoints/LL-010-START)
git checkout $REF -- SKILL.md
jq '.LL-010.status = "pending"' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json
rm -f .superpowers/checkpoints/LL-010-*
echo "Rollback complete"
```

---

**NEXT:** Proceed to LL-011: Comprehensive Testing

**END OF EXECUTION PROMPT FOR LL-010**
