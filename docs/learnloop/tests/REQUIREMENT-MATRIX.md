# LearnLoop Requirement Matrix

**Purpose:** Every claim in README/SKILL has an executable proof.

**Test Philosophy:**
- User-facing tests (FSRS, budget, resume, multi-goal): **Zero token cost** (SQL-only)
- Dev/plumbing tests (agents, guards): Documented in markdown with manual verification steps

---

## Matrix: 12 Claims → Executable Proofs

| # | Claim | User Value | Executable Proof | Location | Status |
|---|-------|-----------|-----------------|----------|--------|
| 1 | **FSRS-6 calculations correct** | ✅ Direct | 4 SQL golden tests | `tests/unit/test_fsrs.sql` | ✅ PASS |
| 2 | **Budget stops spawning** | ✅ Direct | SQL integration test | `tests/integration/test_budget.sql` | 🚧 NEW |
| 3 | **Resume works** | ✅ Direct | SQL state recovery test | `tests/integration/test_resume.sql` | 🚧 NEW |
| 4 | **Multi-goal isolation** | ✅ Direct | SQL isolation test | `tests/integration/test_isolation.sql` | 🚧 NEW |
| 5 | **4 research agents spawn** | ⚠️ Dev | Manual orchestrator run + count | `tests/orchestrator-flow-tests.md` | ✅ Documented |
| 6 | **Real web search** | ⚠️ Dev | Source URL validator | `tests/validators/test_sources.sql` | 🚧 NEW |
| 7 | **Source URLs are real** | ⚠️ Dev | Same as #6 | — | — |
| 8 | **Claim triangulation** | ⚠️ Dev | DB query count check | `tests/integration/test_workflows.sql` | ✅ PASS |
| 9 | **Hidden-topic detection** | ⚠️ Dev | Fixture test | Manual (scenario-based) | 📝 TODO |
| 10 | **Critic rejects bad syllabus** | ⚠️ Dev | E2E flow test | `tests/orchestrator-flow-tests.md` | ✅ Documented |
| 11 | **Repair loop repairs** | ⚠️ Dev | E2E flow test | `tests/orchestrator-flow-tests.md` | ✅ PASS (Test 5) |
| 12 | **Obsidian output valid** | ⚠️ Dev | Markdown linter | Manual (OSS-specific) | 📝 TODO |

---

## Test Categories

### Category A: User-Facing (Zero Token Cost)

**Run locally with:**
```bash
sqlite3 ~/.learnloop/goals/{goal_id}/memory.db < tests/unit/test_fsrs.sql
sqlite3 ~/.learnloop/goals/{goal_id}/memory.db < tests/integration/test_budget.sql
sqlite3 ~/.learnloop/goals/{goal_id}/memory.db < tests/integration/test_resume.sql
sqlite3 ~/.learnloop/goals/{goal_id}/memory.db < tests/integration/test_isolation.sql
```

**Why SQL-only:**
- No agent spawning → zero tokens
- Instant verification (<1 second)
- User can run before/after any skill invocation
- Works offline

---

### Category B: Dev/Plumbing (Documented Proofs)

**Evidence in markdown:**
- Orchestrator flow tests (8 scenarios)
- guard/telemetry behavior
- Critic verdict handling
- Repair loop cycles

**Why documented:**
- Requires spawning agents (token cost)
- CI-only or manual verification
- Architecture claims, not user-visible behavior

---

## Success Criteria

**P0 (Must Pass):**
- [ ] All Category A tests PASS (4 SQL files)
- [ ] Zero script dependencies
- [ ] Tests run on user's machine without installation

**P1 (Should Pass):**
- [ ] Category B tests documented with manual steps
- [ ] Requirement matrix matches SKILL.md claims exactly

**P2 (Nice to Have):**
- [ ] Source URL validator (optional network check)
- [ ] Obsidian markdown linter hook

---

## Implementation Plan

### Phase 1: Expand SQL Tests (Est. 30 min)

1. Create `test_budget.sql` — verify budget limit enforcement
2. Create `test_resume.sql` — verify state recovery after crash
3. Create `test_isolation.sql` — verify multi-goal separation
4. Run all SQL tests against test database

### Phase 2: Document Dev Tests (Est. 20 min)

1. Add manual verification steps to `orchestrator-flow-tests.md`
2. Link each claim to test location in REQUIREMENT-MATRIX.md
3. Update SKILL.md to reference tests in "Verification" section

### Phase 3: CI Integration (Est. 15 min)

1. Add SQL test runner to `.github/workflows/test.yml`
2. Run tests on every PR
3. Fail CI if any Category A test fails

---

## Maintenance

**When adding new claims to SKILL.md:**
1. Add row to REQUIREMENT-MATRIX.md
2. Create executable proof (SQL test or documented scenario)
3. Link test location in matrix
4. Run CI verification

**Claim drift detection:**
- CI checks that REQUIREMENT-MATRIX.md claims match SKILL.md headers
- Missing claims → CI warning

---

## Metrics

| Metric | Target | Current |
|--------|--------|---------|
| User-facing tests | 4 | 1 ✅ + 3 🚧 |
| Dev tests documented | 5 | 5 ✅ |
| Zero token cost tests | 4 | 1 ✅ + 3 🚧 |
| Script dependencies | 0 | 0 ✅ |

---

**Last Updated:** 2026-09-05
**Status:** Phase 1 implementation ready
