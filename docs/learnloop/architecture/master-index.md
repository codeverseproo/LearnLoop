# LearnLoop — SQLite MCP Migration Architecture

**Version:** 1.0.0
**Status:** Ready for execution
**Total Stories:** 12 across 3 phases

---

## Quick Reference

| Phase | Stories | Timeline | Focus |
|-------|---------|----------|-------|
| Phase 1 | 4 | Week 1 | Foundation: MCP queries, schema migration, core workflows |
| Phase 2 | 5 | Week 2 | Workflows: Learning, review, practice, research triggers |
| Phase 3 | 3 | Week 3 | Polish: Error handling, testing, Python deprecation |

---

## Phase Documents

- [Phase 1: Foundation](phase-1-foundation.md) — MCP query templates, schema setup, core tables
- [Phase 2: Workflows](phase-2-workflows.md) — Learning, review, practice, research triggers
- [Phase 3: Polish](phase-3-polish.md) — Error handling, testing, Python removal

---

## Execution Prompts (12 Stories)

### Phase 1: Foundation (Week 1)

| ID | Title | Effort | Prompt |
|----|-------|--------|--------|
| LL-001 | SQLite MCP Query Templates | 2h | [LL-001-execution.md](prompts/LL-001-execution.md) |
| LL-002 | Schema Initialization via MCP | 3h | [LL-002-execution.md](prompts/LL-002-execution.md) |
| LL-003 | FSRS-6 Calculations in SQL | 4h | [LL-003-execution.md](prompts/LL-003-execution.md) |
| LL-004 | Backup System | 2h | [LL-004-execution.md](prompts/LL-004-execution.md) |

### Phase 2: Workflows (Week 2)

| ID | Title | Effort | Prompt |
|----|-------|--------|--------|
| LL-005 | Learning Session Workflow | 3h | [LL-005-execution.md](prompts/LL-005-execution.md) |
| LL-006 | Review Session Workflow | 3h | [LL-006-execution.md](prompts/LL-006-execution.md) |
| LL-007 | Practice Session Workflow | 2h | [LL-007-execution.md](prompts/LL-007-execution.md) |
| LL-008 | Research Workflow | 4h | [LL-008-execution.md](prompts/LL-008-execution.md) |
| LL-009 | Streak & Achievement System | 3h | [LL-009-execution.md](prompts/LL-009-execution.md) |

### Phase 3: Polish (Week 3)

| ID | Title | Effort | Prompt |
|----|-------|--------|--------|
| LL-010 | Error Handling via MCP | 3h | [LL-010-execution.md](prompts/LL-010-execution.md) |
| LL-011 | Comprehensive Testing | 4h | [LL-011-execution.md](prompts/LL-011-execution.md) |
| LL-012 | Python Deprecation | 2h | [LL-012-execution.md](prompts/LL-012-execution.md) |

---

## Dependency Graph

```
Phase 1 (sequential dependencies):
LL-001 (MCP Templates) ────────┐
LL-002 (Schema Init) ──────────┤
LL-003 (FSRS SQL) ─────────────┼──> Must complete in order
LL-004 (Backup) ───────────────┘

Phase 2 (depends on Phase 1, can run in parallel after LL-004):
├── LL-005 (Learning) ─────────┐
├── LL-006 (Review) ───────────┤
├── LL-007 (Practice) ─────────┼──> Parallel execution OK
├── LL-008 (Research) ─────────┤
└── LL-009 (Streaks) ──────────┘

Phase 3 (depends on Phase 2):
├── LL-010 (Error Handling)
│   └── Requires: All Phase 2 workflows
├── LL-011 (Testing)
│   └── Requires: LL-010
└── LL-012 (Python Deprecation)
    └── Requires: LL-011 (all tests passing)
```

---

## State Management

**File:** `.superpowers/state/story-progress.json`

Tracks completion state for all 12 stories:

```json
{
  "LL-001": {
    "status": "passed",
    "startedAt": "2026-09-03T12:00:00Z",
    "completedAt": "2026-09-03T14:00:00Z",
    "webVitals": { "mcpQueryLatency": "<5ms" },
    "signedOffBy": "human",
    "checkpoint": ".superpowers/checkpoints/LL-001-PASS"
  }
}
```

**Checkpoint files:**
- `LL-XXX-START` — Pre-execution snapshot (for rollback)
- `LL-XXX-PASS` — Success marker (dependency for subsequent stories)
- `LL-XXX-rollback.sh` — Generated rollback script

---

## How to Execute

### Single Story Execution

1. Read the execution prompt: `prompts/LL-XXX-execution.md`
2. Copy the entire prompt content
3. Paste into a fresh Claude session
4. Claude will:
   - Run preflight checks
   - Create worktree isolation
   - Execute micro-steps
   - Run verification
   - Request human sign-off
   - Merge and cleanup on success

### Parallel Execution (Phase Level)

Stories in same phase can run in parallel (see dependency graph):
1. Start multiple Claude sessions
2. Each session executes one story from the phase
3. Monitor `.superpowers/state/story-progress.json`
4. Proceed to next phase when all phase stories pass

### Resume After Interruption

1. Check `.superpowers/state/story-progress.json` for last completed step
2. Re-run the same execution prompt
3. Prompt will detect existing checkpoint and resume

### Rollback Failed Story

1. Execute rollback script: `bash .superpowers/checkpoints/LL-XXX-rollback.sh`
2. Delete worktree: `git worktree remove .superpowers/worktrees/LL-XXX`
3. Story state resets to `pending`

---

## Prerequisites (Global)

Before starting any story:

**Environment:**
- Claude Code CLI installed
- SQLite MCP available (`mcp__sqlite__*` tools)
- Git 2.30+ (`git --version`)

**Skill Files:**
- `SKILL.md` exists at repo root
- `docs/` directory for documentation
- Obsidian vault path configured (optional)

**Access:**
- Write access to repo
- SQLite MCP permissions

---

## Performance Targets

| Metric | Baseline (Python) | Target (MCP) | Stories Improving |
|--------|-------------------|--------------|-------------------|
| Query Latency | 50-100ms (script startup) | <5ms | LL-001, LL-002 |
| Dependencies | Python runtime + packages | None | LL-012 |
| Portability | Requires Python env | Any Claude instance | All |
| Maintainability | Two codebases | Single SKILL.md | All |

---

## Success Metrics

**After Phase 1 (Week 1):**
- [ ] MCP query templates working
- [ ] SQLite schema created via MCP
- [ ] FSRS-6 calculations in SQL
- [ ] Backup system functional

**After Phase 2 (Week 2):**
- [ ] All 12 workflows use MCP
- [ ] Learning sessions tracked
- [ ] Review queue queries working
- [ ] Research saved to SQLite

**After Phase 3 (Week 3):**
- [ ] All tests passing
- [ ] Python scripts deprecated
- [ ] Zero dependencies
- [ ] README updated

---

## Architecture Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-09-03 | Initial architecture created |

---

**Ready to execute.** Start with [LL-001-execution.md](prompts/LL-001-execution.md).
