# MIT Learning Skill — SQLite MCP Architecture Design

> **Design Goal:** Transform MIT Learning Skill into a pure skill-level system where ALL data operations go through SQLite MCP, eliminating Python script dependencies.

**Date:** 2026-09-03
**Status:** Design Spec (Pending Approval)
**Architecture:** Skill-Level + SQLite MCP + Obsidian

---

## 1. Executive Summary

Transform the MIT Learning Skill from Python-script-backed to **pure skill-level architecture**:

| Layer | Current State | Target State |
|-------|---------------|--------------|
| **Data Operations** | Python scripts (`scripts/*.py`) | SQLite MCP queries |
| **Business Logic** | Python functions | SKILL.md triggers + MCP |
| **Scheduling** | `fsrs_scheduler.py` | MCP SQL + skill formulas |
| **Mastery Tracking** | `mastery_update.py` | MCP transactions |
| **Validation** | `validation.py` | MCP constraints + skill guards |
| **Research** | `research_engine.py` | WebSearch skill + MCP storage |
| **Vault Operations** | `vault_manager.py` | Native filesystem tools |

**Result:** World's most powerful learning skill — natural language triggers driving everything through MCP, no Python intermediary.

---

## 2. Architecture Overview

### 2.1 Three-Tier Memory (Unchanged)

| Tier | Storage | Latency | Duration |
|------|---------|---------|----------|
| **HOT** | Session context (RAM) | 0ms | Session |
| **WARM** | SQLite via MCP (`~/.mit-learning/goals/{goal_id}/memory.db`) | 1-5ms | Permanent |
| **COLD** | Obsidian vault (`~/Obsidian/MIT-{goal-slug}/`) | 10-50ms | Permanent |

### 2.2 Key Change: SQLite MCP as Data Layer

**Before (Python-backed):**
```
User trigger → SKILL.md → Python script → SQLite → Return
```

**After (Pure MCP):**
```
User trigger → SKILL.md → SQLite MCP query → Return
```

### 2.3 Components

| Component | Implementation | File |
|-----------|----------------|------|
| **Intent Classification** | Natural language patterns in SKILL.md | `SKILL.md` §3 |
| **FSRS-6 Scheduler** | SQL formulas in MCP queries | `SKILL.md` §4 (MCP query templates) |
| **Mastery Tracking** | MCP UPDATE transactions | `SKILL.md` §5 |
| **Streak System** | MCP date arithmetic | `SKILL.md` §6 |
| **Research Workflow** | WebSearch + MCP storage | `SKILL.md` §7 |
| **Vault Operations** | Write tool (native) | `SKILL.md` §8 |
| **Validation** | MCP CHECK constraints + skill guards | `SKILL.md` §9 |

---

## 3. SQLite MCP Query Templates

### 3.1 Schema Initialization (MCP)

```sql
-- Goal database creation via MCP
-- Triggered by: "I want to learn X"

CREATE TABLE IF NOT EXISTS goal_meta (
    goal_id TEXT PRIMARY KEY,
    goal_type TEXT NOT NULL CHECK(goal_type IN ('exam', 'skill', 'degree', 'topic')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    vault_path TEXT,
    total_topics INTEGER DEFAULT 0,
    mastered_topics INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS topics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    mastery REAL DEFAULT 0.0 CHECK(mastery >= 0.0 AND mastery <= 1.0),
    status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'in_progress', 'mastered')),
    next_review DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS fsrs_state (
    topic_id INTEGER PRIMARY KEY,
    stability REAL DEFAULT 2.5 CHECK(stability >= 0.0 AND stability <= 365.0),
    difficulty REAL DEFAULT 5.0 CHECK(difficulty >= 1.0 AND difficulty <= 10.0),
    state INTEGER DEFAULT 0 CHECK(state IN (0, 1, 2, 3)),
    last_review TIMESTAMP,
    next_review TIMESTAMP,
    reviews INTEGER DEFAULT 0,
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);

-- Additional tables: sessions, prerequisites, note_registry, streak_state, achievements
-- Full schema in SKILL.md appendix
```

### 3.2 FSRS Calculations (MCP SQL)

```sql
-- Retrievability calculation: R(t, S) = (1 + t/(9*S))^(-1)
-- MCP query template for review queue

SELECT 
    t.topic_id,
    t.name,
    f.stability,
    f.difficulty,
    f.last_review,
    julianday('now') - julianday(f.last_review) AS days_since_review,
    POWER(1 + (julianday('now') - julianday(f.last_review)) / (9 * f.stability), -1) AS retrievability,
    POWER(1 + (julianday('now') - julianday(f.last_review)) / (9 * f.stability), -1) - 0.9 AS priority
FROM topics t
JOIN fsrs_state f ON t.id = f.topic_id
WHERE t.next_review <= date('now')
ORDER BY priority ASC
LIMIT 10;
```

### 3.3 Mastery Update (MCP Transaction)

```sql
-- After review session with performance rating
-- Triggered by: "Review completed" + performance input

BEGIN TRANSACTION;

UPDATE fsrs_state
SET 
    stability = CASE 
        WHEN :performance >= 0.6 THEN
            MIN(365.0, stability * (1 + (11 - difficulty) * 0.1 * (1 + (:performance - 0.6) * 2) * (1 + SQRT(stability)/10) * (0.5 + :retrievability)))
        ELSE
            stability * (0.5 + :performance * 0.5)
    END,
    difficulty = difficulty + (5 - difficulty) * 0.01 + (1 - :performance) * 0.2,
    state = CASE
        WHEN :performance >= 0.6 AND state = 1 THEN 2
        WHEN :performance < 0.6 AND state = 2 THEN 3
        WHEN :performance >= 0.6 AND state = 3 THEN 2
        ELSE state
    END,
    last_review = CURRENT_TIMESTAMP,
    next_review = datetime('now', '+' || CAST(stability AS INTEGER) || ' days'),
    reviews = reviews + 1
WHERE topic_id = :topic_id;

UPDATE topics
SET 
    mastery = 1 - EXP(-0.5 * (SELECT stability FROM fsrs_state WHERE topic_id = :topic_id) / 
                        (SELECT difficulty FROM fsrs_state WHERE topic_id = :topic_id)),
    status = CASE 
        WHEN mastery >= 0.9 THEN 'mastered'
        WHEN mastery > 0.0 THEN 'in_progress'
        ELSE 'pending'
    END,
    updated_at = CURRENT_TIMESTAMP
WHERE id = :topic_id;

INSERT INTO sessions (session_type, topic_id, performance, started_at, ended_at)
VALUES ('review', :topic_id, :performance, :started_at, CURRENT_TIMESTAMP);

COMMIT;
```

---

## 4. Skill-Level Workflow Triggers

### 4.1 Natural Language Triggers (50+)

All triggers remain in SKILL.md. The skill:
1. Parses intent via pattern matching
2. Executes MCP query templates
3. Returns results to user

**Example — Learning Session:**

```
Trigger: "Learn [topic]", "Teach me [subject]", "Start [topic]"

Skill Actions:
1. MCP: SELECT * FROM topics WHERE name LIKE :topic_pattern
2. If not found → MCP: INSERT INTO topics (name, ...) VALUES (...)
3. MCP: SELECT * FROM fsrs_state WHERE topic_id = :id
4. Present content (from Obsidian or generate)
5. Collect performance rating
6. MCP: UPDATE fsrs_state, topics (mastery update transaction)
7. MCP: INSERT INTO sessions (...)
```

**Example — Review Session:**

```
Trigger: "Review", "What's due", "Flashcards"

Skill Actions:
1. MCP: SELECT ... FROM topics JOIN fsrs_state (review queue query)
2. Present topics sorted by priority
3. For each topic:
   a. Load from Obsidian vault
   b. Present for review
   c. Collect performance rating
   d. MCP: UPDATE fsrs_state (mastery update)
4. MCP: UPDATE streak_state SET last_activity_date = date('now')
```

### 4.2 Research Workflow

```
Trigger: "Research [topic]", "Find sources on [subject]"

Skill Actions:
1. WebSearch: Academic sources (site:edu OR site:gov)
2. WebSearch: Official documentation
3. WebSearch: Broad web (blogs, tutorials)
4. Triangulate claims (≥3 sources)
5. MCP: INSERT INTO sources (goal_id, url, tier, ...)
6. Write: Obsidian note with compiled research
```

---

## 5. Migration Path

### 5.1 Phase 1: Create MCP Query Templates

- Extract all SQL from Python scripts
- Parameterize for skill-level execution
- Add to SKILL.md as query template section

### 5.2 Phase 2: Update SKILL.md Workflows

- Replace Python script calls with MCP queries
- Keep natural language triggers unchanged
- Add error handling via MCP error codes

### 5.3 Phase 3: Deprecate Python Scripts

- Keep scripts as reference (not executed)
- Add deprecation notices
- Eventually remove from repo

### 5.4 Phase 4: Testing

- Verify all workflows work via MCP
- Compare results with Python baseline
- Ensure data integrity

---

## 6. Error Handling (MCP-Based)

| Code | Error | MCP Response |
|------|-------|--------------|
| E001 | Duplicate goal | `ON CONFLICT` clause → graceful message |
| E002 | Invalid tolerance | CHECK constraint → error message |
| E003 | Goal limit | Application logic in skill → limit check |
| E004 | Invalid goal_id | CHECK constraint with REGEX → error |
| E101 | Topic not found | SELECT returns empty → friendly message |
| E201 | Invalid stability | CHECK constraint → error |
| E301 | Vault write failed | Filesystem tool error → retry logic |

---

## 7. Benefits of Pure Skill Architecture

| Aspect | Python Scripts | Skill + MCP |
|--------|----------------|-------------|
| **Dependencies** | Python runtime, packages | None (MCP built-in) |
| **Portability** |Requires Python env | Any Claude Code instance |
| **Speed** | Script startup overhead | Direct MCP queries |
| **Maintainability** | Two codebases (skill + scripts) | Single source of truth |
| **Extensibility** | Modify Python + skill | Modify SKILL.md only |
| **Debugging** | Script logs + MCP errors | MCP errors only |

---

## 8. Open Questions

1. **MCP Transaction Support:** Does SQLite MCP support multi-statement transactions?
   - If no, use BEGIN/COMMIT in single query or application-level transactions

2. **Complex Calculations:** Should FSRS formulas remain in SQL or move to skill logic?
   - SQL: Faster, single query
   - Skill: More readable, easier to debug

3. **Migration Strategy:** Keep Python scripts as fallback during transition?
   - Recommended: Yes, parallel operation for 1 version

---

## 9. Next Steps

1. ✅ Design spec documented
2. ⏳ User approval
3. ⏳ Invoke writing-plans for implementation plan
4. ⏳ Implement MCP query templates
5. ⏳ Migrate workflows
6. ⏳ Test against Python baseline
7. ⏳ Deprecate Python scripts

---

**Design Version:** 1.0.0
**Author:** Claude + User collaboration
**Approved:** ⏳ Pending user review
