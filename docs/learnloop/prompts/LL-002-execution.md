# LL-002: Schema Initialization via MCP

**Execution Prompt — Copy and paste into Claude session**

---

## STORY METADATA

```yaml
ID: LL-002
Title: Schema Initialization via MCP
Phase: 1
Effort: 3 hours
Impact: Database creation without Python scripts
Dependencies: LL-001 (MCP Query Templates)
Parallelizable with: None (depends on LL-001)
```

---

## PREFLIGHT CHECKS

```bash
set -e
echo "=== PREFLIGHT CHECKS FOR LL-002 ==="

# 1. LL-001 passed
jq -e '.LL-001.status == "passed"' .superpowers/state/story-progress.json > /dev/null || { echo "FAIL: LL-001 not passed"; exit 1; }

# 2. Schema SQL exists
test -f docs/learnloop/mcp-queries/schema.sql || { echo "FAIL: schema.sql not found"; exit 1; }

# 3. Goal directory path
echo "Goal directory will be: ~/.mit-learning/goals/<goal_id>/"

echo "✓ ALL PREFLIGHT CHECKS PASSED"
```

---

## STATE INITIALIZATION

```bash
mkdir -p .superpowers/checkpoints

cat > .superpowers/checkpoints/LL-002-START << 'EOF'
{
  "storyId": "LL-002",
  "createdAt": "'$(date -Iseconds)'",
  "gitRef": "'$(git rev-parse HEAD)'",
  "files": ["SKILL.md"]
}
EOF

jq '.LL-002 = {
  "status": "in-progress",
  "phase": 1,
  "title": "Schema Initialization via MCP",
  "startedAt": "'$(date -Iseconds)'",
  "dependencies": ["LL-001"]
}' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json
```

---

## IMPLEMENTATION STEPS

### Step 1: Test Schema Creation

Execute schema.sql via MCP against test database:

```markdown
Using SQLite MCP, execute the following:

1. Create test goal directory: ~/.mit-learning/goals/test/
2. Execute schema.sql contents against new database
3. Verify tables created

MCP command:
mcp__sqlite__query({
  database: "~/.mit-learning/goals/test/memory.db",
  query: "<contents of schema.sql>"
})
```

**Verification:**
```bash
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;"
# Expected: achievements, fsrs_state, goal_meta, note_registry, prerequisites, sessions, streak_state, topics
```

---

### Step 2: Update SKILL.md Workflow

Add schema initialization to syllabus_generation workflow:

```markdown
Update SKILL.md syllabus_generation workflow to include:

### Database Initialization

When creating a new learning goal:

1. **Create goal directory:** `~/.mit-learning/goals/<goal_id>/`
2. **Initialize database via MCP:**
   ```
   mcp__sqlite__query({
     database: "~/.mit-learning/goals/<goal_id>/memory.db",
     query: "<schema.sql contents>"
   })
   ```
3. **Insert goal metadata:**
   ```sql
   INSERT INTO goal_meta (goal_id, goal_type, created_at)
   VALUES (:goal_id, :goal_type, CURRENT_TIMESTAMP);
   ```
4. **Initialize streak state:**
   ```sql
   INSERT INTO streak_state (goal_id, current_streak, last_activity_date)
   VALUES (:goal_id, 0, date('now'));
   ```

Replace any Python script references with direct MCP execution.
```

---

### Step 3: Create Goal Directory Structure

Add to SKILL.md:

```markdown
### Goal Directory Structure

Each goal creates:

```
~/.mit-learning/goals/<goal_id>/
├── memory.db           # SQLite database (via MCP)
├── notes/               # Obsidian vault sync
│   ├── topics/
│   ├── sessions/
│   └── research/
└── config.json          # Goal configuration
```

Creation via shell (one-time setup):
```bash
mkdir -p ~/.mit-learning/goals/<goal_id>/{notes/{topics,sessions,research}}
```
```

---

### Step 4: Test Against Python Baseline

If Python scripts exist:

```bash
# Run Python initialization
python scripts/init_goal.py --goal-id test_python --type exam

# Run MCP initialization
# (via Claude session)

# Compare databases
sqlite3 ~/.mit-learning/goals/test_python/memory.db ".schema" > /tmp/python_schema.sql
sqlite3 ~/.mit-learning/goals/test/memory.db ".schema" > /tmp/mcp_schema.sql

diff /tmp/python_schema.sql /tmp/mcp_schema.sql || echo "Schemas differ - review"
```

---

## TESTING & VERIFICATION

```bash
echo "=== SCHEMA VERIFICATION ==="

# 1. Database file created
test -f ~/.mit-learning/goals/test/memory.db && echo "✓ Database file exists"

# 2. All tables present
TABLES=$(sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT COUNT(*) FROM sqlite_master WHERE type='table';")
test "$TABLES" -eq 8 && echo "✓ All 8 tables created"

# 3. CHECK constraints active
sqlite3 ~/.mit-learning/goals/test/memory.db "INSERT INTO topics (topic_id, name, mastery) VALUES ('T01', 'Test', 1.5);" 2>&1 | grep -q "CHECK constraint" && echo "✓ Constraints enforced"

# 4. Indexes created
IDX=$(sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%';")
test "$IDX" -ge 5 && echo "✓ Indexes created"

# 5. SKILL.md updated
grep -q "mcp__sqlite__query" SKILL.md && echo "✓ SKILL.md has MCP references"
```

---

## HUMAN VERIFICATION

```markdown
Verify:
- [ ] Test database created at ~/.mit-learning/goals/test/memory.db
- [ ] All 8 tables present (achievements, fsrs_state, goal_meta, note_registry, prerequisites, sessions, streak_state, topics)
- [ ] CHECK constraints reject invalid data
- [ ] SKILL.md has MCP-based workflow
- [ ] No Python scripts required for initialization

## HUMAN SIGN-OFF ##
Status: [ ] I have verified the above items and approve this story.
```

---

## SUCCESS CRITERIA

```bash
echo "=== ACCEPTANCE CRITERIA ==="

# 1. Database created via MCP
test -f ~/.mit-learning/goals/test/memory.db && echo "✓ [1/5] Database created"

# 2. All tables exist
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT name FROM sqlite_master WHERE type='table';" | grep -c "goal_meta\|topics\|fsrs_state" | grep -q "3" && echo "✓ [2/5] Core tables exist"

# 3. Constraints enforced
sqlite3 ~/.mit-learning/goals/test/memory.db "INSERT INTO goal_meta (goal_id, goal_type) VALUES ('test', 'invalid');" 2>&1 | grep -q "CHECK" && echo "✓ [3/5] Constraints work"

# 4. Streak initialized correctly
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT current_streak FROM streak_state WHERE goal_id='test';" | grep -q "0" && echo "✓ [4/5] Streak initialized"

# 5. SKILL.md updated
grep -q "mcp__sqlite__query" SKILL.md && echo "✓ [5/5] SKILL.md has MCP workflow"

echo "=== ALL CRITERIA VERIFIED ==="
```

---

## CLEANUP & COMPLETION

```bash
# Commit
git add SKILL.md
git commit -m "feat(LL-002): schema initialization via MCP

- Add MCP-based database creation to SKILL.md
- Test schema execution via SQLite MCP
- Remove Python initialization dependency

Story: LL-002
Dependencies: LL-001
"

# Update state
jq '.LL-002.status = "passed" | .LL-002.completedAt = "'$(date -Iseconds)'"' \
  .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json

cat > .superpowers/checkpoints/LL-002-PASS << 'EOF'
{
  "storyId": "LL-002",
  "completedAt": "'$(date -Iseconds)'",
  "status": "passed",
  "acceptanceCriteria": [
    { "criterion": "Database created via MCP", "passed": true },
    { "criterion": "All 8 tables exist", "passed": true },
    { "criterion": "CHECK constraints enforced", "passed": true },
    { "criterion": "SKILL.md has MCP workflow", "passed": true }
  ]
}
EOF

echo "✓ LL-002 passed"
```

---

## ROLLBACK

```bash
#!/bin/bash
set -e
echo "Rolling back LL-002..."

# Remove test database
rm -rf ~/.mit-learning/goals/test/

# Restore SKILL.md
REF=$(jq -r '.gitRef' .superpowers/checkpoints/LL-002-START)
git checkout $REF -- SKILL.md

# Update state
jq '.LL-002.status = "pending"' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json

rm -f .superpowers/checkpoints/LL-002-*
echo "Rollback complete"
```

---

**NEXT:** Proceed to LL-003: FSRS-6 Calculations in SQL

**END OF EXECUTION PROMPT FOR LL-002**
