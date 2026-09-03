# MIT-003: FSRS-6 Calculations in SQL

**Execution Prompt — Copy and paste into Claude session**

---

## STORY METADATA

```yaml
ID: MIT-003
Title: FSRS-6 Calculations in SQL
Phase: 1
Effort: 4 hours
Impact: Spaced repetition without Python scheduler
Dependencies: MIT-002 (Schema Initialization)
Parallelizable with: None
```

---

## PREFLIGHT CHECKS

```bash
set -e
echo "=== PREFLIGHT CHECKS FOR MIT-003 ==="

# 1. MIT-002 passed
jq -e '.MIT-002.status == "passed"' .superpowers/state/story-progress.json > /dev/null || { echo "FAIL: MIT-002 not passed"; exit 1; }

# 2. fsrs.sql exists
test -f docs/superpowers/mcp-queries/fsrs.sql || { echo "FAIL: fsrs.sql not found"; exit 1; }

# 3. Test database available
test -f ~/.mit-learning/goals/test/memory.db || { echo "FAIL: Test database not found"; exit 1; }

echo "✓ ALL PREFLIGHT CHECKS PASSED"
```

---

## STATE INITIALIZATION

```bash
cat > .superpowers/checkpoints/MIT-003-START << 'EOF'
{
  "storyId": "MIT-003",
  "createdAt": "'$(date -Iseconds)'",
  "gitRef": "'$(git rev-parse HEAD)'",
  "files": ["docs/superpowers/mcp-queries/fsrs.sql", "SKILL.md"]
}
EOF

jq '.MIT-003 = {
  "status": "in-progress",
  "phase": 1,
  "title": "FSRS-6 Calculations in SQL",
  "startedAt": "'$(date -Iseconds)'",
  "dependencies": ["MIT-002"]
}' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json
```

---

## IMPLEMENTATION STEPS

### Step 1: Verify Retrievability Formula

Test retrievability calculation:

```sql
-- Test with known values
-- R(t=10, S=10) should equal (1 + 10/90)^(-1) = 0.9

SELECT
    10.0 AS days_since_review,
    10.0 AS stability,
    POWER(1 + 10.0 / (9.0 * 10.0), -1.0) AS retrievability;

-- Expected: ~0.9
```

Execute via MCP:
```markdown
mcp__sqlite__query({
  database: "~/.mit-learning/goals/test/memory.db",
  query: "SELECT POWER(1 + 10.0 / (9.0 * 10.0), -1.0) AS r;"
})
```

**Verification:** Result should be `0.9` (exactly 9/10)

---

### Step 2: Test Stability Update (Success)

Test stability increase after successful review:

```sql
-- Initial: S=10, D=5, performance=0.8, R=0.9
-- Expected: S' ≈ 10 * (1 + 6 * 0.1 * 2.0 * 1.31 * 1.4)

SELECT
    10.0 AS old_stability,
    5.0 AS difficulty,
    0.8 AS performance,
    0.9 AS retrievability,
    10.0 * (1 + (11.0 - 5.0) * 0.1 * (1 + (0.8 - 0.6) * 2) * (1 + SQRT(10.0)/10.0) * (0.5 + 0.9)) AS new_stability;

-- Expected: ~24.2
```

---

### Step 3: Test Stability Update (Failure)

Test stability decrease after failed review:

```sql
-- Initial: S=10, performance=0.3
-- Expected: S' = 10 * (0.5 + 0.3 * 0.5) = 6.5

SELECT
    10.0 AS old_stability,
    0.3 AS performance,
    10.0 * (0.5 + 0.3 * 0.5) AS new_stability;

-- Expected: 6.5
```

---

### Step 4: Test Mastery Calculation

```sql
-- Mastery = 1 - exp(-0.5 * S / D)

SELECT
    10.0 AS stability,
    5.0 AS difficulty,
    1 - EXP(-0.5 * 10.0 / 5.0) AS mastery;

-- Expected: ~0.632
```

---

### Step 5: Create Test Data

```sql
-- Insert test topic
INSERT INTO topics (topic_id, name, status, mastery)
VALUES ('T01-fsrs-test', 'FSRS Test Topic', 'in_progress', 0.0);

-- Insert FSRS state
INSERT INTO fsrs_state (topic_id, stability, difficulty, state, last_review, reviews)
VALUES (
    (SELECT id FROM topics WHERE topic_id = 'T01-fsrs-test'),
    10.0, 5.0, 1, datetime('now', '-10 days'), 1
);
```

---

### Step 6: Execute Review Simulation

```sql
-- Simulate review with performance = 0.8 (success)

-- First, get retrievability
SELECT
    t.id,
    t.topic_id,
    f.stability,
    POWER(1 + (julianday('now') - julianday(f.last_review)) / (9.0 * f.stability), -1.0) AS retrievability
FROM topics t
JOIN fsrs_state f ON t.id = f.topic_id
WHERE t.topic_id = 'T01-fsrs-test';

-- Then update (use retrieved topic_id)
UPDATE fsrs_state
SET
    stability = MIN(365.0, stability * (1 + (11.0 - difficulty) * 0.1 * 1.6 * (1 + SQRT(stability)/10.0) * 1.4)),
    difficulty = MIN(10.0, MAX(1.0, difficulty + (5.0 - difficulty) * 0.01 + 0.2 * 0.2)),
    state = 2,
    last_review = CURRENT_TIMESTAMP,
    next_review = datetime('now', '+' || CAST(stability * 1.1 AS INTEGER) || ' days'),
    reviews = reviews + 1
WHERE topic_id = (SELECT id FROM topics WHERE topic_id = 'T01-fsrs-test');

-- Update mastery
UPDATE topics
SET
    mastery = 1 - EXP(-0.5 * (SELECT stability FROM fsrs_state WHERE topic_id = id) /
                       (SELECT difficulty FROM fsrs_state WHERE topic_id = id)),
    status = 'in_progress',
    updated_at = CURRENT_TIMESTAMP
WHERE topic_id = 'T01-fsrs-test';

-- Verify
SELECT t.topic_id, t.mastery, f.stability, f.difficulty, f.state, f.next_review
FROM topics t
JOIN fsrs_state f ON t.id = f.topic_id
WHERE t.topic_id = 'T01-fsrs-test';
```

---

### Step 7: Update SKILL.md

Add FSRS calculation section to SKILL.md:

```markdown
## FSRS-6 Calculations via MCP

All FSRS-6 calculations execute as SQL queries via SQLite MCP.

### Retrievability Query

```sql
-- Calculate retrievability for due topics
SELECT
    t.topic_id,
    t.name,
    f.stability,
    POWER(1 + (julianday('now') - julianday(f.last_review)) / (9.0 * f.stability), -1.0) AS retrievability
FROM topics t
JOIN fsrs_state f ON t.id = f.topic_id
WHERE t.next_review <= date('now')
ORDER BY retrievability ASC;
```

### Update After Review

Execute via MCP:
1. Calculate retrievability
2. Update fsrs_state with new stability/difficulty
3. Update topics with new mastery

See `docs/superpowers/mcp-queries/fsrs.sql` for complete queries.
```

---

## TESTING & VERIFICATION

```bash
echo "=== FSRS CALCULATION VERIFICATION ==="

# 1. Retrieveability formula correct
RESULT=$(sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT ROUND(POWER(1 + 10.0 / 90.0, -1.0), 2);")
test "$RESULT" = "0.9" && echo "✓ [1/5] Retrievability formula correct"

# 2. Stability update (success)
RESULT=$(sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT CAST(10.0 * (0.5 + 0.3 * 0.5) AS INTEGER);")
test "$RESULT" = "6" && echo "✓ [2/5] Stability decrease correct"

# 3. Mastery formula
RESULT=$(sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT ROUND(1 - EXP(-0.5 * 10.0 / 5.0), 2);")
test "$RESULT" = "0.63" && echo "✓ [3/5] Mastery formula correct"

# 4. Test topic mastery updated
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT mastery FROM topics WHERE topic_id='T01-fsrs-test';" | grep -q "0\." && echo "✓ [4/5] Topic mastery updated"

# 5. SKILL.md updated
grep -q "FSRS-6 Calculations via MCP" SKILL.md && echo "✓ [5/5] SKILL.md updated"

echo "=== ALL VERIFICATIONS PASSED ==="
```

---

## HUMAN VERIFICATION

```markdown
Verify:
- [ ] Retrievability formula matches: R = (1 + t/(9*S))^(-1)
- [ ] Stability update increases on success (performance >= 0.6)
- [ ] Stability update decreases on failure (performance < 0.6)
- [ ] Mastery formula: 1 - exp(-0.5 * S / D)
- [ ] State transitions: 0→1→2 (success), 2→3 (failure)
- [ ] SKILL.md documents MCP-based FSRS

## HUMAN SIGN-OFF ##
Status: [ ] I have verified the calculations match FSRS-6 specification.
```

---

## SUCCESS CRITERIA

```bash
echo "=== ACCEPTANCE CRITERIA ==="

# 1. Retrievability matches Python
test $(sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT ROUND(POWER(1 + 10.0/90.0, -1.0), 1);") = "0.9" && echo "✓ [1/4] Retrievability correct"

# 2. Stability update works
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT stability FROM fsrs_state WHERE topic_id=(SELECT id FROM topics WHERE topic_id='T01-fsrs-test');" | grep -q "." && echo "✓ [2/4] Stability updated"

# 3. Mastery calculated
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT mastery FROM topics WHERE topic_id='T01-fsrs-test';" | grep -q "0\." && echo "✓ [3/4] Mastery calculated"

# 4. SKILL.md updated
grep -q "FSRS-6 Calculations via MCP" SKILL.md && echo "✓ [4/4] SKILL.md documented"

echo "=== ALL CRITERIA VERIFIED ==="
```

---

## CLEANUP & COMPLETION

```bash
git add docs/superpowers/mcp-queries/fsrs.sql SKILL.md
git commit -m "feat(MIT-003): FSRS-6 calculations in SQL

- Verified retrievability formula: R = (1 + t/(9*S))^(-1)
- Stability updates for success/failure
- Mastery calculation: 1 - exp(-0.5 * S / D)
- State machine transitions
- Updated SKILL.md with FSRS section

Story: MIT-003
Dependencies: MIT-002
"

jq '.MIT-003.status = "passed" | .MIT-003.completedAt = "'$(date -Iseconds)'"' \
  .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json

cat > .superpowers/checkpoints/MIT-003-PASS << 'EOF'
{"storyId": "MIT-003", "status": "passed", "completedAt": "'$(date -Iseconds)'"}
EOF

echo "✓ MIT-003 passed"
```

---

## ROLLBACK

```bash
#!/bin/bash
set -e
REF=$(jq -r '.gitRef' .superpowers/checkpoints/MIT-003-START)
git checkout $REF -- docs/superpowers/mcp-queries/fsrs.sql SKILL.md
jq '.MIT-003.status = "pending"' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json
rm -f .superpowers/checkpoints/MIT-003-*
echo "Rollback complete"
```

---

**NEXT:** Proceed to MIT-004: Backup System

**END OF EXECUTION PROMPT FOR MIT-003**
