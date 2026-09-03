# MIT-004: Backup System

**Execution Prompt — Copy and paste into Claude session**

---

## STORY METADATA

```yaml
ID: MIT-004
Title: Backup System
Phase: 1
Effort: 2 hours
Impact: Data safety for accidental losses
Dependencies: MIT-003 (FSRS Calculations)
Parallelizable with: None
```

---

## PREFLIGHT CHECKS

```bash
set -e
echo "=== PREFLIGHT CHECKS FOR MIT-004 ==="

# 1. MIT-003 passed
jq -e '.MIT-003.status == "passed"' .superpowers/state/story-progress.json > /dev/null || { echo "FAIL: MIT-003 not passed"; exit 1; }

# 2. Backup SQL exists
test -f docs/superpowers/mcp-queries/backup.sql || { echo "FAIL: backup.sql not found"; exit 1; }

echo "✓ ALL PREFLIGHT CHECKS PASSED"
```

---

## STATE INITIALIZATION

```bash
cat > .superpowers/checkpoints/MIT-004-START << 'EOF'
{"storyId": "MIT-004", "createdAt": "'$(date -Iseconds)'", "gitRef": "'$(git rev-parse HEAD)'"}
EOF

jq '.MIT-004 = {"status": "in-progress", "phase": 1, "title": "Backup System", "startedAt": "'$(date -Iseconds)'", "dependencies": ["MIT-003"]}' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json
```

---

## IMPLEMENTATION STEPS

### Step 1: Create Backup Directory Structure

```bash
mkdir -p ~/.mit-learning/backups/
echo "Backup directory created at ~/.mit-learning/backups/"
```

---

### Step 2: Create Backup SQL

Write to `docs/superpowers/mcp-queries/backup.sql`:

```sql
-- ============================================
-- BACKUP OPERATIONS
-- ============================================

-- Backup creation (copy database)
-- Run via shell, not MCP
-- cp ~/.mit-learning/goals/<goal_id>/memory.db ~/.mit-learning/backups/<goal_id>_<timestamp>.db

-- Integrity check
PRAGMA integrity_check;

-- Export to SQL dump
.mode insert
.output ~/.mit-learning/backups/<goal_id>_<timestamp>.sql

-- Dump all tables
.dump goal_meta
.dump topics
.dump fsrs_state
.dump sessions
.dump prerequisites
.dump note_registry
.dump streak_state
.dump achievements

.output stdout

-- Verify backup
-- Compare row counts
SELECT 'goal_meta' AS tbl, COUNT(*) AS cnt FROM goal_meta
UNION ALL SELECT 'topics', COUNT(*) FROM topics
UNION ALL SELECT 'fsrs_state', COUNT(*) FROM fsrs_state
UNION ALL SELECT 'sessions', COUNT(*) FROM sessions
UNION ALL SELECT 'streak_state', COUNT(*) FROM streak_state;
```

---

### Step 3: Create Backup Script

Create `docs/superpowers/scripts/backup.sh`:

```bash
#!/bin/bash
# MIT Learning Skill Backup Script
# Usage: backup.sh <goal_id>

set -e

GOAL_ID="${1:-test}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME/.mit-learning/backups"
GOAL_DIR="$HOME/.mit-learning/goals/$GOAL_ID"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Check source exists
if [ ! -f "$GOAL_DIR/memory.db" ]; then
    echo "ERROR: Database not found at $GOAL_DIR/memory.db"
    exit 1
fi

# Create backup
BACKUP_FILE="$BACKUP_DIR/${GOAL_ID}_${TIMESTAMP}.db"
cp "$GOAL_DIR/memory.db" "$BACKUP_FILE"

# Verify
sqlite3 "$BACKUP_FILE" "PRAGMA integrity_check;" | grep -q "ok" || {
    echo "ERROR: Backup integrity check failed"
    rm "$BACKUP_FILE"
    exit 1
}

# Get row counts
echo "Backup created: $BACKUP_FILE"
sqlite3 "$BACKUP_FILE" "SELECT 'Topics:', COUNT(*) FROM topics; SELECT 'Sessions:', COUNT(*) FROM sessions;"

# Cleanup old backups (keep last 10)
ls -t "$BACKUP_DIR"/${GOAL_ID}_*.db | tail -n +11 | xargs -r rm

echo "Backup complete. Old backups cleaned up."
```

Make executable:
```bash
chmod +x docs/superpowers/scripts/backup.sh
```

---

### Step 4: Test Backup

```bash
# Create test data
sqlite3 ~/.mit-learning/goals/test/memory.db "INSERT INTO topics (topic_id, name) VALUES ('T01-backup-test', 'Backup Test');"

# Run backup
./docs/superpowers/scripts/backup.sh test

# Verify backup
ls -la ~/.mit-learning/backups/test_*.db
```

---

### Step 5: Create Restore Procedure

Add to backup.sql:

```sql
-- ============================================
-- RESTORE OPERATIONS
-- ============================================

-- Restore from backup
-- 1. Verify backup integrity
PRAGMA integrity_check;

-- 2. Check schema version
SELECT * FROM goal_meta;

-- 3. Verify row counts match original
SELECT 'goal_meta', COUNT(*) FROM goal_meta;

-- 4. Restore flags topic statuses
UPDATE topics SET status = 'pending' WHERE mastery < 0.1;
UPDATE topics SET status = 'in_progress' WHERE mastery >= 0.1 AND mastery < 0.9;
UPDATE topics SET status = 'mastered' WHERE mastery >= 0.9;
```

---

### Step 6: Update SKILL.md

Add backup triggers:

```markdown
## Backup System

### Automatic Triggers

Backup before:
- Schema migrations
- Bulk topic imports
- Goal deletion

### Manual Backup

```bash
./docs/superpowers/scripts/backup.sh <goal_id>
```

### Restore

```bash
# Restore from backup
cp ~/.mit-learning/backups/<goal_id>_<timestamp>.db ~/.mit-learning/goals/<goal_id>/memory.db

# Verify
sqlite3 ~/.mit-learning/goals/<goal_id>/memory.db "PRAGMA integrity_check;"
```

### Before Schema Changes

Always backup:
```bash
./docs/superpowers/scripts/backup.sh <goal_id>
# Then proceed with migration
```
```

---

## TESTING & VERIFICATION

```bash
echo "=== BACKUP VERIFICATION ==="

# 1. Backup script exists
test -f docs/superpowers/scripts/backup.sh && echo "✓ [1/5] Backup script created"

# 2. Script executable
test -x docs/superpowers/scripts/backup.sh && echo "✓ [2/5] Script executable"

# 3. Backup created
ls ~/.mit-learning/backups/test_*.db >/dev/null 2>&1 && echo "✓ [3/5] Backup file exists"

# 4. Integrity check
BACKUP=$(ls -t ~/.mit-learning/backups/test_*.db | head -1)
sqlite3 "$BACKUP" "PRAGMA integrity_check;" | grep -q "ok" && echo "✓ [4/5] Backup passes integrity check"

# 5. SKILL.md updated
grep -q "Backup System" SKILL.md && echo "✓ [5/5] SKILL.md has backup section"

echo "=== ALL VERIFICATIONS PASSED ==="
```

---

## HUMAN VERIFICATION

```markdown
Verify:
- [ ] Backup script executes without errors
- [ ] Backup file created with timestamp
- [ ] Backup passes SQLite integrity check
- [ ] Restore procedure documented
- [ ] SKILL.md has backup triggers

## HUMAN SIGN-OFF ##
Status: [ ] I have verified backup/restore works correctly.
```

---

## SUCCESS CRITERIA

```bash
echo "=== ACCEPTANCE CRITERIA ==="

# 1. Backup script exists and executable
test -x docs/superpowers/scripts/backup.sh && echo "✓ [1/4] Backup script ready"

# 2. Test backup created
ls ~/.mit-learning/backups/test_*.db >/dev/null && echo "✓ [2/4] Test backup exists"

# 3. Integrity verified
sqlite3 ~/.mit-learning/backups/test_*.db "PRAGMA integrity_check;" 2>&1 | grep -q "ok" && echo "✓ [3/4] Integrity verified"

# 4. SKILL.md documented
grep -q "Manual Backup" SKILL.md && echo "✓ [4/4] SKILL.md has backup docs"

echo "=== PHASE 1 COMPLETE ==="
```

---

## CLEANUP & COMPLETION

```bash
git add docs/superpowers/mcp-queries/backup.sql docs/superpowers/scripts/backup.sh SKILL.md
git commit -m "feat(MIT-004): backup system

- Backup script for database safety
- Integrity verification
- Restore procedure documented
- Automatic cleanup (keep last 10)

Story: MIT-004
Dependencies: MIT-003
Phase: 1 Complete
"

jq '.MIT-004.status = "passed" | .MIT-004.completedAt = "'$(date -Iseconds)'"' \
  .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json

cat > .superpowers/checkpoints/MIT-004-PASS << 'EOF'
{"storyId": "MIT-004", "status": "passed", "completedAt": "'$(date -Iseconds)'", "phase": "1-complete"}
EOF

echo "✓ MIT-004 passed"
echo "✓ PHASE 1 COMPLETE"
```

---

## ROLLBACK

```bash
#!/bin/bash
set -e
REF=$(jq -r '.gitRef' .superpowers/checkpoints/MIT-004-START)
git checkout $REF -- docs/superpowers/mcp-queries/backup.sql SKILL.md
rm -rf docs/superpowers/scripts/backup.sh
jq '.MIT-004.status = "pending"' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json
rm -f .superpowers/checkpoints/MIT-004-*
echo "Rollback complete"
```

---

**NEXT:** Proceed to Phase 2: Workflows (MIT-005)

**END OF EXECUTION PROMPT FOR MIT-004**
