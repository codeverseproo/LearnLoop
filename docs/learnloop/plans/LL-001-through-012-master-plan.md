# MIT Learning Skill - Master Execution Plan

> **For OMC orchestrator:** Execute stories in order. Each story has its own execution prompt in `docs/learnloop/prompts/LL-XXX-execution.md`

**Goal:** Build world's most powerful learning skill using pure SQLite MCP + SKILL.md architecture (zero Python)

**Architecture:** Three-phase execution with 12 stories total

---

## Execution Order

### Phase 1: Foundation (Sequential)
Execute in order - each depends on prior.

| Story | Title | Prompt | Dependencies |
|-------|-------|--------|--------------|
| LL-001 | Repository Setup | `docs/learnloop/prompts/LL-001-execution.md` | None |
| LL-002 | Schema via MCP | `docs/learnloop/prompts/LL-002-execution.md` | LL-001 |
| LL-003 | FSRS Calculations | `docs/learnloop/prompts/LL-003-execution.md` | LL-002 |
| LL-004 | Backup System | `docs/learnloop/prompts/LL-004-execution.md` | LL-003 |

### Phase 2: Workflows (Parallel after Phase 1)
Execute after LL-004. Can run in parallel.

| Story | Title | Prompt | Dependencies |
|-------|-------|--------|--------------|
| LL-005 | Learning Session | `docs/learnloop/prompts/LL-005-execution.md` | LL-004 |
| LL-006 | Review Session | `docs/learnloop/prompts/LL-006-execution.md` | LL-004 |
| LL-007 | Practice Workflow | `docs/learnloop/prompts/LL-007-execution.md` | LL-004 |
| LL-008 | Research Workflow | `docs/learnloop/prompts/LL-008-execution.md` | LL-004 |
| LL-009 | Streak System | `docs/learnloop/prompts/LL-009-execution.md` | LL-004 |

### Phase 3: Polish (Sequential)
Execute in order after Phase 2 complete.

| Story | Title | Prompt | Dependencies |
|-------|-------|--------|--------------|
| LL-010 | Error Handling | `docs/learnloop/prompts/LL-010-execution.md` | LL-005 through LL-009 |
| LL-011 | Testing | `docs/learnloop/prompts/LL-011-execution.md` | LL-010 |
| LL-012 | Python Deprecation | `docs/learnloop/prompts/LL-012-execution.md` | LL-011 |

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

Begin with LL-001: Repository Setup

```bash
# Read the execution prompt
Read docs/learnloop/prompts/LL-001-execution.md

# Execute following the prompt's steps
# Then proceed to LL-002, etc.
```
