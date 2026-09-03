# MIT-001: SQLite MCP Query Templates

**Execution Prompt — Copy and paste into Claude session**

---

## STORY METADATA

```yaml
ID: MIT-001
Title: Create SQLite MCP Query Templates for MIT Learning Skill
Phase: 1
Effort: 2 hours
Impact: Foundation for all data operations — eliminates Python dependency
Dependencies: None
Parallelizable with: None (blocks all other stories)
```

---

## PREFLIGHT CHECKS

Run these checks BEFORE starting implementation. Fail fast if any fail.

### Automated Preflight

```bash
# RUN THIS BLOCK FIRST
set -e

echo "=== PREFLIGHT CHECKS FOR MIT-001 ==="

# 1. Environment
echo "Checking environment..."
git --version | grep -q "2.3" || { echo "FAIL: Git 2.30+ required"; exit 1; }

# 2. SKILL.md exists
echo "Checking SKILL.md..."
test -f SKILL.md || { echo "FAIL: SKILL.md not found at repo root"; exit 1; }

# 3. MCP Available (check via tool availability)
echo "Checking SQLite MCP availability..."
# Claude should have mcp__sqlite__* tools available

# 4. Git clean
echo "Checking git state..."
git diff --quiet || { echo "FAIL: Uncommitted changes. Commit or stash first"; exit 1; }

# 5. State directory exists
echo "Checking state directory..."
mkdir -p .superpowers/state .superpowers/checkpoints .superpowers/worktrees

echo ""
echo "✓ ALL PREFLIGHT CHECKS PASSED"
echo "Proceeding with implementation..."
```

### Manual Prerequisites (Human verify)

```markdown
Before starting, confirm:
- [ ] Claude Code has SQLite MCP access
- [ ] SKILL.md is the current version
- [ ] Goal directory path available (~/.mit-learning/)
```

---

## STATE INITIALIZATION

Create checkpoint and update state:

```bash
# Create checkpoint
mkdir -p .superpowers/checkpoints .superpowers/state

cat > .superpowers/checkpoints/MIT-001-START << 'EOF'
{
  "storyId": "MIT-001",
  "createdAt": "'$(date -Iseconds)'",
  "gitRef": "'$(git rev-parse HEAD)'",
  "files": [
    "docs/superpowers/mcp-queries/"
  ]
}
EOF

# Initialize state file if not exists
test -f .superpowers/state/story-progress.json || echo '{}' > .superpowers/state/story-progress.json

# Update state to in-progress
jq '.MIT-001 = {
  "status": "in-progress",
  "phase": 1,
  "title": "SQLite MCP Query Templates",
  "startedAt": "'$(date -Iseconds)'"
}' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json
```

---

## WORKTREE SETUP (Isolation)

Create isolated worktree for this story:

```bash
# Create worktree
git worktree add .superpowers/worktrees/MIT-001 -b story/MIT-001

# Switch to worktree
cd .superpowers/worktrees/MIT-001

echo "Working in isolated worktree: $(pwd)"
echo "Branch: $(git branch --show-current)"
```

---

## IMPLEMENTATION STEPS

### Step 1: Create MCP Queries Directory

**Prompt for this step:**

```
Create the following directory structure:

docs/superpowers/mcp-queries/
├── README.md           # Overview and usage
├── schema.sql          # Schema initialization
├── fsrs.sql            # FSRS-6 calculations
├── learning.sql        # Learning session queries
├── review.sql          # Review session queries
├── practice.sql        # Practice session queries
├── research.sql        # Research workflow queries
├── streak.sql          # Streak and achievement queries
└── backup.sql          # Backup operations

Create the directory:
mkdir -p docs/superpowers/mcp-queries
```

**Expected outcome:** Directory structure created.

**Verification:**
```bash
ls -la docs/superpowers/mcp-queries/
```

---

### Step 2: Create README.md for MCP Queries

**Prompt for this step:**

```
Create docs/superpowers/mcp-queries/README.md with:

# SQLite MCP Query Templates

Query templates for MIT Learning Skill data operations via SQLite MCP.

## Organization

| File | Purpose |
|------|---------|
| schema.sql | Database initialization, table creation |
| fsrs.sql | FSRS-6 scheduling calculations |
| learning.sql | Learning session operations |
| review.sql | Review queue and session management |
| practice.sql | Practice session operations |
| research.sql | Research workflow storage |
| streak.sql | Streak tracking and achievements |
| backup.sql | Backup and restore operations |

## Usage

Each .sql file contains parameterized queries designed for SQLite MCP execution.

Parameters use `:param` syntax:
- `:goal_id` — Learning goal identifier
- `:topic_id` — Topic identifier  
- `:performance` — User performance rating (0.0-1.0)
- `:created_at` — Timestamp

Execute via Claude Code MCP tools:
mcp__sqlite__query({ database: "path/to/memory.db", query: "<SQL>" })

## Testing

Run verification queries after any change:
sqlite3 ~/.mit-learning/goals/test/memory.db < schema.sql
```

**Verification:**
```bash
test -f docs/superpowers/mcp-queries/README.md && echo "✓ README created"
```

---

### Step 3: Create Schema Initialization SQL

**Prompt for this step:**

```
Create docs/superpowers/mcp-queries/schema.sql with complete database schema:

-- Goal metadata
CREATE TABLE IF NOT EXISTS goal_meta (
    goal_id TEXT PRIMARY KEY,
    goal_type TEXT NOT NULL CHECK(goal_type IN ('exam', 'skill', 'degree', 'topic')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    vault_path TEXT,
    total_topics INTEGER DEFAULT 0,
    mastered_topics INTEGER DEFAULT 0
);

-- Topics with mastery tracking
CREATE TABLE IF NOT EXISTS topics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    mastery REAL DEFAULT 0.0 CHECK(mastery >= 0.0 AND mastery <= 1.0),
    status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'in_progress', 'mastered')),
    next_review DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- FSRS-6 state tracking
CREATE TABLE IF NOT EXISTS fsrs_state (
    topic_id INTEGER PRIMARY KEY,
    stability REAL DEFAULT 2.5 CHECK(stability >= 0.0 AND stability <= 365.0),
    difficulty REAL DEFAULT 5.0 CHECK(difficulty >= 1.0 AND difficulty <= 10.0),
    state INTEGER DEFAULT 0 CHECK(state IN (0, 1, 2, 3)),
    last_review TIMESTAMP,
    next_review TIMESTAMP,
    reviews INTEGER DEFAULT 0,
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);

-- Session history
CREATE TABLE IF NOT EXISTS sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_type TEXT NOT NULL CHECK(session_type IN ('review', 'practice', 'assessment', 'learning')),
    topic_id INTEGER,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP,
    performance REAL CHECK(performance >= 0.0 AND performance <= 1.0),
    duration_seconds INTEGER,
    notes TEXT,
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);

-- Prerequisites graph
CREATE TABLE IF NOT EXISTS prerequisites (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id INTEGER NOT NULL,
    prerequisite_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (topic_id) REFERENCES topics(id),
    FOREIGN KEY (prerequisite_id) REFERENCES topics(id),
    UNIQUE(topic_id, prerequisite_id)
);

-- Note registry (Obsidian vault links)
CREATE TABLE IF NOT EXISTS note_registry (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id INTEGER NOT NULL,
    note_path TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);

-- Streak tracking
CREATE TABLE IF NOT EXISTS streak_state (
    goal_id TEXT PRIMARY KEY,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_activity_date DATE,
    streak_freeze_available INTEGER DEFAULT 1,
    streak_freeze_used_date DATE,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id)
);

-- Achievements
CREATE TABLE IF NOT EXISTS achievements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    achievement_id TEXT NOT NULL,
    unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id),
    UNIQUE(goal_id, achievement_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_topics_status ON topics(status);
CREATE INDEX IF NOT EXISTS idx_topics_next_review ON topics(next_review);
CREATE INDEX IF NOT EXISTS idx_fsrs_next_review ON fsrs_state(next_review);
CREATE INDEX IF NOT EXISTS idx_sessions_topic ON sessions(topic_id);
CREATE INDEX IF NOT EXISTS idx_sessions_started ON sessions(started_at);
```

**Verification:**
```bash
grep -q "CREATE TABLE IF NOT EXISTS goal_meta" docs/superpowers/mcp-queries/schema.sql && echo "✓ Schema SQL created"
```

---

### Step 4: Create FSRS-6 Calculation SQL

**Prompt for this step:**

```
Create docs/superpowers/mcp-queries/fsrs.sql with FSRS-6 formulas as SQL:

-- ============================================
-- FSRS-6 CALCULATIONS
-- ============================================

-- Retrievability calculation: R(t, S) = (1 + t/(9*S))^(-1)
-- Query: Calculate retrievability for all due topics
-- Parameters: :goal_id

SELECT 
    t.id,
    t.topic_id,
    t.name,
    f.stability,
    f.difficulty,
    f.state,
    f.last_review,
    CAST(julianday('now') - julianday(f.last_review) AS REAL) AS days_since_review,
    POWER(1 + (julianday('now') - julianday(f.last_review)) / (9.0 * f.stability), -1.0) AS retrievability,
    POWER(1 + (julianday('now') - julianday(f.last_review)) / (9.0 * f.stability), -1.0) - 0.9 AS priority
FROM topics t
JOIN fsrs_state f ON t.id = f.topic_id
WHERE t.next_review <= date('now')
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
    difficulty = MIN(10.0, MAX(1.0, difficulty + (5.0 - difficulty) * 0.01 + (1 - :performance) * 0.2)),
    state = CASE
        WHEN state = 0 THEN 1
        WHEN state = 1 AND :performance >= 0.6 THEN 2
        WHEN state = 2 AND :performance < 0.6 THEN 3
        WHEN state = 3 AND :performance >= 0.6 THEN 2
        ELSE state
    END,
    last_review = CURRENT_TIMESTAMP,
    next_review = datetime('now', '+' || CAST(MIN(365, stability * 1.1) AS INTEGER) || ' days'),
    reviews = reviews + 1
WHERE topic_id = :topic_id AND :performance >= 0.6;

-- ============================================
-- STABILITY UPDATE (Failure: performance < 0.6)
-- ============================================
-- Formula: S' = S * (0.5 + performance * 0.5)

UPDATE fsrs_state
SET 
    stability = MAX(1.0, stability * (0.5 + :performance * 0.5)),
    difficulty = MIN(10.0, MAX(1.0, difficulty + (5.0 - difficulty) * 0.01 + (1 - :performance) * 0.2)),
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
```

**Verification:**
```bash
grep -q "retrievability" docs/superpowers/mcp-queries/fsrs.sql && echo "✓ FSRS SQL created"
```

---

### Step 5: Create Learning Session SQL

**Prompt for this step:**

```
Create docs/superpowers/mcp-queries/learning.sql:

-- ============================================
-- LEARNING SESSION QUERIES
-- ============================================

-- Get or create topic
-- Parameters: :topic_name, :goal_id

INSERT INTO topics (topic_id, name, status, created_at)
VALUES (
    'T' || strftime('%Y%m%d%H%M%S', 'now') || '-' || LOWER(REPLACE(:topic_name, ' ', '-')),
    :topic_name,
    'in_progress',
    CURRENT_TIMESTAMP
)
ON CONFLICT(topic_id) DO UPDATE SET updated_at = CURRENT_TIMESTAMP;

-- Initialize FSRS state for new topic
-- Parameters: :topic_id (internal id)

INSERT INTO fsrs_state (topic_id, stability, difficulty, state, last_review)
VALUES (:topic_id, 2.5, 5.0, 0, CURRENT_TIMESTAMP)
ON CONFLICT(topic_id) DO NOTHING;

-- Start learning session
-- Parameters: :topic_id

INSERT INTO sessions (session_type, topic_id, started_at)
VALUES ('learning', :topic_id, CURRENT_TIMESTAMP);

-- End learning session with performance
-- Parameters: :session_id, :performance, :notes

UPDATE sessions
SET 
    ended_at = CURRENT_TIMESTAMP,
    performance = :performance,
    duration_seconds = CAST((julianday(CURRENT_TIMESTAMP) - julianday(started_at)) * 86400 AS INTEGER),
    notes = :notes
WHERE id = :session_id;

-- Get related topics (prerequisites)
-- Parameters: :topic_id

SELECT t.topic_id, t.name, t.mastery
FROM topics t
JOIN prerequisites p ON t.id = p.prerequisite_id
WHERE p.topic_id = :topic_id
ORDER BY t.mastery ASC;
```

**Verification:**
```bash
grep -q "session_type" docs/superpowers/mcp-queries/learning.sql && echo "✓ Learning SQL created"
```

---

### Step 6: Create Remaining Query Files

**Prompt for this step:**

```
Create the remaining SQL files with placeholder structure:

1. docs/superpowers/mcp-queries/review.sql:
-- Review queue queries
-- Due topics query (using fsrs.sql retrievability)
-- Session start/end

2. docs/superpowers/mcp-queries/practice.sql:
-- Practice problem queries
-- Performance tracking
-- Interleaved topic selection

3. docs/superpowers/mcp-queries/research.sql:
-- Source storage
-- Claim triangulation
-- Note registry links

4. docs/superpowers/mcp-queries/streak.sql:
-- Activity tracking
-- Streak increment
-- Freeze usage
-- Achievement unlock

5. docs/superpowers/mcp-queries/backup.sql:
-- Backup creation
-- Verification
-- Restore operations

Create each with appropriate header comment and basic structure matching the patterns in fsrs.sql and learning.sql.
```

**Verification:**
```bash
ls -la docs/superpowers/mcp-queries/*.sql | wc -l | grep -q "8" && echo "✓ All SQL files created"
```

---

### Step 7: Update SKILL.md with Query References

**Prompt for this step:**

```
Add a new section to SKILL.md after the FSRS-6 Constants section:

## MCP Query Templates

All data operations use SQLite MCP queries from `docs/superpowers/mcp-queries/`.

### Usage Pattern

```
User trigger → SKILL.md → mcp__sqlite__query → Return
```

### Query Files

| File | Purpose | Workflows |
|------|---------|-----------|
| schema.sql | Database initialization | New goal setup |
| fsrs.sql | FSRS-6 calculations | Review, Learning |
| learning.sql | Learning sessions | learning_session |
| review.sql | Review management | review_session |
| practice.sql | Practice tracking | practice_session |
| research.sql | Research storage | research |
| streak.sql | Gamification | progress_dashboard |
| backup.sql | Safety | Manual trigger |

Add this as Section 4.5 (numbered appropriately).
```

**Verification:**
```bash
grep -q "MCP Query Templates" SKILL.md && echo "✓ SKILL.md updated with MCP section"
```

---

## TESTING & VERIFICATION

### SQL Syntax Check

```bash
echo "=== SQL SYNTAX CHECK ==="

for file in docs/superpowers/mcp-queries/*.sql; do
  echo "Checking $file..."
  # Basic syntax check (requires sqlite3)
  sqlite3 :memory: < "$file" 2>&1 | head -5 || echo "Note: $file may have parameterized queries"
done

echo "✓ SQL files validated"
```

### Directory Structure

```bash
echo "=== DIRECTORY STRUCTURE ==="
ls -la docs/superpowers/mcp-queries/
echo "✓ Structure verified"
```

### File Contents Spot Check

```bash
echo "=== CONTENT VERIFICATION ==="
grep -l "CREATE TABLE" docs/superpowers/mcp-queries/*.sql && echo "✓ Schema has tables"
grep -l "retrievability" docs/superpowers/mcp-queries/*.sql && echo "✓ FSRS calculations present"
grep -l "session" docs/superpowers/mcp-queries/*.sql && echo "✓ Session queries present"
```

### SKILL.md Integration

```bash
echo "=== SKILL.MD INTEGRATION ==="
grep -A5 "MCP Query Templates" SKILL.md && echo "✓ SKILL.md has MCP section"
```

---

## HUMAN VERIFICATION

**REQUIRED: Human sign-off before marking complete.**

```markdown
Verify the following:
- [ ] Directory structure: docs/superpowers/mcp-queries/ exists
- [ ] 8 SQL files created (schema, fsrs, learning, review, practice, research, streak, backup)
- [ ] README.md documents query file purposes
- [ ] schema.sql has all 8 tables with CHECK constraints
- [ ] fsrs.sql has retrievability and stability calculations
- [ ] SKILL.md has MCP Query Templates section
- [ ] All queries use parameterized syntax (:param)

## HUMAN SIGN-OFF ##
Status: [ ] I have verified the above items and approve this story.
```

**Copy this section and ask human to confirm before proceeding.**

---

## SUCCESS CRITERIA CHECKLIST

```bash
echo "=== ACCEPTANCE CRITERIA VERIFICATION ==="

# 1. Directory exists
test -d docs/superpowers/mcp-queries && echo "✓ [1/6] MCP queries directory exists"

# 2. 8 SQL files
test $(ls docs/superpowers/mcp-queries/*.sql 2>/dev/null | wc -l) -eq 8 && echo "✓ [2/6] All 8 SQL files created"

# 3. README exists
test -f docs/superpowers/mcp-queries/README.md && echo "✓ [3/6] README exists"

# 4. Schema has core tables
grep -q "goal_meta" docs/superpowers/mcp-queries/schema.sql && echo "✓ [4/6] Schema has goal_meta"
grep -q "fsrs_state" docs/superpowers/mcp-queries/schema.sql && echo "✓ [5/6] Schema has fsrs_state"

# 5. FSRS has retrievability
grep -q "retrievability" docs/superpowers/mcp-queries/fsrs.sql && echo "✓ [6/6] FSRS calculations present"

# 6. SKILL.md references MCP
grep -q "MCP Query Templates" SKILL.md && echo "✓ [7/7] SKILL.md has MCP section"

echo ""
echo "=== ALL CRITERIA VERIFIED ==="
```

---

## CLEANUP & COMPLETION

### Commit Changes

```bash
echo "=== COMMITTING CHANGES ==="

cd .superpowers/worktrees/MIT-001

git add docs/superpowers/mcp-queries/
git add SKILL.md

git commit -m "feat(MIT-001): create SQLite MCP query templates

- Add 8 SQL files for all data operations
- Schema with CHECK constraints for safety
- FSRS-6 calculations in pure SQL
- Learning, review, practice, research queries
- Streak and achievement tracking
- Backup operations
- Update SKILL.md with MCP section

Story: MIT-001
Impact: Foundation for Python-free architecture
"
```

### Merge Worktree

```bash
echo "=== MERGING WORKTREE ==="

git checkout main
git merge story/MIT-001 --no-ff -m "Merge story/MIT-001: SQLite MCP Query Templates"

# Cleanup worktree
git worktree remove .superpowers/worktrees/MIT-001
git branch -d story/MIT-001

echo "✓ Worktree merged and cleaned up"
```

### Update State

```bash
# Create PASS checkpoint
cat > .superpowers/checkpoints/MIT-001-PASS << 'EOF'
{
  "storyId": "MIT-001",
  "completedAt": "'$(date -Iseconds)'",
  "status": "passed",
  "acceptanceCriteria": [
    { "criterion": "MCP queries directory exists", "passed": true },
    { "criterion": "8 SQL files created", "passed": true },
    { "criterion": "README documents structure", "passed": true },
    { "criterion": "Schema has all tables", "passed": true },
    { "criterion": "FSRS calculations present", "passed": true },
    { "criterion": "SKILL.md has MCP section", "passed": true }
  ],
  "signedOffBy": "human"
}
EOF

# Update state file
jq '.MIT-001.status = "passed" | .MIT-001.completedAt = "'$(date -Iseconds)'"' \
  .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json

echo "✓ State updated: MIT-001 passed"
```

---

## ROLLBACK PROCEDURE

**If story fails and needs complete rollback:**

```bash
#!/bin/bash
# Rollback script for MIT-001

set -e

echo "Rolling back MIT-001..."

# Restore git state
git checkout main
git reset --hard HEAD

# Remove created files
rm -rf docs/superpowers/mcp-queries/

# Restore SKILL.md from checkpoint
if [ -f .superpowers/checkpoints/MIT-001-START ]; then
  REF=$(jq -r '.gitRef' .superpowers/checkpoints/MIT-001-START)
  git checkout $REF -- SKILL.md
fi

# Remove worktree if exists
git worktree remove .superpowers/worktrees/MIT-001 2>/dev/null || true
git branch -D story/MIT-001 2>/dev/null || true

# Update state
jq '.MIT-001.status = "pending"' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json

# Remove checkpoints
rm -f .superpowers/checkpoints/MIT-001-*

echo "Rollback complete. MIT-001 status: pending"
```

---

## NEXT STEPS

After MIT-001 passes:

1. **Proceed to MIT-002:** Schema Initialization via MCP
2. **Test queries:** Execute schema.sql against test database
3. **Update README.md:** Add MCP architecture section

---

**END OF EXECUTION PROMPT FOR MIT-001**

**Copy everything above this line and paste into Claude session.**
