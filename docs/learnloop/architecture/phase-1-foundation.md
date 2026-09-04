# Phase 1: Foundation

**Timeline:** Week 1
**Stories:** 4 (LL-001 through LL-004)
**Goal:** Establish SQLite MCP query infrastructure, schema, FSRS-6 calculations, and backup system

---

## Phase Overview

Phase 1 creates the foundation for pure skill-level architecture:

1. **MCP Query Templates** — SQL files for all data operations
2. **Schema Initialization** — Database creation via MCP
3. **FSRS-6 Calculations** — Spaced repetition formulas in SQL
4. **Backup System** — Data safety before any operations

**Success Criteria (end of Phase 1):**
- All MCP query templates functional
- Schema creates database via MCP
- FSRS-6 calculations return correct values
- Backup/restore working

---

## Dependency Map

```
Phase 1 stories are SEQUENTIAL (each depends on previous):

LL-001 (MCP Templates) ───> LL-002 (Schema) ───> LL-003 (FSRS) ───> LL-004 (Backup)
     │                            │                      │                    │
     └─ Creates SQL files         └─ Uses templates     └─ Extends fsrs.sql   └─ Uses all
```

**Execution order:** LL-001 → LL-002 → LL-003 → LL-004

---

## Shared Prerequisites

Before starting any Phase 1 story:

### Environment Setup

```bash
# Git version
git --version  # Should be 2.30+

# SQLite available (for local testing)
sqlite3 --version

# State directory
mkdir -p .superpowers/state .superpowers/checkpoints .superpowers/worktrees

# Initialize state file
test -f .superpowers/state/story-progress.json || echo '{}' > .superpowers/state/story-progress.json
```

### MCP Access

```markdown
Verify Claude Code has SQLite MCP tools:
- mcp__sqlite__query
- mcp__sqlite__execute
```

---

## Story Summaries

### LL-001: SQLite MCP Query Templates

**Impact:** Foundation for all data operations — eliminates Python dependency

**What:** Create comprehensive SQL query templates:
- 8 SQL files (schema, fsrs, learning, review, practice, research, streak, backup)
- Parameterized queries for MCP execution
- README documenting structure

**Files affected:**
- `docs/learnloop/mcp-queries/` (new directory)
- `SKILL.md` (add MCP section)

**Key acceptance criteria:**
- 8 SQL files created
- README documents each file's purpose
- Schema has all 8 tables with CHECK constraints
- FSRS has retrievability calculation
- SKILL.md references MCP queries

**Execution prompt:** [LL-001-execution.md](prompts/LL-001-execution.md)

---

### LL-002: Schema Initialization via MCP

**Impact:** Database creation without Python scripts

**What:** Implement goal database initialization:
- Execute schema.sql via MCP
- Create goal directory structure
- Initialize streak_state
- Test against Python baseline

**Files affected:**
- `SKILL.md` (syllabus_generation workflow updates)
- `docs/learnloop/mcp-queries/schema.sql` (execution)

**Key acceptance criteria:**
- Database created via MCP
- All 8 tables exist
- CHECK constraints enforced
- Streak initialized correctly
- Matches Python script output

**Execution prompt:** [LL-002-execution.md](prompts/LL-002-execution.md)

---

### LL-003: FSRS-6 Calculations in SQL

**Impact:** Spaced repetition without Python scheduler

**What:** Implement FSRS-6 formulas:
- Retrievability calculation
- Stability update (success/failure)
- Difficulty adjustment
- Mastery score calculation
- Interval scheduling

**Files affected:**
- `docs/learnloop/mcp-queries/fsrs.sql` (expansion)
- `SKILL.md` (review_session workflow updates)

**Key acceptance criteria:**
- Retrievability matches Python: `R = (1 + t/(9*S))^(-1)`
- Stability update matches Python formulas
- Mastery score: `1 - exp(-0.5 * S / D)`
- State machine transitions correctly
- Test vectors pass

**Execution prompt:** [LL-003-execution.md](prompts/LL-003-execution.md)

---

### LL-004: Backup System

**Impact:** Data safety for accidental losses

**What:** Implement backup operations:
- Automatic backup before schema changes
- Daily backup option
- Export to Obsidian vault
- Restore procedure

**Files affected:**
- `docs/learnloop/mcp-queries/backup.sql` (new)
- `SKILL.md` (add backup triggers)

**Key acceptance criteria:**
- Backup created before schema migration
- Backup file named with timestamp
- Restore procedure documented
- Integrity check after restore

**Execution prompt:** [LL-004-execution.md](prompts/LL-004-execution.md)

---

## Cross-Story Considerations

### Query File Dependencies

- **LL-001** creates all query templates (foundation)
- **LL-002** executes schema.sql
- **LL-003** extends fsrs.sql with calculations
- **LL-004** creates backup.sql

### MCP Testing

Each story should test queries against a test database:

```bash
# Create test database
sqlite3 ~/.mit-learning/goals/test/memory.db < docs/learnloop/mcp-queries/schema.sql

# Run verification query
sqlite3 ~/.mit-learning/goals/test/memory.db "SELECT name FROM sqlite_master WHERE type='table'"

# Clean up
rm -rf ~/.mit-learning/goals/test
```

---

## Verification Checklist (End of Phase 1)

```bash
# 1. All query files exist
ls docs/learnloop/mcp-queries/*.sql | wc -l  # Should be 8

# 2. Schema creates database without errors
sqlite3 :memory: < docs/learnloop/mcp-queries/schema.sql

# 3. FSRS calculations present
grep -q "retrievability" docs/learnloop/mcp-queries/fsrs.sql
grep -q "stability" docs/learnloop/mcp-queries/fsrs.sql

# 4. Backup queries exist
grep -q "backup" docs/learnloop/mcp-queries/backup.sql

# 5. SKILL.md updated
grep -q "MCP Query Templates" SKILL.md

# 6. State file shows Phase 1 complete
jq '. | to_entries | map(select(.value.phase == 1 and .value.status == "passed")) | length' .superpowers/state/story-progress.json
# Should be 4
```

---

**Phase 1 complete. Proceed to [Phase 2: Workflows](phase-2-workflows.md).**
