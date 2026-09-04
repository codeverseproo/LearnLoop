# State Management Specification

**Version:** 1.0.0
**Purpose:** Track story execution state, enable resume-from-interruption, coordinate dependencies

---

## Overview

The state management system provides:

1. **Story progress tracking** — Know which stories passed, pending, failed
2. **Checkpoint system** — Snapshots for rollback
3. **Dependency validation** — Automated prerequisite checks
4. **Resume capability** — Continue interrupted work

---

## File Structure

```
.superpowers/
├── state/
│   ├── story-progress.json       # Master state file
│   └── session-context.json      # Current session info
├── checkpoints/
│   ├── LL-001-START              # Pre-execution snapshot
│   ├── LL-001-PASS               # Success marker
│   └── LL-001-rollback.sh        # Rollback script
└── worktrees/
    └── LL-001/                   # Isolated worktree (if used)
```

---

## State File Schema

### story-progress.json

```json
{
  "LL-001": {
    "status": "passed",
    "phase": 1,
    "title": "SQLite MCP Query Templates",
    "startedAt": "2026-09-03T12:00:00Z",
    "completedAt": "2026-09-03T14:00:00Z",
    "effort": "2h",
    "impact": "Foundation for all data operations",
    "filesChanged": [
      "docs/learnloop/mcp-queries/",
      "SKILL.md"
    ],
    "signedOffBy": "human",
    "checkpoint": ".superpowers/checkpoints/LL-001-PASS",
    "notes": "All query templates created successfully"
  },
  "LL-002": {
    "status": "pending",
    "phase": 1,
    "title": "Schema Initialization via MCP",
    "dependencies": ["LL-001"],
    "prerequisites": [
      "SQLite MCP access",
      "Goal directory path configured"
    ]
  },
  "LL-003": {
    "status": "in-progress",
    "phase": 1,
    "title": "FSRS-6 Calculations in SQL",
    "startedAt": "2026-09-03T15:00:00Z",
    "currentStep": "implementation",
    "checkpoint": ".superpowers/checkpoints/LL-003-START"
  }
}
```

### Status Values

- `pending` — Not started, prerequisites not validated
- `ready` — Prerequisites validated, ready to execute
- `in-progress` — Currently executing
- `passed` — Successfully completed, all criteria verified
- `failed` — Execution failed, needs rollback
- `blocked` — Dependencies not met

---

## Checkpoint System

### Checkpoint Types

#### START Checkpoint

Created before story execution begins:

```json
{
  "storyId": "LL-001",
  "createdAt": "2026-09-03T12:00:00Z",
  "gitRef": "abc123def456",
  "files": [
    "docs/learnloop/mcp-queries/",
    "SKILL.md"
  ],
  "environment": {
    "git": "2.39.0",
    "mcp": "sqlite"
  }
}
```

#### PASS Checkpoint

Created after successful completion:

```json
{
  "storyId": "LL-001",
  "completedAt": "2026-09-03T14:00:00Z",
  "gitRef": "def789ghi012",
  "acceptanceCriteria": [
    { "criterion": "MCP queries directory exists", "passed": true },
    { "criterion": "8 SQL files created", "passed": true },
    { "criterion": "README documents structure", "passed": true }
  ],
  "signedOffBy": "human",
  "notes": "All query templates created"
}
```

#### Rollback Script

Generated at START, executable on failure:

```bash
#!/bin/bash
# .superpowers/checkpoints/LL-001-rollback.sh
set -e

echo "Rolling back LL-001..."

# Restore git state
git checkout abc123def456

# Remove created files
rm -rf docs/learnloop/mcp-queries/

# Restore modified files
git checkout abc123def456 -- SKILL.md

# Update state
jq '.LL-001.status = "pending"' .superpowers/state/story-progress.json > tmp.json
mv tmp.json .superpowers/state/story-progress.json

# Remove checkpoints
rm -f .superpowers/checkpoints/LL-001-*

echo "Rollback complete. LL-001 status: pending"
```

---

## Prerequisite Validation

### Automated Preflight Checks

Each story prompt includes preflight script:

```bash
#!/bin/bash
# Preflight checks for LL-001

echo "Running preflight checks for LL-001..."

# Environment
git --version | grep -q "2.3" || { echo "FAIL: Git 2.30+ required"; exit 1; }

# SQLite MCP
# Check tool availability in Claude session

# File existence
test -f SKILL.md || { echo "FAIL: SKILL.md not found"; exit 1; }

# State file
jq -e '.LL-001.status == "pending"' .superpowers/state/story-progress.json > /dev/null || { echo "FAIL: LL-001 already processed"; exit 1; }

echo "PREFLIGHT PASS"
```

### Manual Prerequisites

Some prerequisites require human verification:

```markdown
## Manual Prerequisites for LL-001

- [ ] Claude Code has SQLite MCP access
- [ ] SKILL.md is the current version
- [ ] Goal directory path available (~/.mit-learning/)
```

---

## State Transitions

```
pending → ready (prerequisites validated)
ready → in-progress (execution started)
in-progress → passed (all criteria verified)
in-progress → failed (error or criteria not met)
failed → pending (rollback complete)
```

### Transition Commands

```bash
# Mark story as in-progress
jq '.LL-001.status = "in-progress" | .LL-001.startedAt = "'$(date -Iseconds)'"' \
  .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json

# Mark story as passed
jq '.LL-001.status = "passed" | .LL-001.completedAt = "'$(date -Iseconds)'"' \
  .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json

# Mark story as failed
jq '.LL-001.status = "failed"' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json
```

---

## Resume After Interruption

### Detection

When starting a story, check for existing state:

```bash
# Check if story was interrupted
STATUS=$(jq -r '.LL-001.status' .superpowers/state/story-progress.json)

if [ "$STATUS" = "in-progress" ]; then
  echo "Detected interrupted execution of LL-001"
  STARTED=$(jq -r '.LL-001.startedAt' .superpowers/state/story-progress.json)
  echo "Started at: $STARTED"

  if [ -f .superpowers/checkpoints/LL-001-START ]; then
    echo "Checkpoint found. Options:"
    echo "1. Resume from last step"
    echo "2. Rollback and restart"
    echo "3. Abort"
  fi
fi
```

---

## Dependency Checking

### Automated Dependency Validation

```bash
# Check if all dependencies for a story are met
check_dependencies() {
  STORY_ID=$1
  DEPENDENCIES=$(jq -r ".${STORY_ID}.dependencies[]" .superpowers/state/story-progress.json 2>/dev/null)

  for DEP in $DEPENDENCIES; do
    DEP_STATUS=$(jq -r ".${DEP}.status" .superpowers/state/story-progress.json)
    if [ "$DEP_STATUS" != "passed" ]; then
      echo "FAIL: Dependency $DEP not passed (status: $DEP_STATUS)"
      return 1
    fi
    echo "OK: Dependency $DEP passed"
  done

  return 0
}

# Usage
check_dependencies "LL-003" || exit 1
```

### Phase Completion Check

```bash
# Check if all Phase 1 stories passed
check_phase_complete() {
  PHASE=$1
  COUNT=$(jq "[.[] | select(.phase == ${PHASE} and .status == \"passed\")] | length" .superpowers/state/story-progress.json)
  EXPECTED=4  # Phase 1 has 4 stories

  if [ "$COUNT" -eq "$EXPECTED" ]; then
    echo "Phase ${PHASE} complete: ${COUNT}/${EXPECTED} stories passed"
    return 0
  else
    echo "Phase ${PHASE} incomplete: ${COUNT}/${EXPECTED} stories passed"
    return 1
  fi
}

# Usage
check_phase_complete 1 || { echo "Cannot start Phase 2"; exit 1; }
```

---

## Session Context

```json
// .superpowers/state/session-context.json
{
  "sessionId": "uuid-here",
  "startedAt": "2026-09-03T10:00:00Z",
  "currentPhase": 1,
  "currentStory": "LL-001",
  "lastActivity": "2026-09-03T12:30:00Z",
  "mode": "execution",
  "notes": "Running Phase 1 stories sequentially"
}
```

---

## Utility Functions

### Initialize State

```bash
# Run once at project start
init_state() {
  mkdir -p .superpowers/state .superpowers/checkpoints .superpowers/worktrees

  # Initialize empty state
  echo '{}' > .superpowers/state/story-progress.json

  echo "State initialized"
}
```

### Update State After Story

```bash
update_story_state() {
  STORY_ID=$1
  STATUS=$2

  jq --arg status "$STATUS" \
     --arg completed "$(date -Iseconds)" \
     ".${STORY_ID}.status = \$status | .${STORY_ID}.completedAt = \$completed" \
     .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json

  echo "Updated ${STORY_ID} to ${STATUS}"
}
```

### Generate Progress Report

```bash
progress_report() {
  echo "# Progress Report"
  echo "Generated: $(date)"
  echo ""

  for PHASE in 1 2 3; do
    PASSED=$(jq "[.[] | select(.phase == ${PHASE} and .status == \"passed\")] | length" .superpowers/state/story-progress.json)
    TOTAL=$(jq "[.[] | select(.phase == ${PHASE})] | length" .superpowers/state/story-progress.json)
    echo "Phase ${PHASE}: ${PASSED}/${TOTAL} passed"
  done
}
```

---

**State management enables reliable, resumable execution across all 12 stories.**
