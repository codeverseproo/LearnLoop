# Phase 3: Polish

**Timeline:** Week 3
**Stories:** 3 (MIT-010 through MIT-012)
**Goal:** Error handling, comprehensive testing, Python deprecation

---

## Phase Overview

Phase 3 hardens the system for production:

1. **Error Handling** — Graceful degradation via MCP queries
2. **Comprehensive Testing** — Full coverage of all workflows
3. **Python Deprecation** — Remove Python dependency completely

**Success Criteria (end of Phase 3):**
- All error paths handled
- 100% workflow coverage
- Zero Python scripts required
- README documents pure-skill architecture

---

## Dependency Map

```
Phase 3 stories are SEQUENTIAL (each validates the whole system):

MIT-010 (Error Handling) ───> MIT-011 (Testing) ───> MIT-012 (Python Deprecation)
        │                           │                        │
        └─ Try/catch in MCP        └─ Test coverage        └─ Remove scripts
```

**Execution order:** MIT-010 → MIT-011 → MIT-012

---

## Prerequisites

Before starting Phase 3:

- All Phase 2 stories passed (5/5)
- All 12 workflows functional via MCP
- SQLite databases operational
- Backup system tested

---

## Story Summaries

### MIT-010: Error Handling via MCP

**Impact:** Production-ready error handling

**What:** Implement comprehensive error handling:
- Schema validation errors
- FSRS parameter bounds checking
- Database connection failures
- Missing goal directory recovery
- Integrity constraint violations

**Files affected:**
- `docs/superpowers/mcp-queries/schema.sql` (CHECK constraints)
- `SKILL.md` (error handling section)
- Test fixtures for error cases

**Key acceptance criteria:**
- Invalid parameters rejected gracefully
- Database errors don't crash session
- Missing goals auto-created with warning
- Constraint violations return clear messages
- All error paths have MCP recovery queries

**Execution prompt:** [MIT-010-execution.md](prompts/MIT-010-execution.md)

---

### MIT-011: Comprehensive Testing

**Impact:** Confidence in all workflows

**What:** Create full test coverage:
- Unit tests for FSRS calculations
- Integration tests for each workflow
- Edge case testing
- Performance benchmarks
- Regression test suite

**Files affected:**
- `docs/superpowers/tests/` (new directory)
- Test fixtures and sample data
- Performance benchmarks

**Key acceptance criteria:**
- FSRS formulas match reference values
- All 12 workflows have integration tests
- Edge cases covered (empty queue, first topic, etc.)
- Performance < 5ms per query
- Test suite runnable via single command

**Execution prompt:** [MIT-011-execution.md](prompts/MIT-011-execution.md)

---

### MIT-012: Python Deprecation

**Impact:** Zero Python dependency

**What:** Remove all Python scripts:
- Archive (don't delete) Python scripts
- Update README to pure-skill architecture
- Document MCP query usage
- Remove Python from dependencies
- Verify all functionality works without Python

**Files affected:**
- `scripts/` (archive to `scripts/_deprecated/`)
- `README.md` (complete rewrite)
- `package.json` / `requirements.txt` (remove dependencies)

**Key acceptance criteria:**
- No Python scripts required
- README documents MCP-only approach
- All tests pass without Python
- Zero external dependencies
- Clean git history with deprecation commit

**Execution prompt:** [MIT-012-execution.md](prompts/MIT-012-execution.md)

---

## Testing Strategy

### Test Categories

| Category | Coverage Target | Tool |
|----------|-----------------|------|
| FSRS Calculations | 100% formulas | SQLite test db |
| Schema Operations | All tables | MCP query tests |
| Workflows | All 12 | Integration tests |
| Error Paths | All constraints | Error fixtures |
| Performance | <5ms/query | Benchmarks |

### Test Structure

```
docs/superpowers/tests/
├── unit/
│   ├── test_fsrs_calculations.sql    -- Retrievability, stability, mastery
│   ├── test_schema_constraints.sql    -- CHECK, foreign keys
│   └── test_streak_logic.sql          -- Increment, freeze, reset
├── integration/
│   ├── test_learning_workflow.sql     -- End-to-end learning session
│   ├── test_review_workflow.sql       -- Review queue + FSRS update
│   └── test_research_workflow.sql     -- Source storage + triangulation
├── edge-cases/
│   ├── test_empty_database.sql        -- First topic, empty queue
│   ├── test_boundary_values.sql       -- Stability bounds, day offsets
│   └── test_concurrent_access.sql     -- Multiple sessions
└── performance/
    └── benchmarks.sql                 -- Query timing <5ms
```

---

## Error Handling Matrix

| Error Type | Recovery Action | User Message |
|------------|-----------------|--------------|
| Missing database | Create schema via MCP | "Initialized new goal database" |
| Invalid FSRS params | Clamp to bounds | "Adjusted parameters to valid range" |
| Constraint violation | Rollback, report | "Operation conflicts with existing data" |
| Missing goal dir | Create directory | "Created goal directory structure" |
| Backup failure | Continue with warning | "Backup skipped, proceeding carefully" |

---

## Verification Checklist (End of Phase 3)

```bash
# 1. Error handling works
sqlite3 :memory: "SELECT * FROM nonexistent_table" 2>&1 | grep -q "no such table"

# 2. All tests pass
for test in docs/superpowers/tests/**/*.sql; do
  sqlite3 :memory: < "$test" || echo "FAIL: $test"
done

# 3. No Python required
grep -r "python" SKILL.md README.md || echo "Python references found"

# 4. Performance acceptable
time sqlite3 ~/.mit-learning/goals/test/memory.db < docs/superpowers/mcp-queries/fsrs.sql

# 5. State file shows all stories passed
jq '. | to_entries | map(select(.value.status == "passed")) | length' .superpowers/state/story-progress.json
# Should be 12

# 6. README updated
grep -q "SQLite MCP" README.md
grep -q "No Python required" README.md
```

---

## Final Deliverables

**After Phase 3 complete:**

1. **Architecture:**
   - 12 MCP query files in `docs/superpowers/mcp-queries/`
   - Zero Python dependencies
   - Pure SKILL.md implementation

2. **Documentation:**
   - README with pure-skill architecture
   - Inline query documentation
   - Workflow reference guide

3. **Testing:**
   - Full test suite
   - Performance benchmarks
   - Error handling verification

4. **State:**
   - All 12 stories passed
   - Clean git history
   - No deprecated code in active use

---

**Phase 3 complete. Project finished. Proceed to [Finishing](#final-deliverables).**
