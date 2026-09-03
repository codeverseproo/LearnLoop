# MIT Learning Skill - Master Execution Plan

> **For OMC orchestrator:** Execute stories in order. Each story has its own execution prompt in `docs/superpowers/prompts/MIT-XXX-execution.md`

**Goal:** Build world's most powerful learning skill using pure SQLite MCP + SKILL.md architecture (zero Python)

**Architecture:** Three-phase execution with 12 stories total

---

## Execution Order

### Phase 1: Foundation (Sequential)
Execute in order - each depends on prior.

| Story | Title | Prompt | Dependencies |
|-------|-------|--------|--------------|
| MIT-001 | Repository Setup | `docs/superpowers/prompts/MIT-001-execution.md` | None |
| MIT-002 | Schema via MCP | `docs/superpowers/prompts/MIT-002-execution.md` | MIT-001 |
| MIT-003 | FSRS Calculations | `docs/superpowers/prompts/MIT-003-execution.md` | MIT-002 |
| MIT-004 | Backup System | `docs/superpowers/prompts/MIT-004-execution.md` | MIT-003 |

### Phase 2: Workflows (Parallel after Phase 1)
Execute after MIT-004. Can run in parallel.

| Story | Title | Prompt | Dependencies |
|-------|-------|--------|--------------|
| MIT-005 | Learning Session | `docs/superpowers/prompts/MIT-005-execution.md` | MIT-004 |
| MIT-006 | Review Session | `docs/superpowers/prompts/MIT-006-execution.md` | MIT-004 |
| MIT-007 | Practice Workflow | `docs/superpowers/prompts/MIT-007-execution.md` | MIT-004 |
| MIT-008 | Research Workflow | `docs/superpowers/prompts/MIT-008-execution.md` | MIT-004 |
| MIT-009 | Streak System | `docs/superpowers/prompts/MIT-009-execution.md` | MIT-004 |

### Phase 3: Polish (Sequential)
Execute in order after Phase 2 complete.

| Story | Title | Prompt | Dependencies |
|-------|-------|--------|--------------|
| MIT-010 | Error Handling | `docs/superpowers/prompts/MIT-010-execution.md` | MIT-005 through MIT-009 |
| MIT-011 | Testing | `docs/superpowers/prompts/MIT-011-execution.md` | MIT-010 |
| MIT-012 | Python Deprecation | `docs/superpowers/prompts/MIT-012-execution.md` | MIT-011 |

---

## Global Constraints

1. **No Python scripts** - All logic in SKILL.md + SQL queries
2. **All data via SQLite MCP** - `mcp__sqlite__query` tool
3. **Test after each story** - Verify before commit
4. **Checkpoint files** - Store in `.superpowers/checkpoints/`
5. **State tracking** - Update `.superpowers/state/story-progress.json`

---

## Execution Prompts

Each story has a complete execution prompt with:
- Metadata (ID, phase, effort, dependencies)
- Preflight checks
- State initialization
- Implementation steps
- Testing & verification
- Human verification
- Success criteria
- Cleanup & commit
- Rollback script

---

## Start

Begin with MIT-001: Repository Setup

```bash
# Read the execution prompt
Read docs/superpowers/prompts/MIT-001-execution.md

# Execute following the prompt's steps
# Then proceed to MIT-002, etc.
```
