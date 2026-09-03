# MIT Learning Skill — SQLite MCP Migration Architecture

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
| MIT-001 | SQLite MCP Query Templates | 2h | [MIT-001-execution.md](prompts/MIT-001-execution.md) |
| MIT-002 | Schema Initialization via MCP | 3h | [MIT-002-execution.md](prompts/MIT-002-execution.md) |
| MIT-003 | FSRS-6 Calculations in SQL | 4h | [MIT-003-execution.md](prompts/MIT-003-execution.md) |
| MIT-004 | Backup System | 2h | [MIT-004-execution.md](prompts/MIT-004-execution.md) |

### Phase 2: Workflows (Week 2)

| ID | Title | Effort | Prompt |
|----|-------|--------|--------|
| MIT-005 | Learning Session Workflow | 3h | [MIT-005-execution.md](prompts/MIT-005-execution.md) |
| MIT-006 | Review Session Workflow | 3h | [MIT-006-execution.md](prompts/MIT-006-execution.md) |
| MIT-007 | Practice Session Workflow | 2h | [MIT-007-execution.md](prompts/MIT-007-execution.md) |
| MIT-008 | Research Workflow | 4h | [MIT-008-execution.md](prompts/MIT-008-execution.md) |
| MIT-009 | Streak & Achievement System | 3h | [MIT-009-execution.md](prompts/MIT-009-execution.md) |

### Phase 3: Polish (Week 3)

| ID | Title | Effort | Prompt |
|----|-------|--------|--------|
| MIT-010 | Error Handling via MCP | 3h | [MIT-010-execution.md](prompts/MIT-010-execution.md) |
| MIT-011 | Comprehensive Testing | 4h | [MIT-011-execution.md](prompts/MIT-011-execution.md) |
| MIT-012 | Python Deprecation | 2h | [MIT-012-execution.md](prompts/MIT-012-execution.md) |

---

## Dependency Graph

```
Phase 1 (sequential dependencies):
MIT-001 (MCP Templates) ────────┐
MIT-002 (Schema Init) ──────────┤
MIT-003 (FSRS SQL) ─────────────┼──> Must complete in order
MIT-004 (Backup) ───────────────┘

Phase 2 (depends on Phase 1, can run in parallel after MIT-004):
├── MIT-005 (Learning) ─────────┐
├── MIT-006 (Review) ───────────┤
├── MIT-007 (Practice) ─────────┼──> Parallel execution OK
├── MIT-008 (Research) ─────────┤
└── MIT-009 (Streaks) ──────────┘

Phase 3 (depends on Phase 2):
├── MIT-010 (Error Handling)
│   └── Requires: All Phase 2 workflows
├── MIT-011 (Testing)
│   └── Requires: MIT-010
└── MIT-012 (Python Deprecation)
    └── Requires: MIT-011 (all tests passing)
```

---

## State Management

**File:** `.superpowers/state/story-progress.json`

Tracks completion state for all 12 stories:

```json
{
  "MIT-001": {
    "status": "passed",
    "startedAt": "2026-09-03T12:00:00Z",
    "completedAt": "2026-09-03T14:00:00Z",
    "webVitals": { "mcpQueryLatency": "<5ms" },
    "signedOffBy": "human",
    "checkpoint": ".superpowers/checkpoints/MIT-001-PASS"
  }
}
```

**Checkpoint files:**
- `MIT-XXX-START` — Pre-execution snapshot (for rollback)
- `MIT-XXX-PASS` — Success marker (dependency for subsequent stories)
- `MIT-XXX-rollback.sh` — Generated rollback script

---

## How to Execute

### Single Story Execution

1. Read the execution prompt: `prompts/MIT-XXX-execution.md`
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

1. Execute rollback script: `bash .superpowers/checkpoints/MIT-XXX-rollback.sh`
2. Delete worktree: `git worktree remove .superpowers/worktrees/MIT-XXX`
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
| Query Latency | 50-100ms (script startup) | <5ms | MIT-001, MIT-002 |
| Dependencies | Python runtime + packages | None | MIT-012 |
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

**Ready to execute.** Start with [MIT-001-execution.md](prompts/MIT-001-execution.md).
