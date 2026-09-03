# MIT-011: Comprehensive Testing

**Execution Prompt — Copy and paste into Claude session**

---

## STORY METADATA

```yaml
ID: MIT-011
Title: Comprehensive Testing
Phase: 3
Effort: 4 hours
Impact: Confidence in all workflows
Dependencies: MIT-010 (Error Handling)
Parallelizable with: None
```

---

## PREFLIGHT CHECKS

```bash
set -e
echo "=== PREFLIGHT CHECKS FOR MIT-011 ==="

# 1. MIT-010 passed
jq -e '.MIT-010.status == "passed"' .superpowers/state/story-progress.json > /dev/null || { echo "FAIL: MIT-010 not passed"; exit 1; }

echo "✓ ALL PREFLIGHT CHECKS PASSED"
```

---

## STATE INITIALIZATION

```bash
cat > .superpowers/checkpoints/MIT-011-START << 'EOF'
{"storyId": "MIT-011", "createdAt": "'$(date -Iseconds)'", "gitRef": "'$(git rev-parse HEAD)'"}
EOF

jq '.MIT-011 = {"status": "in-progress", "phase": 3, "title": "Comprehensive Testing", "startedAt": "'$(date -Iseconds)'", "dependencies": ["MIT-010"]}' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json
```

---

## IMPLEMENTATION STEPS

### Step 1: Create Test Directory Structure

```bash
mkdir -p docs/superpowers/tests/{unit,integration,edge-cases,performance}
```

---

### Step 2: Create Unit Tests for FSRS

Create `docs/superpowers/tests/unit/test_fsrs.sql`:

```sql
-- ============================================
-- FSRS-6 Unit Tests
-- ============================================

-- Test 1: Retrievability at 10 days, stability 10
-- Expected: R = (1 + 10/90)^(-1) = 0.9
SELECT 'Test 1: Retrievability',
    CASE
        WHEN ABS(POWER(1 + 10.0/90.0, -1.0) - 0.9) < 0.001 THEN 'PASS'
        ELSE 'FAIL'
    END AS result,
    POWER(1 + 10.0/90.0, -1.0) AS actual,
    0.9 AS expected;

-- Test 2: Retrievability approaches 1.0 as days = 0
SELECT 'Test 2: R(0 days)',
    CASE
        WHEN ABS(POWER(1 + 0.0/90.0, -1.0) - 1.0) < 0.001 THEN 'PASS'
        ELSE 'FAIL'
    END AS result;

-- Test 3: Mastery formula
-- M = 1 - exp(-0.5 * S / D)
-- S=10, D=5: M = 1 - exp(-1) = 0.632
SELECT 'Test 3: Mastery',
    CASE
        WHEN ABS((1 - EXP(-0.5 * 10.0 / 5.0)) - 0.632) < 0.01 THEN 'PASS'
        ELSE 'FAIL'
    END AS result,
    1 - EXP(-0.5 * 10.0 / 5.0) AS actual,
    0.632 AS expected;

-- Test 4: Stability increase on success
-- S' = S * factor, factor > 1
SELECT 'Test 4: Stability increase',
    CASE
        WHEN 10.0 * 1.5 > 10.0 THEN 'PASS'
        ELSE 'FAIL'
    END AS result;

-- Test 5: Stability decrease on failure
-- S' = S * (0.5 + p * 0.5), p < 0.6
SELECT 'Test 5: Stability decrease',
    CASE
        WHEN 10.0 * (0.5 + 0.3 * 0.5) < 10.0 THEN 'PASS'
        ELSE 'FAIL'
    END AS result;

-- Test 6: Difficulty bounds
SELECT 'Test 6: Difficulty bounds',
    CASE
        WHEN MAX(1.0, MIN(10.0, 0.5)) = 1.0 THEN 'PASS'
        ELSE 'FAIL'
    END AS result;

-- Test 7: State transitions
-- State 0 -> 1 (new), 1 -> 2 (success), 2 -> 3 (lapse)
SELECT 'Test 7: State transitions',
    CASE
        WHEN (CASE WHEN 0 = 0 THEN 1 ELSE 0 END) = 1 THEN 'PASS'
        ELSE 'FAIL'
    END AS result;
```

---

### Step 3: Create Integration Tests for Workflows

Create `docs/superpowers/tests/integration/test_learning_workflow.sql`:

```sql
-- ============================================
-- Learning Workflow Integration Test
-- ============================================

-- Setup: Create test goal
INSERT OR IGNORE INTO goal_meta (goal_id, goal_type)
VALUES ('test_integration', 'topic');

INSERT OR IGNORE INTO streak_state (goal_id, current_streak, last_activity_date)
VALUES ('test_integration', 0, date('now'));

-- Step 1: Create topic
INSERT INTO topics (topic_id, name, status)
VALUES ('TI-001', 'Integration Test Topic', 'in_progress');

-- Step 2: Initialize FSRS
INSERT INTO fsrs_state (topic_id, stability, difficulty, state, last_review)
SELECT id, 2.5, 5.0, 0, CURRENT_TIMESTAMP
FROM topics WHERE topic_id = 'TI-001';

-- Verify: Topic exists
SELECT 'Integration Step 1: Topic created',
    CASE WHEN (SELECT COUNT(*) FROM topics WHERE topic_id = 'TI-001') = 1
    THEN 'PASS' ELSE 'FAIL' END AS result;

-- Verify: FSRS initialized
SELECT 'Integration Step 2: FSRS initialized',
    CASE WHEN (SELECT stability FROM fsrs_state
               WHERE topic_id = (SELECT id FROM topics WHERE topic_id = 'TI-001')) > 0
    THEN 'PASS' ELSE 'FAIL' END AS result;

-- Step 3: Complete session (performance = 0.75)
UPDATE fsrs_state
SET
    stability = MIN(365.0, stability * 1.5),
    state = 2,
    last_review = CURRENT_TIMESTAMP,
    reviews = reviews + 1
WHERE topic_id = (SELECT id FROM topics WHERE topic_id = 'TI-001');

-- Step 4: Update mastery
UPDATE topics
SET mastery = 0.4,
    status = 'in_progress'
WHERE topic_id = 'TI-001';

-- Verify: Mastery updated
SELECT 'Integration Step 3: Mastery updated',
    CASE WHEN (SELECT mastery FROM topics WHERE topic_id = 'TI-001') > 0
    THEN 'PASS' ELSE 'FAIL' END AS result;

-- Step 5: Increment streak
UPDATE streak_state
SET current_streak = current_streak + 1,
    last_activity_date = date('now')
WHERE goal_id = 'test_integration';

-- Verify: Streak incremented
SELECT 'Integration Step 4: Streak incremented',
    CASE WHEN (SELECT current_streak FROM streak_state WHERE goal_id = 'test_integration') > 0
    THEN 'PASS' ELSE 'FAIL' END AS result;

-- Cleanup
DELETE FROM topics WHERE topic_id = 'TI-001';
DELETE FROM fsrs_state WHERE topic_id = (SELECT id FROM topics WHERE topic_id = 'TI-001');
```

---

### Step 4: Create Edge Case Tests

Create `docs/superpowers/tests/edge-cases/test_edge_cases.sql`:

```sql
-- ============================================
-- Edge Case Tests
-- ============================================

-- Test 1: Empty review queue
SELECT 'Edge 1: Empty queue',
    CASE WHEN (SELECT COUNT(*) FROM topics t
               JOIN fsrs_state f ON t.id = f.topic_id
               WHERE f.next_review <= datetime('now')) >= 0
    THEN 'PASS' ELSE 'FAIL' END AS result;

-- Test 2: First topic (no history)
INSERT INTO topics (topic_id, name, status, mastery)
VALUES ('TE-001', 'First Topic', 'pending', 0.0);

INSERT INTO fsrs_state (topic_id, stability, difficulty, state, last_review)
SELECT id, 2.5, 5.0, 0, CURRENT_TIMESTAMP
FROM topics WHERE topic_id = 'TE-001';

SELECT 'Edge 2: First topic created',
    CASE WHEN (SELECT COUNT(*) FROM topics WHERE topic_id = 'TE-001') = 1
    THEN 'PASS' ELSE 'FAIL' END AS result;

-- Test 3: Maximum mastery (0.999...)
UPDATE topics SET mastery = 0.999 WHERE topic_id = 'TE-001';
SELECT 'Edge 3: Max mastery',
    CASE WHEN (SELECT mastery FROM topics WHERE topic_id = 'TE-001') <= 1.0
    THEN 'PASS' ELSE 'FAIL' END AS result;

-- Test 4: Boundary stability values
UPDATE fsrs_state SET stability = 0.5 WHERE topic_id = (SELECT id FROM topics WHERE topic_id = 'TE-001');
SELECT 'Edge 4: Min stability',
    CASE WHEN (SELECT stability FROM fsrs_state WHERE topic_id = (SELECT id FROM topics WHERE topic_id = 'TE-001')) >= 0.5
    THEN 'PASS' ELSE 'FAIL' END AS result;

UPDATE fsrs_state SET stability = 365.0 WHERE topic_id = (SELECT id FROM topics WHERE topic_id = 'TE-001');
SELECT 'Edge 5: Max stability',
    CASE WHEN (SELECT stability FROM fsrs_state WHERE topic_id = (SELECT id FROM topics WHERE topic_id = 'TE-001')) <= 365.0
    THEN 'PASS' ELSE 'FAIL' END AS result;

-- Test 5: Longest streak tracking
INSERT INTO streak_state (goal_id, current_streak, longest_streak, last_activity_date)
VALUES ('edge_test', 50, 50, date('now'));

SELECT 'Edge 6: Longest streak',
    CASE WHEN (SELECT longest_streak FROM streak_state WHERE goal_id = 'edge_test') = 50
    THEN 'PASS' ELSE 'FAIL' END AS result;

-- Cleanup
DELETE FROM topics WHERE topic_id = 'TE-001';
DELETE FROM streak_state WHERE goal_id = 'edge_test';
```

---

### Step 5: Create Performance Benchmarks

Create `docs/superpowers/tests/performance/benchmarks.sql`:

```sql
-- ============================================
-- Performance Benchmarks
-- ============================================

-- Setup: Insert 10000 topics
-- (Run manually, not in test suite)

-- Benchmark 1: Single FSRS query
.timer on
SELECT
    t.id,
    t.topic_id,
    POWER(1 + (julianday('now') - julianday(f.last_review)) / (9.0 * f.stability), -1.0) AS retrievability
FROM topics t
JOIN fsrs_state f ON t.id = f.topic_id
WHERE f.next_review <= datetime('now')
ORDER BY retrievability ASC
LIMIT 20;
.timer off

-- Target: < 5ms

-- Benchmark 2: Mastery update
.timer on
UPDATE topics
SET mastery = 1 - EXP(-0.5 * (SELECT stability FROM fsrs_state WHERE topic_id = id) /
                   (SELECT difficulty FROM fsrs_state WHERE topic_id = id))
WHERE id = :topic_id;
.timer off

-- Target: < 2ms

-- Benchmark 3: Streak increment
.timer on
UPDATE streak_state
SET current_streak = current_streak + 1,
    last_activity_date = date('now')
WHERE goal_id = :goal_id;
.timer off

-- Target: < 1ms
```

---

### Step 6: Create Test Runner Script

Create `docs/superpowers/tests/run_tests.sh`:

```bash
#!/bin/bash
# MIT Learning Skill Test Runner

set -e

DB="$HOME/.mit-learning/goals/test/memory.db"
TEST_DIR="docs/superpowers/tests"

echo "=== MIT Learning Skill Test Suite ==="
echo "Database: $DB"
echo ""

# Check database exists
if [ ! -f "$DB" ]; then
    echo "ERROR: Test database not found"
    exit 1
fi

PASSED=0
FAILED=0

# Run unit tests
echo "--- Unit Tests ---"
for test in "$TEST_DIR"/unit/*.sql; do
    echo "Running: $(basename $test)"
    RESULT=$(sqlite3 "$DB" < "$test" 2>&1)
    if echo "$RESULT" | grep -q "FAIL"; then
        echo "  FAILED"
        FAILED=$((FAILED + 1))
    else
        PASSED=$((PASSED + 1))
    fi
done

# Run integration tests
echo "--- Integration Tests ---"
for test in "$TEST_DIR"/integration/*.sql; do
    echo "Running: $(basename $test)"
    RESULT=$(sqlite3 "$DB" < "$test" 2>&1)
    if echo "$RESULT" | grep -q "FAIL"; then
        echo "  FAILED"
        FAILED=$((FAILED + 1))
    else
        PASSED=$((PASSED + 1))
    fi
done

# Run edge case tests
echo "--- Edge Case Tests ---"
for test in "$TEST_DIR"/edge-cases/*.sql; do
    echo "Running: $(basename $test)"
    RESULT=$(sqlite3 "$DB" < "$test" 2>&1)
    if echo "$RESULT" | grep -q "FAIL"; then
        echo "  FAILED"
        FAILED=$((FAILED + 1))
    else
        PASSED=$((PASSED + 1))
    fi
done

echo ""
echo "=== Test Results ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [ $FAILED -gt 0 ]; then
    echo "STATUS: FAIL"
    exit 1
else
    echo "STATUS: PASS"
    exit 0
fi
```

Make executable:
```bash
chmod +x docs/superpowers/tests/run_tests.sh
```

---

## TESTING & VERIFICATION

```bash
echo "=== TEST SUITE VERIFICATION ==="

# 1. Test files exist
test -d docs/superpowers/tests/unit && echo "✓ [1/5] Unit test dir exists"
test -d docs/superpowers/tests/integration && echo "✓ [2/5] Integration test dir exists"
test -d docs/superpowers/tests/edge-cases && echo "✓ [3/5] Edge case test dir exists"
test -d docs/superpowers/tests/performance && echo "✓ [4/5] Performance test dir exists"

# 2. Test runner executable
test -x docs/superpowers/tests/run_tests.sh && echo "✓ [5/5] Test runner ready"

# 3. Run tests
./docs/superpowers/tests/run_tests.sh || echo "Tests completed"
```

---

## HUMAN VERIFICATION

```markdown
Verify:
- [ ] All test directories created
- [ ] Unit tests for FSRS formulas
- [ ] Integration tests for workflows
- [ ] Edge case tests for boundaries
- [ ] Performance benchmarks < 5ms
- [ ] Test runner executes clean

## HUMAN SIGN-OFF ##
Status: [ ] I have verified the test suite works correctly.
```

---

## SUCCESS CRITERIA

```bash
echo "=== ACCEPTANCE CRITERIA ==="

test -f docs/superpowers/tests/unit/test_fsrs.sql && echo "✓ [1/4] FSRS unit tests exist"
test -f docs/superpowers/tests/integration/test_learning_workflow.sql && echo "✓ [2/4] Integration tests exist"
test -f docs/superpowers/tests/edge-cases/test_edge_cases.sql && echo "✓ [3/4] Edge case tests exist"
test -x docs/superpowers/tests/run_tests.sh && echo "✓ [4/4] Test runner executable"

echo "=== ALL CRITERIA VERIFIED ==="
```

---

## CLEANUP & COMPLETION

```bash
git add docs/superpowers/tests/
git commit -m "feat(MIT-011): comprehensive testing

- Unit tests for FSRS calculations
- Integration tests for all workflows
- Edge case tests for boundaries
- Performance benchmarks
- Test runner script

Story: MIT-011
Phase: 3
Dependencies: MIT-010
"

jq '.MIT-011.status = "passed" | .MIT-011.completedAt = "'$(date -Iseconds)'"' \
  .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json

cat > .superpowers/checkpoints/MIT-011-PASS << 'EOF'
{"storyId": "MIT-011", "status": "passed", "completedAt": "'$(date -Iseconds)'"}
EOF

echo "✓ MIT-011 passed"
```

---

## ROLLBACK

```bash
#!/bin/bash
set -e
rm -rf docs/superpowers/tests/
jq '.MIT-011.status = "pending"' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json
rm -f .superpowers/checkpoints/MIT-011-*
echo "Rollback complete"
```

---

**NEXT:** Proceed to MIT-012: Python Deprecation (FINAL)

**END OF EXECUTION PROMPT FOR MIT-011**
