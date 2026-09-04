# Phase 2: Workflows

**Timeline:** Week 2
**Stories:** 5 (LL-005 through LL-009)
**Goal:** Implement all 12 learning workflows using MCP queries

---

## Phase Overview

Phase 2 implements the core learning workflows:

1. **Learning Session** — Topic learning with FSRS tracking
2. **Review Session** — Spaced repetition review queue
3. **Practice Session** — Problem practice with performance tracking
4. **Research Workflow** — Layered research with claim triangulation
5. **Streak & Achievements** — Gamification system

**Success Criteria (end of Phase 2):**
- All 12 workflows use MCP queries
- Learning sessions tracked in SQLite
- Review queue prioritizes by retrievability
- Research saved to SQLite + Obsidian
- Streaks increment correctly

---

## Dependency Map

```
Phase 2 stories can run IN PARALLEL (all depend on Phase 1, not each other):

LL-005 (Learning) ────┐
LL-006 (Review) ──────┼──> Can execute simultaneously
LL-007 (Practice) ────┤
LL-008 (Research) ────┤
LL-009 (Streaks) ─────┘

All require: LL-004 (Phase 1 complete)
```

**Execution:** Any order, can run 5 parallel sessions

---

## Story Summaries

### LL-005: Learning Session Workflow

**Impact:** Core learning functionality via pure MCP

**What:** Implement learning_session workflow:
- Topic creation via MCP
- FSRS state initialization
- Session start/end tracking
- Mastery update after session

**Files affected:**
- `SKILL.md` (learning_session workflow)
- `docs/learnloop/mcp-queries/learning.sql` (execution)

**Key acceptance criteria:**
- New topic creates fsrs_state entry
- Session recorded with performance
- Mastery calculated correctly
- Works via natural language trigger

**Execution prompt:** [LL-005-execution.md](prompts/LL-005-execution.md)

---

### LL-006: Review Session Workflow

**Impact:** Spaced repetition without Python scheduler

**What:** Implement review_session workflow:
- Review queue query (overdue topics)
- Priority sorting by retrievability
- Performance rating collection
- FSRS state update
- Streak increment

**Files affected:**
- `SKILL.md` (review_session workflow)
- `docs/learnloop/mcp-queries/review.sql` (new/expansion)

**Key acceptance criteria:**
- Queue returns topics WHERE next_review <= today
- Priority = retrievability - 0.9
- Performance updates fsrs_state
- Session recorded
- Streak increments on activity

**Execution prompt:** [LL-006-execution.md](prompts/LL-006-execution.md)

---

### LL-007: Practice Session Workflow

**Impact:** Practice problem tracking via MCP

**What:** Implement practice_session workflow:
- Topic selection
- Performance tracking
- Mastery update
- Interleaved practice support

**Files affected:**
- `SKILL.md` (practice_session, interleaved_practice workflows)
- `docs/learnloop/mcp-queries/practice.sql` (new)

**Key acceptance criteria:**
- Practice session creates session record
- Performance updates mastery
- Interleaved practice selects multiple topics
- Cross-topic interference tracked

**Execution prompt:** [LL-007-execution.md](prompts/LL-007-execution.md)

---

### LL-008: Research Workflow

**Impact:** Research compilation saved to SQLite

**What:** Implement research workflow:
- WebSearch for sources
- Source storage in SQLite
- Claim triangulation (≥3 sources)
- Note creation in Obsidian

**Files affected:**
- `SKILL.md` (research triggers)
- `docs/learnloop/mcp-queries/research.sql` (new)
- Source tables in schema

**Key acceptance criteria:**
- Sources stored in SQLite
- Claims require ≥3 sources
- Confidence score calculated
- Note written to Obsidian vault

**Execution prompt:** [LL-008-execution.md](prompts/LL-008-execution.md)

---

### LL-009: Streak & Achievement System

**Impact:** Gamification via MCP

**What:** Implement streak and achievement tracking:
- Daily activity detection
- Streak increment logic
- Streak freeze mechanic
- Achievement unlock conditions

**Files affected:**
- `SKILL.md` (streak triggers)
- `docs/learnloop/mcp-queries/streak.sql` (expansion)

**Key acceptance criteria:**
- Streak increments on daily activity
- Streak freezes available (1 per goal)
- Achievements unlock correctly
- Streak reset on missed day (unless frozen)

**Execution prompt:** [LL-009-execution.md](prompts/LL-009-execution.md)

---

## Workflow Mapping

| Workflow | MCP Queries Used |
|----------|------------------|
| syllabus_generation | schema.sql, learning.sql |
| diagnostic_assessment | learning.sql, practice.sql |
| study_schedule_optimization | review.sql |
| learning_session | learning.sql, fsrs.sql |
| prior_knowledge_activation | learning.sql |
| metacognitive_reflection | learning.sql |
| review_session | review.sql, fsrs.sql, streak.sql |
| elaborative_interrogation | learning.sql |
| practice_session | practice.sql, fsrs.sql |
| interleaved_practice | practice.sql |
| progress_dashboard | streak.sql, review.sql |
| current_affairs_digest | research.sql |

---

## Testing Strategy

Each workflow should have test scenarios:

```markdown
### Learning Session Test
1. Trigger: "Learn Python basics"
2. Verify: Topic created in SQLite
3. Verify: fsrs_state initialized
4. Complete session with performance 0.8
5. Verify: Mastery updated correctly

### Review Session Test
1. Create due topics (manipulate next_review dates)
2. Trigger: "What's due for review"
3. Verify: Queue returns due topics
4. Verify: Priority ordering correct
5. Complete review, verify FSRS update

### Streak Test
1. Trigger: Activity on day 1
2. Verify: current_streak = 1
3. Trigger: Activity on day 2
4. Verify: current_streak = 2
5. Skip day 3, verify streak reset
```

---

## Verification Checklist (End of Phase 2)

```bash
# 1. All workflow queries exist
grep -l "learning" docs/learnloop/mcp-queries/*.sql
grep -l "review" docs/learnloop/mcp-queries/*.sql
grep -l "practice" docs/learnloop/mcp-queries/*.sql
grep -l "streak" docs/learnloop/mcp-queries/*.sql

# 2. Test database with sample data
sqlite3 ~/.mit-learning/goals/test/memory.db < docs/learnloop/mcp-queries/schema.sql
sqlite3 ~/.mit-learning/goals/test/memory.db "INSERT INTO topics (topic_id, name) VALUES ('T01-test', 'Test Topic')"

# 3. Verify FSRS update works
sqlite3 ~/.mit-learning/goals/test/memory.db < docs/learnloop/mcp-queries/fsrs.sql

# 4. State file shows Phase 2 complete
jq '. | to_entries | map(select(.value.phase == 2 and .value.status == "passed")) | length' .superpowers/state/story-progress.json
# Should be 5
```

---

**Phase 2 complete. Proceed to [Phase 3: Polish](phase-3-polish.md).**
