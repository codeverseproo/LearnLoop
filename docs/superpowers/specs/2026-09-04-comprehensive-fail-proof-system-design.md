# LearnLoop Comprehensive Fail-Proof System Design

**Date:** 2026-09-04  
**Goal:** Complete system overhaul covering all 12 workflows, database architecture, vault organization, and research methodology  

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Database Architecture](#database-architecture)
3. [All 12 Workflows - End-to-End Verification](#all-12-workflows)
4. [Output Organization - Vault Structure](#vault-structure)
5. [Research Methodology - Layered Approach](#research-methodology)
6. [Implementation Roadmap](#implementation-roadmap)

---

## Executive Summary

**Current State Analysis (from session transcript):**

- **Database Created:** `memory.db` exists with topics/prerequisites
- **Missing:** Interview data in `goal_meta` table
- **Missing:** Research metadata tracking
- **Missing:** 4 discovery agents (spawned 21 generic instead)
- **Missing:** Satisfaction criteria verification
- **Missing:** Vault organization enforcement

**Root Causes:**

1. **No agent definitions** - Prompts exist but not registered agents
2. **No phase gates** - Steps can be skipped without detection
3. **Incomplete schema** - Missing interview fields in `goal_meta`
4. **No vault guards** - Output location not enforced
5. **No verification queries** - Satisfaction criteria not executed

**Solution: 5-Component Fail-Proof System**

```
┌─────────────────────────────────────────────────────────────┐
│ COMPONENT 5: OUTPUT ORGANIZATION                            │
│ - Vault structure enforcement                               │
│ - Naming conventions                                         │
│ - Folder hierarchy validation                                │
└─────────────────────────────────────────────────────────────┘
                          ↑
┌─────────────────────────────────────────────────────────────┐
│ COMPONENT 4: ALL-12 WORKFLOW GATES                          │
│ - Each workflow has entry/exit criteria                     │
│ - State transitions verified                                 │
│ - Cross-workflow dependencies tracked                        │
└─────────────────────────────────────────────────────────────┘
                          ↑
┌─────────────────────────────────────────────────────────────┐
│ COMPONENT 3: DATABASE ARCHITECTURE                           │
│ - Complete schema with interview data                        │
│ - Migration scripts                                          │
│ - Integrity checks                                            │
│ - Backup/restore protocols                                    │
└─────────────────────────────────────────────────────────────┘
                          ↑
┌─────────────────────────────────────────────────────────────┐
│ COMPONENT 2: SELF-HEALING EXECUTION                          │
│ - Retry logic (max 3 per phase)                              │
│ - Auto-recovery from common failures                         │
│ - Clear error messages with fix suggestions                  │
└─────────────────────────────────────────────────────────────┘
                          ↑
┌─────────────────────────────────────────────────────────────┐
│ COMPONENT 1: AGENT REGISTRY + PHASE GATES                    │
│ - 4 discovery agents registered                               │
│ - Critic agent registered                                     │
│ - SQL verification between phases                            │
└─────────────────────────────────────────────────────────────┘
```

---

## Database Architecture

### Problem: Where to Store Database?

**Current:** `~/.learnloop/goals/{goal_id}/memory.db`

**Issue:** Working directory was `/Users/codeversepro/Documents/Syllabus/` (user's cwd)

**Solution:** Enforce database location at skill invocation

### Database Location Guard

Add to SKILL.md **Pre-Flight Validation**:

```markdown
## Pre-Flight: Database Location

**BEFORE any execution:**

1. **Generate goal_id** from user input
2. **Create directory if not exists:**
   ```bash
   mkdir -p ~/.learnloop/goals/{goal_id}
   ```
3. **Change working directory:**
   ```bash
   cd ~/.learnloop/goals/{goal_id}
   ```
4. **Verify location:**
   ```bash
   pwd  # Should output: /Users/{user}/.learnloop/goals/{goal_id}
   ```
5. **Proceed with execution in this directory**

**Violation:** If cwd != `~/.learnloop/goals/{goal_id}/` → STOP with error:
> "Working directory must be ~/.learnloop/goals/{goal_id}/. Current: {cwd}. Run 'cd ~/.learnloop/goals/{goal_id}' first."
```

### Schema Enhancements

**Missing tables/columns identified:**

| Current Schema | Missing | Purpose |
|----------------|---------|---------|
| `goal_meta` | `baseline`, `timeline`, `daily_availability`, `interview_complete`, `onboarding_complete` | Interview data persistence |
| `execution_state` | Entire table | Retry tracking, phase progression |
| `user_profile` | Entire table | Global user preferences (onboarding data) |
| `note_templates` | Entire table | Obsidian note templates |
| `workflow_dependencies` | Entire table | Cross-workflow prerequisites |

### Complete Schema Migration

**File: `docs/learnloop/mcp-queries/migrations/005-comprehensive-schema.sql`**

```sql
-- ============================================
-- Migration: Comprehensive Schema Update
-- ============================================

-- 1. Add interview fields to goal_meta
ALTER TABLE goal_meta ADD COLUMN baseline TEXT;
ALTER TABLE goal_meta ADD COLUMN timeline_weeks INTEGER;
ALTER TABLE goal_meta ADD COLUMN daily_availability_hours REAL;
ALTER TABLE goal_meta ADD COLUMN interview_complete INTEGER DEFAULT 0;
ALTER TABLE goal_meta ADD COLUMN onboarding_complete INTEGER DEFAULT 0;
ALTER TABLE goal_meta ADD COLUMN goal_profile_json TEXT;
ALTER TABLE goal_meta ADD COLUMN user_id TEXT;

-- 2. Add user profile table (global preferences)
CREATE TABLE IF NOT EXISTS user_profile (
    user_id TEXT PRIMARY KEY,
    name TEXT,
    onboarding_complete INTEGER DEFAULT 0,
    availability_json TEXT,
    learning_style_json TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Add execution state table (retry tracking)
CREATE TABLE IF NOT EXISTS execution_state (
    goal_id TEXT NOT NULL,
    phase TEXT NOT NULL,
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    last_attempt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_failure_reason TEXT,
    phase_complete INTEGER DEFAULT 0,
    PRIMARY KEY (goal_id, phase),
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id)
);

-- 4. Add workflow dependencies table
CREATE TABLE IF NOT EXISTS workflow_dependencies (
    workflow_name TEXT NOT NULL,
    prerequisite_workflow TEXT,
    required_tables TEXT,  -- JSON array of required tables
    verification_query TEXT,
    PRIMARY KEY (workflow_name)
);

-- 5. Add note templates table
CREATE TABLE IF NOT EXISTS note_templates (
    template_id TEXT PRIMARY KEY,
    template_name TEXT NOT NULL,
    template_type TEXT NOT NULL CHECK(template_type IN ('syllabus', 'topic', 'review', 'reflection', 'dashboard')),
    template_content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Add indexes for new tables
CREATE INDEX IF NOT EXISTS idx_execution_goal_phase ON execution_state(goal_id, phase);
CREATE INDEX IF NOT EXISTS idx_execution_complete ON execution_state(phase_complete);
CREATE INDEX IF NOT EXISTS idx_user_onboarding ON user_profile(onboarding_complete);
CREATE INDEX IF NOT EXISTS idx_goal_interview ON goal_meta(interview_complete);

-- 7. Populate workflow dependencies
INSERT INTO workflow_dependencies (workflow_name, prerequisite_workflow, required_tables, verification_query) VALUES
('syllabus_generation', NULL, '["goal_meta", "topics", "prerequisites"]', 'SELECT COUNT(*) FROM topics WHERE goal_id = ?'),
('diagnostic_assessment', 'syllabus_generation', '["topics", "sessions"]', 'SELECT COUNT(*) FROM topics WHERE goal_id = ?'),
('study_schedule_optimization', 'syllabus_generation', '["topics", "fsrs_state"]', 'SELECT COUNT(*) FROM fsrs_state'),
('learning_session', 'syllabus_generation', '["topics", "fsrs_state"]', 'SELECT COUNT(*) FROM topics WHERE status != "pending"'),
('prior_knowledge_activation', 'syllabus_generation', '["topics", "prerequisites"]', 'SELECT COUNT(*) FROM prerequisites'),
('metacognitive_reflection', 'learning_session', '["sessions"]', 'SELECT COUNT(*) FROM sessions WHERE session_type = "learning"'),
('review_session', 'learning_session', '["topics", "fsrs_state"]', 'SELECT COUNT(*) FROM fsrs_state WHERE reviews > 0'),
('elaborative_interrogation', 'learning_session', '["topics", "note_registry"]', 'SELECT COUNT(*) FROM note_registry'),
('practice_session', 'learning_session', '["topics", "sessions"]', 'SELECT COUNT(*) FROM sessions WHERE session_type = "practice"'),
('interleaved_practice', 'practice_session', '["sessions"]', 'SELECT COUNT(*) FROM sessions WHERE session_type = "practice"'),
('progress_dashboard', 'syllabus_generation', '["goal_meta", "topics", "streak_state"]', 'SELECT COUNT(*) FROM streak_state'),
('current_affairs_digest', 'syllabus_generation', '["topics"]', 'SELECT COUNT(*) FROM topics WHERE goal_type = "exam"');

-- 8. Add default note templates
INSERT INTO note_templates (template_id, template_name, template_type, template_content) VALUES
('syllabus-default', 'Syllabus Template', 'syllabus', '# {goal_name} Syllabus

**Generated:** {date}
**Goal Type:** {goal_type}
**Total Topics:** {total_topics}

---

## Executive Summary
{executive_summary}

---

## Core Topics

| # | Topic | Prerequisites | Sources | Confidence |
|---|-------|---------------|---------|------------|
{topics_table}

---

## Hidden Topics
{hidden_topics}

---

## Knowledge Graph
{knowledge_graph}

---

## Sources
{sources_bibliography}
'),
('topic-default', 'Topic Note Template', 'topic', '# {topic_name}

**Status:** {status}
**Mastery:** {mastery}%
**Next Review:** {next_review}

---

## Concept
{concept_explanation}

---

## Prerequisites
{prerequisites}

---

## Related Topics
{related_topics}

---

## Practice Problems
{practice_problems}

---

## Sources
{sources}
');

-- 9. Verification query
SELECT 
    'goal_meta columns' AS check_item,
    COUNT(*) AS columns_added
FROM pragma_table_info('goal_meta')
WHERE name IN ('baseline', 'timeline_weeks', 'daily_availability_hours', 'interview_complete');

SELECT 
    'new tables' AS check_item,
    COUNT(*) AS tables_created
FROM sqlite_master
WHERE type='table' 
AND name IN ('user_profile', 'execution_state', 'workflow_dependencies', 'note_templates');
```

### Database Integrity Checks

**File: `docs/learnloop/mcp-queries/integrity.sql`**

```sql
-- ============================================
-- DATABASE INTEGRITY CHECKS
-- ============================================

-- 1. Schema integrity
PRAGMA integrity_check;

-- 2. Foreign key constraints
PRAGMA foreign_key_check;

-- 3. Orphaned topics (no goal)
SELECT t.topic_id, t.name
FROM topics t
LEFT JOIN goal_meta g ON t.goal_id = g.goal_id
WHERE g.goal_id IS NULL;

-- 4. Orphaned FSRS states (no topic)
SELECT fsrs.topic_id
FROM fsrs_state fsrs
LEFT JOIN topics t ON fsrs.topic_id = t.id
WHERE t.id IS NULL;

-- 5. Circular prerequisites
WITH RECURSIVE cycle_detection(topic_id, path, depth) AS (
    SELECT topic_id, CAST(topic_id AS TEXT), 0 FROM topics
    UNION ALL
    SELECT p.topic_id, c.path || ' -> ' || p.prerequisite_id, c.depth + 1
    FROM prerequisites p
    JOIN cycle_detection c ON p.prerequisite_id = c.topic_id
    WHERE c.depth < 20  -- Prevent infinite recursion
)
SELECT topic_id, path FROM cycle_detection
WHERE path LIKE '%' || topic_id || ' -> %' || topic_id;

-- 6. Missing research metadata for goals
SELECT g.goal_id
FROM goal_meta g
LEFT JOIN research_metadata r ON g.goal_id = r.goal_id
WHERE g.interview_complete = 1
AND r.goal_id IS NULL;

-- 7. Topics without sources (core topics only)
SELECT t.topic_id, t.name
FROM topics t
LEFT JOIN topic_sources ts ON t.id = ts.topic_id
WHERE t.is_hidden = 0
AND ts.id IS NULL;
```

### Backup/Restore Protocols

**File: `docs/learnloop/mcp-queries/backup.sql`**

```sql
-- ============================================
-- BACKUP PROTOCOL
-- ============================================

-- Create backup with timestamp
-- Run via bash: sqlite3 ~/.learnloop/goals/{goal_id}/memory.db ".backup ~/.learnloop/backups/{goal_id}_$(date +%Y%m%d_%H%M%S).db"

-- Verify backup
-- Run via bash: sqlite3 ~/.learnloop/backups/{backup_file} "PRAGMA integrity_check; SELECT COUNT(*) FROM topics;"

-- ============================================
-- RESTORE PROTOCOL
-- ============================================

-- Stop all connections
-- Run via bash: rm ~/.learnloop/goals/{goal_id}/memory.db

-- Restore from backup
-- Run via bash: cp ~/.learnloop/backups/{backup_file} ~/.learnloop/goals/{goal_id}/memory.db

-- Verify restored database
PRAGMA integrity_check;
SELECT 'topics' AS tbl, COUNT(*) FROM topics;
SELECT 'goal_meta' AS tbl, COUNT(*) FROM goal_meta;
```

---

## All 12 Workflows - End-to-End Verification

### Workflow State Machine

Each workflow has: **Entry Gate → Execution → Exit Gate**

```markdown
WORKFLOW STATE MACHINE TEMPLATE

Entry Gate:
  - Check prerequisites (workflow_dependencies table)
  - Verify database state
  - If FAIL: Block with clear message

Execution:
  - Run workflow steps
  - Track progress in execution_state table
  - Update phase_complete flags

Exit Gate:
  - Verify outputs created
  - Run satisfaction queries
  - If FAIL: Retry (max 3) or block
```

### Workflow 1: syllabus_generation

**Entry Gate:**
```sql
-- No prerequisites (root workflow)
SELECT 'PASS' AS entry_gate WHERE NOT EXISTS (
    SELECT 1 FROM goal_meta WHERE goal_id = :goal_id
);
-- FAIL: "Goal {goal_id} already exists. Cannot regenerate syllabus."
```

**Execution Steps:**
1. Parse goal → deterministic (cannot fail)
2. Initialize database → create tables
3. Per-goal interview → 4 prompts
4. **Gate 1:** Interview data persisted
5. Launch 4 discovery agents → parallel
6. **Gate 2:** Research metadata complete
7. Merge results → union + dedupe
8. **Gate 3:** Merge complete
9. Run critic agent → adversarial review
10. **Gate 4:** Critic approved
11. Check satisfaction criteria → 7 SQL queries
12. **Gate 5:** Satisfaction verified
13. Generate syllabus → Obsidian note
14. Store in SQLite → INSERT topics
15. **Gate 6:** Database populated

**Exit Gate:**
```sql
-- Final verification
SELECT 
    (SELECT COUNT(*) FROM topics) AS topic_count,
    (SELECT COUNT(*) FROM prerequisites) AS prereq_count,
    (SELECT COUNT(*) FROM topic_sources) AS source_count,
    (SELECT COUNT(*) FROM research_metadata) AS research_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM topics) >= 15
         AND (SELECT COUNT(*) FROM research_metadata) = 4
         AND (SELECT interview_complete FROM goal_meta WHERE goal_id = :goal_id) = 1
        THEN 'PASS'
        ELSE 'FAIL'
    END AS exit_gate;
```

### Workflow 2: diagnostic_assessment

**Prerequisites:** `syllabus_generation` complete

**Entry Gate:**
```sql
SELECT 'PASS' AS entry_gate WHERE EXISTS (
    SELECT 1 FROM goal_meta 
    WHERE goal_id = :goal_id 
    AND interview_complete = 1
)
AND EXISTS (
    SELECT 1 FROM topics WHERE goal_id = :goal_id LIMIT 1
);
-- FAIL: "Syllabus must be generated before diagnostic assessment."
```

**Execution Steps:**
1. Select sample topics from syllabus (5-10 random)
2. Generate assessment questions per topic
3. Present questions to user
4. Collect responses
5. Score performance (0.0-1.0 per topic)
6. Update topics.mastery with baseline
7. Flag weak areas (mastery < 0.5)
8. Write Diagnostic-Report.md

**Exit Gate:**
```sql
SELECT 
    COUNT(*) AS assessed_count,
    AVG(mastery) AS avg_baseline
FROM topics 
WHERE goal_id = :goal_id 
AND mastery > 0;
-- EXPECT: assessed_count >= 5, avg_baseline meaningful
```

### Workflow 3: study_schedule_optimization

**Prerequisites:** `syllabus_generation` + optionally `diagnostic_assessment`

**Entry Gate:**
```sql
SELECT 'PASS' AS entry_gate WHERE EXISTS (
    SELECT 1 FROM fsrs_state fs
    JOIN topics t ON fs.topic_id = t.id
    WHERE t.goal_id = :goal_id
);
-- FAIL: "No FSRS state found. Run syllabus generation first."
```

**Execution Steps:**
1. Load review queue (_topics WHERE next_review <= today_)
2. Calculate priority scores
3. Load user availability from goal_meta
4. Generate time blocks (deep work periods)
5. Apply FSRS spacing
6. Write schedule to Obsidian

**Exit Gate:**
```sql
SELECT 'PASS' AS exit_gate WHERE EXISTS (
    SELECT 1 FROM note_registry 
    WHERE note_path LIKE '%Review-Queue%'
);
-- FAIL: "Schedule not saved to Obsidian."
```

### Workflow 4: learning_session

**Prerequisites:** `syllabus_generation`

**Entry Gate:**
```sql
SELECT 'PASS' AS entry_gate WHERE EXISTS (
    SELECT 1 FROM topics 
    WHERE goal_id = :goal_id 
    AND status = 'pending'
    LIMIT 1
);
-- FAIL: "No pending topics to learn."
```

**Execution Steps:**
1. Select topic (next in sequence or user choice)
2. Check prerequisites (all mastered?)
   - If not: suggest prior_knowledge_activation
3. Load topic content from sources
4. Present concept explanation
5. Generate practice problems (3-5)
6. Collect user responses
7. Score performance
8. Update FSRS state
9. Write topic note to Obsidian
10. Update topics.status to 'in_progress'

**Exit Gate:**
```sql
SELECT 'PASS' AS exit_gate WHERE EXISTS (
    SELECT 1 FROM sessions 
    WHERE topic_id = :topic_id 
    AND session_type = 'learning'
    AND ended_at IS NOT NULL
)
AND EXISTS (
    SELECT 1 FROM note_registry 
    WHERE topic_id = :topic_id
);
-- FAIL: "Session incomplete or note not created."
```

### Workflow 5: prior_knowledge_activation

**Prerequisites:** `syllabus_generation` + topic identified

**Entry Gate:**
```sql
SELECT 'PASS' AS entry_gate WHERE EXISTS (
    SELECT 1 FROM prerequisites p
    JOIN topics t ON p.prerequisite_id = t.id
    WHERE t.goal_id = :goal_id
    LIMIT 1
);
-- FAIL: "No prerequisite links found."
```

**Execution Steps:**
1. Query prerequisites for target topic
2. Check mastery of prerequisites
3. Identify weak prerequisites (mastery < 0.7)
4. Generate review material for weak areas
5. Create bridging questions (connect prereq to target)
6. Draw concept map (ASCII diagram)

**Exit Gate:**
```sql
SELECT 'PASS' AS exit_gate WHERE EXISTS (
    SELECT 1 FROM note_registry 
    WHERE note_path LIKE '%Prior-Knowledge%'
);
-- FAIL: "Prior knowledge activation note not created."
```

### Workflow 6: metacognitive_reflection

**Prerequisites:** `learning_session` (at least 1 completed)

**Entry Gate:**
```sql
SELECT 'PASS' AS entry_gate WHERE EXISTS (
    SELECT 1 FROM sessions 
    WHERE goal_id = :goal_id 
    AND session_type IN ('learning', 'practice', 'review')
    AND ended_at IS NOT NULL
    LIMIT 1
);
-- FAIL: "No completed sessions to reflect on."
```

**Execution Steps:**
1. Load session history (last 10 sessions)
2. Calculate performance metrics per topic
3. Identify patterns (improving, declining, stable)
4. Extract successful strategies (high performance sessions)
5. Flag struggling areas (declining performance)
6. Generate reflection prompts (Socratic questions)
7. Write reflection note

**Exit Gate:**
```sql
SELECT 'PASS' AS exit_gate WHERE EXISTS (
    SELECT 1 FROM note_registry 
    WHERE note_path LIKE '%Reflection%'
);
```

### Workflow 7: review_session

**Prerequisites:** `learning_session` + at least 1 topic reviewed

**Entry Gate:**
```sql
SELECT 'PASS' AS entry_gate WHERE EXISTS (
    SELECT 1 FROM fsrs_state fs
    JOIN topics t ON fs.topic_id = t.id
    WHERE t.goal_id = :goal_id
    AND fs.next_review <= DATE('now')
    LIMIT 1
);
-- FAIL: "No topics due for review."
```

**Execution Steps:**
1. Query overdue topics (next_review <= today)
2. Calculate priority (retrievability - 0.9, lowest first)
3. Present topic for review
4. Collect performance rating (1-4 scale)
5. Update FSRS state
6. Calculate next review date
7. Update topics.next_review

**Exit Gate:**
```sql
SELECT 
    COUNT(*) AS reviewed_count,
    AVG(performance) AS avg_performance
FROM sessions 
WHERE session_type = 'review' 
AND started_at >= DATE('now', '-1 day');
-- EXPECT: reviewed_count >= 1
```

### Workflow 8: elaborative_interrogation

**Prerequisites:** `learning_session` (topic learned)

**Entry Gate:**
```sql
SELECT 'PASS' AS entry_gate WHERE :topic_id IS NOT NULL
AND EXISTS (
    SELECT 1 FROM topics WHERE id = :topic_id AND status != 'pending'
);
-- FAIL: "Topic not learned yet. Run learning_session first."
```

**Execution Steps:**
1. Load topic content
2. Generate "why" questions (3-5)
3. Generate "how" questions (3-5)
4. Prompt user for explanations
5. Identify knowledge gaps (incomplete answers)
6. Provide elaborated answers
7. Update mastery with depth score

**Exit Gate:**
```sql
SELECT 'PASS' AS exit_gate WHERE EXISTS (
    SELECT 1 FROM note_registry 
    WHERE topic_id = :topic_id 
    AND note_path LIKE '%Elaboration%'
);
```

### Workflow 9: practice_session

**Prerequisites:** `learning_session` (topic learned)

**Entry Gate:**
```sql
SELECT 'PASS' AS entry_gate WHERE :topic_id IS NOT NULL
AND EXISTS (
    SELECT 1 FROM note_registry WHERE topic_id = :topic_id
);
-- FAIL: "Topic note not found. Learn topic first."
```

**Execution Steps:**
1. Load topic concepts
2. Generate problems (varying difficulty)
3. Present problem, collect answer
4. Score and provide feedback
5. Calculate performance
6. Update mastery + FSRS state
7. Record session

**Exit Gate:**
```sql
SELECT 'PASS' AS exit_gate WHERE EXISTS (
    SELECT 1 FROM sessions 
    WHERE topic_id = :topic_id 
    AND session_type = 'practice'
    AND ended_at IS NOT NULL
);
```

### Workflow 10: interleaved_practice

**Prerequisites:** `practice_session` (multiple topics practiced)

**Entry Gate:**
```sql
SELECT 'PASS' AS entry_gate WHERE (
    SELECT COUNT(DISTINCT topic_id) FROM sessions 
    WHERE session_type = 'practice' 
    AND goal_id = :goal_id
) >= 3;
-- FAIL: "Need at least 3 practiced topics for interleaving."
```

**Execution Steps:**
1. Select 3-5 topics from same domain
2. Randomize problem order (interleaving)
3. Present mixed problems
4. Score per topic
5. Update all FSRS states
6. Track cross-topic interference

**Exit Gate:**
```sql
SELECT 'PASS' AS exit_gate WHERE EXISTS (
    SELECT 1 FROM sessions 
    WHERE session_type = 'practice'
    AND notes LIKE '%interleaved%'
);
```

### Workflow 11: progress_dashboard

**Prerequisites:** `syllabus_generation`

**Entry Gate:**
```sql
SELECT 'PASS' AS entry_gate WHERE EXISTS (
    SELECT 1 FROM goal_meta WHERE goal_id = :goal_id
);
-- FAIL: "Goal not found."
```

**Execution Steps:**
1. Query goal_meta for totals
2. Count mastered/in_progress/pending
3. Load streak_state
4. Calculate percentages
5. Generate progress bars (ASCII)
6. Calculate days to completion estimate
7. Write/update dashboard

**Exit Gate:**
```sql
SELECT 'PASS' AS exit_gate WHERE EXISTS (
    SELECT 1 FROM note_registry 
    WHERE note_path LIKE '%Dashboard/Progress%'
);
```

### Workflow 12: current_affairs_digest

**Prerequisites:** `syllabus_generation` + goal_type = 'exam'

**Entry Gate:**
```sql
SELECT 'PASS' AS entry_gate WHERE EXISTS (
    SELECT 1 FROM goal_meta 
    WHERE goal_id = :goal_id 
    AND goal_type = 'exam'
);
-- FAIL: "Current affairs only available for exam goals."
```

**Execution Steps:**
1. WebSearch for current events relevant to exam topics
2. Filter by syllabus keywords
3. Summarize key developments
4. Link to syllabus concepts
5. Write daily digest

**Exit Gate:**
```sql
SELECT 'PASS' AS exit_gate WHERE EXISTS (
    SELECT 1 FROM note_registry 
    WHERE note_path LIKE '%Current-Affairs%'
    AND created_at >= DATE('now', '-1 day')
);
```

---

## Vault Structure

### Problem: No Vault Organization Enforcement

**Session Issue:** Files created in:
- `/Users/codeversepro/Obsidian/LL-upsc-maths-optional/` (correct)
- `/Users/codeversepro/Documents/Syllabus/` (wrong - user cwd)

**Root Cause:** Working directory not enforced.

### Vault Hierarchy

```
~/Obsidian/LL-{goal-slug}/
├── 00-Dashboard/
│   ├── Syllabus.md           # Generated syllabus
│   ├── Progress.md            # Progress dashboard
│   └── Schedule.md            # Study schedule
├── 10-Active-Topics/
│   ├── {topic-id}.md         # Topic notes
│   └── {topic-id}-elaboration.md  # Deep-dive notes
├── 20-Review-Queue/
│   ├── Due-{date}.md         # Daily review schedule
│   └── Overdue.md            # Overdue items
├── 30-Mastered/
│   └── {topic-id}.md         # Archived mastered topics
├── 40-Practice/
│   ├── {topic-id}-problems.md  # Practice problem sets
│   └── interleaved-{date}.md    # Interleaved sessions
├── 50-Resources/
│   ├── Reflection-{date}.md  # Metacognitive reflections
│   ├── Current-Affairs-{date}.md  # Daily digest (exam)
│   └── Diagnostic-Report.md  # Baseline assessment
├── 60-Research/
│   ├── {agent-type}-raw-results.json  # Discovery artifacts
│   ├── {agent-type}-sources.md         # Curated sources
│   └── {agent-type}-analysis.md        # Hidden topic analysis
└── Templates/
    ├── topic-template.md
    ├── review-template.md
    └── reflection-template.md
```

### Vault Location Guard

Add to SKILL.md **Pre-Flight**:

```markdown
## Vault Location Guard

**Check vault path:**
1. Read vault_path from goal_meta (if exists)
2. If vault_path IS NULL:
   - Create vault: `~/Obsidian/LL-{goal-slug}/`
   - Create folder structure (see above)
   - Store vault_path in goal_meta
3. Verify vault exists: `ls $vault_path`
4. If FAIL: "Vault not found at {vault_path}. Create it first."

**Enforce vault usage:**
- All notes written to: `{vault_path}/{folder}/{filename}.md`
- If path outside vault: REJECT with error
```

### Vault Creation Script

Add to SKILL.md **Database Initialization** phase:

```markdown
## Create Vault Structure

After database initialization:

```bash
# Set vault path
VAULT_PATH=~/Obsidian/LL-{goal-slug}

# Create folders
mkdir -p "$VAULT_PATH"/{00-Dashboard,10-Active-Topics,20-Review-Queue,30-Mastered,40-Practice,50-Resources,60-Research,Templates}

# Create initial files
touch "$VAULT_PATH/00-Dashboard/Syllabus.md"
touch "$VAULT_PATH/00-Dashboard/Progress.md"

# Store vault path in database
sqlite3 ~/.learnloop/goals/{goal_id}/memory.db \
  "UPDATE goal_meta SET vault_path = '$VAULT_PATH' WHERE goal_id = '{goal_id}';"

# Verify creation
ls -la "$VAULT_PATH"
```

**Verify:** vault_path populated in goal_meta
```

### Naming Conventions

**Enforce in SKILL.md:**

```markdown
## Naming Conventions

| File Type | Pattern | Example |
|-----------|---------|---------|
| Syllabus | Syllabus.md | Syllabus.md |
| Topic Note | {topic-id}.md | linear-algebra-vector-spaces.md |
| Review Queue | Due-{YYYY-MM-DD}.md | Due-2026-09-04.md |
| Reflection | Reflection-{YYYY-MM-DD}.md | Reflection-2026-09-04.md |
| Current Affairs | Current-Affairs-{YYYY-MM-DD}.md | Current-Affairs-2026-09-04.md |
| Research Artifact | {agent-type}-{type}.json/md | official-sources.md |

**Validation regex:**
- Topic ID: `^[a-z0-9-]+$`
- Date file: `^[A-Za-z]+-\d{4}-\d{2}-\d{2}\.md$`
- Research file: `^(official|academic|practical|expert)-(raw-results|sources|analysis)\.(json|md)$`

**Reject if:** filename doesn't match pattern
```

---

## Research Methodology

### Layered Research Approach

**3-Layer Model:**

```
┌─────────────────────────────────────────────────┐
│ LAYER 3: PRACTICAL RESOURCES                     │
│ - Tutorials, blogs, case studies                 │
│ - Agent: discovery-practical                      │
│ - Min searches: 2-3                               │
│ - Focus: applications, examples                   │
└─────────────────────────────────────────────────┘
                      ↑ Triangulation
┌─────────────────────────────────────────────────┐
│ LAYER 2: ACADEMIC RESOURCES                       │
│ - Papers, courses, textbooks                      │
│ - Agent: discovery-academic                        │
│ - Min searches: 3-5                               │
│ - Focus: theory, depth                            │
└─────────────────────────────────────────────────┘
                      ↑ Triangulation
┌─────────────────────────────────────────────────┐
│ LAYER 1: OFFICIAL SOURCES                         │
│ - Curriculum, blueprints, documentation           │
│ - Agent: discovery-official                        │
│ - Min searches: 3-5                               │
│ - Focus: authoritative, exam-aligned              │
└─────────────────────────────────────────────────┘
                      ↑ Triangulation
┌─────────────────────────────────────────────────┐
│ EXPERT PATTERN RECOGNITION                        │
│ - Expert advice, case studies                     │
│ - Agent: discovery-expert                          │
│ - Min searches: 2                                 │
│ - Focus: hidden topics, gotchas                    │
└─────────────────────────────────────────────────┘
```

### Triangulation Rules

**Claim triangulation:** Every claim needs ≥3 independent sources

```markdown
## Triangulation Protocol

For each topic claim:
1. Find sources across different agent types
2. Same domain counts as 1 source
3. Calculate confidence score:
   ```
   confidence = min(1.0, source_count / 3) * agent_diversity_factor
   ```
   - agent_diversity_factor = 1.0 if 4 agents
   - agent_diversity_factor = 0.75 if 3 agents
   - agent_diversity_factor = 0.5 if 2 agents

**Store in topics.confidence**
```

### Hidden Topic Detection

**3 Methods Required:**

| Method | Agent | Detection Logic |
|--------|-------|-----------------|
| `complexity_analysis` | All | Topics requiring unlisted prerequisites |
| `error_pattern` | practical, expert | Common mistakes not in syllabus |
| `expert_practice` | expert | Topics experts emphasize |

**Verification:**
```sql
-- Verify all 3 methods ran
SELECT CASE 
    WHEN COUNT(DISTINCT detection_method) = 3 THEN 'PASS'
    ELSE 'FAIL'
END AS hidden_detection
FROM topics 
WHERE is_hidden = 1 
AND detection_method IS NOT NULL;
```

### Confidence Scoring Model

```python
# Pseudo-code for confidence calculation
def calculate_confidence(topic, sources, agents):
    # Base confidence from source count
    source_confidence = min(1.0, len(sources) / 3)
    
    # Agent diversity factor (penalize single-source agents)
    agent_types = set(s.agent_type for s in sources)
    agent_factors = {
        4: 1.0,  # All agents
        3: 0.85,  # Missing 1 agent
        2: 0.6,   # Missing 2 agents
        1: 0.3    # Single agent
    }
    agent_confidence = agent_factors[len(agent_types)]
    
    # Recency factor (penalize old sources)
    avg_age_months = mean(source.age_months for source in sources)
    recency_factor = max(0.5, 1.0 - (avg_age_months / 36))
    
    # Combined confidence
    confidence = (source_confidence + agent_confidence + recency_factor) / 3
    
    return round(confidence, 2)
```

---

## Implementation Roadmap

### Agent Architecture: Two-Tier Adaptive System

**Session Evidence:** Failed session used 21 agents (all generic), proving single-tier insufficient.

**Root Cause:** Discovery agents exist as prompts but not as registered agent types. Session spawned generic agents because SKILL.md lacked:
1. Two-tier architecture (discovery → deep-dive)
2. Dynamic spawn triggers (complexity >= 7)
3. Budget limits (max 20, tracked)

#### Two-Tier Agent Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ TIER 2: DEEP-DIVE AGENTS (Dynamic: 0-10)                    │
│ - Spawn on complexity >= 7 OR sources < 3                   │
│ - Narrow coverage, deep research                            │
│ - Max 10 deep-dives, batch 4 at a time                      │
│ - Topic-specific expertise                                   │
└─────────────────────────────────────────────────────────────┘
                          ↑ (if topic complex)
┌─────────────────────────────────────────────────────────────┐
│ TIER 1: DISCOVERY AGENTS (Fixed: 4)                         │
│ - Official, Academic, Practical, Expert                     │
│ - Broad coverage, shallow research                           │
│ - MUST complete before Tier 2 spawns                         │
│ - Gate: All 4 insert into research_metadata                  │
└─────────────────────────────────────────────────────────────┘
                          ↑
┌─────────────────────────────────────────────────────────────┐
│ TIER 3: CRITIC + REPAIR (1-6)                               │
│ - 1 critic (fixed)                                          │
│ - 0-5 repair agents (if critic rejects)                     │
│ - Max 3 repair cycles                                        │
│ - Final verification before output                           │
└─────────────────────────────────────────────────────────────┘
```

#### Adaptive Agent Budget

| Tier | Category | Min | Max | Trigger |
|------|----------|-----|-----|---------|
| 1 | Discovery | 4 | 4 | Fixed (always run) |
| 2 | Deep-Dive | 0 | 10 | complexity >= 7 OR sources < 3 |
| 3 | Critic | 1 | 1 | Fixed (quality gate) |
| 3 | Repair | 0 | 5 | Critic verdict == "reject" |
| **Total** | **All** | **5** | **20** | Dynamic based on goal |

#### Dynamic Spawn Triggers

**Deep-Dive Agent Spawn Conditions:**

```sql
-- After Wave 1 (Discovery) completes
-- Identify topics needing deep research

SELECT topic_id, topic_name,
       complexity_score,
       source_count,
       CASE 
         WHEN complexity_score >= 7 THEN 'deep-dive'
         WHEN source_count < 3 THEN 'deep-dive'
         ELSE 'skip'
       END AS spawn_decision
FROM topics t
LEFT JOIN (
    SELECT topic_id, COUNT(*) as source_count
    FROM topic_sources
    GROUP BY topic_id
) ts ON t.id = ts.topic_id
WHERE t.goal_id = :goal_id
AND t.is_hidden = 0
AND (complexity_score >= 7 OR source_count < 3 OR source_count IS NULL);
```

#### Wave Orchestration Pattern

**Wave 1: Discovery (4 agents, parallel)**
```markdown
1. Spawn all 4 discovery agents in parallel
2. Wait for completion (barrier)
3. **GATE 3A:** Verify all 4 agents ran
   ```sql
   SELECT COUNT(*) FROM research_metadata 
   WHERE goal_id = :goal_id 
   AND agent_type IN ('official', 'academic', 'practical', 'expert');
   -- Expected: 4
   ```
4. If gate fails: retry missing agents (max 2 retries)
```

**Wave 2: Deep-Dive (0-10 agents, batched)**
```markdown
1. Merge Wave 1 results
2. Identify complex topics (SQL query above)
3. Spawn deep-dive agents in batches of 4:
   - Batch 1: topics[0:4]
   - Wait for batch completion
   - Batch 2: topics[4:8] (if needed)
   - Wait for batch completion
   - Batch 3: topics[8:10] (if needed, max 10)
4. **GATE 3B:** Verify deep-dives completed
   ```sql
   SELECT COUNT(*) FROM execution_state
   WHERE goal_id = :goal_id AND phase = 'deep-dive';
   -- Expected: <= 10, matches spawned count
   ```
```

**Wave 3: Critic with Date Context (1 agent, sequential)**
```markdown
1. Merge Wave 1 + Wave 2 results
2. Spawn critic agent with date-aware prompt:
   ```
   **Critic Agent Prompt:**
   
   **Current Date:** {current_date ISO-8601}
   
   You are the quality gate for syllabus generation.
   
   **Context:**
   - Goal: {goal_name}
   - Goal Type: {goal_type}
   - Discovery Agents: 4 (official, academic, practical, expert)
   - Deep-Dive Agents: {N} topics researched
   
   **Your Task:**
   1. Verify research completeness (≥3 sources per topic)
   2. Verify hidden topic detection (3 methods used)
   3. Check source recency (≤2 years for exam goals)
   4. Validate triangulation (≥3 agent types per claim)
   5. Check database integrity (all required tables populated)
   
   **Verdict Options:**
   - APPROVED: All checks pass
   - APPROVED_WITH_WARNINGS: Minor issues, list warnings
   - REJECT: Critical issues, must fix before output
   
   **Output Format:**
   ```json
   {
     "verdict": "APPROVED|APPROVED_WITH_WARNINGS|REJECT",
     "checks": [
       {"check": "research_completeness", "status": "PASS|FAIL", "details": "..."},
       {"check": "hidden_detection", "status": "PASS|FAIL", "details": "..."},
       ...
     ],
     "warnings": [],
     "challenges": ["specific issue 1", "specific issue 2"],
     "repair_suggestions": ["action 1", "action 2"]
   }
   ```
   
   **Constraint:** Always include current date in reasoning to verify source recency.
   ```
3. Wait for verdict
4. **GATE 4:** Critic decision
   - APPROVED: Proceed to Wave 5 (Output)
   - APPROVED_WITH_WARNINGS: Log warnings, proceed to Wave 5
   - REJECT: Loop to Wave 4 (Repair)
```

**Wave 4: Repair Loop (0-5 agents, loop until satisfied)**
```markdown
WHILE critic_verdict == "reject" AND repair_cycles < 3:
    
    **Repair Cycle {cycle_number}:**
    
    1. Extract critic challenges from verdict JSON
    2. Categorize challenges by type:
       - research_gap: Missing sources → spawn discovery agents
       - detection_missing: Hidden topics not found → spawn detection agents  
       - validation_failed: SQL checks fail → spawn verification agents
       - quality_issue: Confidence too low → spawn deep-dive agents
    
    3. Spawn repair agents (max 5 per cycle):
       ```markdown
       **Repair Agent Prompt:**
       
       **Current Date:** {current_date ISO-8601}
       **Repair Cycle:** {cycle_number}/3
       
       You are fixing a specific issue identified by the critic.
       
       **Issue:** {specific_challenge}
       **Category:** {challenge_category}
       **Affected Topics:** {topic_list}
       
       **Your Task:**
       1. Re-run WebSearch with refined queries
       2. Add missing sources to topic_sources table
       3. Re-run hidden topic detection if needed
       4. Update topics.confidence scores
       5. Save artifacts to ~/.learnloop/research/{goal_id}/repair-{cycle}/
       
       **Output:**
       ```json
       {
         "repair_type": "{challenge_category}",
         "topics_fixed": ["topic1", "topic2"],
         "sources_added": 5,
         "detection_methods_rerun": ["complexity_analysis"],
         "confidence_updated": true
       }
       ```
       
       **Constraint:** Use current date to verify source recency.
       ```
    
    4. Wait for repair agents to complete
    5. Update execution_state:
       ```sql
       UPDATE execution_state 
       SET attempts = attempts + 1,
           last_attempt = CURRENT_TIMESTAMP
       WHERE goal_id = :goal_id AND phase = 'repair';
       ```
    
    6. Re-run critic (Wave 3) with updated context
    7. Check new verdict:
       - APPROVED/APPROVED_WITH_WARNINGS: Exit loop, proceed to Wave 5
       - REJECT: Continue loop (if cycles < 3)
    
    8. If max cycles (3) reached and still REJECT:
       ```sql
       INSERT INTO execution_state (goal_id, phase, last_failure_reason)
       VALUES (:goal_id, 'repair_max_cycles', 'Critic still rejects after 3 repair cycles');
       ```
       - Log fundamental issue
       - Generate partial output with warnings
       - Notify user that manual review needed

**Repair Loop Exit Conditions:**
- Critic verdict != "reject" (satisfied)
- Max cycles reached (3) → partial output with warnings
- User cancellation

---

## Design Validation & Self-Check

### Coverage Matrix: All 12 Workflows

| Workflow | Entry Gate | Exit Gate | Agent Types | SQL Verification |
|----------|------------|-----------|-------------|------------------|
| 1. syllabus_generation | goal_meta exists | topics ≥ 1 | 4 discovery + N deep-dive + critic | `SELECT COUNT(*) FROM topics WHERE goal_id = ?` |
| 2. diagnostic_assessment | syllabus_generation complete | assessments ≥ 1 | 1 assessor | `SELECT COUNT(*) FROM sessions WHERE session_type = 'assessment'` |
| 3. study_schedule_optimization | syllabus_generation complete | fsrs_state populated | 1 scheduler | `SELECT COUNT(*) FROM fsrs_state` |
| 4. learning_session | topics.status != 'pending' | session recorded | 1 tutor | `SELECT COUNT(*) FROM sessions WHERE session_type = 'learning'` |
| 5. prior_knowledge_activation | prerequisites exist | activated topics ≥ 1 | 1 activator | `SELECT COUNT(*) FROM topics WHERE prior_knowledge_activated = 1` |
| 6. metacognitive_reflection | learning_session complete | reflection recorded | 1 reflector | `SELECT COUNT(*) FROM note_registry WHERE note_type = 'reflection'` |
| 7. review_session | fsrs_state.reviews > 0 | review completed | 1 reviewer | `SELECT COUNT(*) FROM sessions WHERE session_type = 'review'` |
| 8. elaborative_interrogation | learning_session complete | elaboration recorded | 1 elaborator | `SELECT COUNT(*) FROM note_registry WHERE note_type = 'elaboration'` |
| 9. practice_session | topics.status = 'active' | practice recorded | 1 practitioner | `SELECT COUNT(*) FROM sessions WHERE session_type = 'practice'` |
| 10. interleaved_practice | practice_session complete | interleaved set ≥ 2 | 1 interleaver | `SELECT COUNT(*) FROM sessions WHERE session_type = 'interleaved'` |
| 11. progress_dashboard | syllabus_generation complete | dashboard generated | 1 dashboarder | `SELECT COUNT(*) FROM dashboards WHERE goal_id = ?` |
| 12. current_affairs_digest | goal_type = 'exam' | digest generated | 1 digester | `SELECT COUNT(*) FROM digests WHERE goal_id = ?` |

### Architecture Review Checklist

**Design Self-Check (Pre-Implementation):**

- [x] **Completeness:** All 12 workflows covered with entry/exit gates
- [x] **Agent Coverage:** Discovery (4) + Deep-Dive (dynamic) + Critic (1) + Repair (conditional)
- [x] **Database Schema:** Complete with execution_state, workflow_dependencies, note_templates
- [x] **Phase Gates:** SQL verification between each wave
- [x] **Self-Healing:** Repair loop with max 3 cycles
- [x] **Budget Tracking:** Advisory warnings (not blocking) at 10/15/20 agents
- [x] **Date Context:** Current date in all agent prompts for recency verification
- [x] **Output Organization:** Vault structure defined in Component 5
- [x] **Research Methodology:** 3-layer triangulation with confidence scoring
- [x] **Hidden Topic Detection:** 3 methods (complexity_analysis, error_pattern, expert_practice)

### Outstanding Items (Add to Implementation Plan)

**CRITICAL: Date Injection in Agent Prompts**

Every agent MUST receive current date in ISO-8601 format:

```markdown
**Current Date:** 2026-09-04 (ISO-8601)

Use this date to:
1. Verify source recency (≤2 years for exam goals)
2. Calculate staleness scores
3. Filter outdated curriculum references
4. Validate exam schedules against current date
```

**Implementation:** Update SKILL.md agent spawn instructions to inject `{current_date}` variable at runtime.

### Missing Components (Added During Validation)

**Component 6: Error Recovery Patterns**

| Error Type | Detection | Recovery |
|------------|-----------|----------|
| Agent spawn failure | Agent tool returns null | Retry same agent (max 2) |
| WebSearch quota exceeded | Search returns error | Use cached results, degrade gracefully |
| Database locked | SQL INSERT fails | Wait 5s, retry (max 3) |
| Invalid JSON output | Parse fails | Re-run agent with stricter prompt |
| Missing table | SQL query fails | Run schema migration, retry |
| Critic loop stuck | 3 cycles = still REJECT | Partial output + manual review flag |

**Component 7: Telemetry & Observability**

```sql
-- Track all phase transitions
CREATE TABLE IF NOT EXISTS phase_telemetry (
    goal_id TEXT NOT NULL,
    phase TEXT NOT NULL,
    wave INTEGER,
    agent_type TEXT,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    duration_seconds INTEGER,
    success INTEGER DEFAULT 1,
    error_message TEXT,
    PRIMARY KEY (goal_id, phase, started_at)
);

-- Query for performance analysis
SELECT 
    phase,
    AVG(duration_seconds) as avg_duration,
    COUNT(*) as runs,
    SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) as failures
FROM phase_telemetry
GROUP BY phase
ORDER BY avg_duration DESC;
```

---

## Implementation Plan Structure

**Phase 1: Foundation (Day 1)**
- Agent registry (6 agent definition files)
- Database migration (schema.sql updates)
- Phase gate SQL files

**Phase 2: Intelligence Layer (Day 2)**
- Discovery agent prompts (4 files)
- Deep-dive agent template
- Critic agent prompt
- Repair agent prompt

**Phase 3: Orchestration (Day 3)**
- SKILL.md workflow rewrite
- Wave orchestration logic
- Repair loop implementation

**Phase 4: Testing & Validation (Day 4)**
- SQL gate verification
- Agent spawn tests
- End-to-end workflow test
- Budget tracking tests

**Phase 5: Documentation (Day 5)**
- Update README
- Architecture diagrams
- Troubleshooting guide
- Migration guide for existing goals

---

Ready for implementation planning. Invoke `/superpowers:writing-plans` to create detailed implementation tasks.

#### Budget Tracking Schema

Add to `execution_state` table:

```sql
ALTER TABLE execution_state ADD COLUMN agent_spawns INTEGER DEFAULT 0;
ALTER TABLE execution_state ADD COLUMN wave INTEGER DEFAULT 0;
ALTER TABLE execution_state ADD COLUMN agent_type TEXT;

-- Track each spawn
INSERT INTO execution_state 
    (goal_id, phase, wave, agent_spawns, agent_type, last_attempt)
VALUES 
    (:goal_id, :phase, :wave, :count, :agent_type, CURRENT_TIMESTAMP);

-- Budget verification (WARNING only, does not block)
-- Check agent count and emit warning if approaching limit

SELECT 
    SUM(agent_spawns) AS total_agents,
    CASE 
        WHEN SUM(agent_spawns) >= 20 THEN 'WARN_LIMIT'
        WHEN SUM(agent_spawns) >= 15 THEN 'WARN_75PCT'
        WHEN SUM(agent_spawns) >= 10 THEN 'WARN_50PCT'
        ELSE 'OK'
    END AS budget_status,
    CASE
        WHEN SUM(agent_spawns) >= 20 THEN '⚠️ Agent budget exhausted. Consider simplifying goal scope for future runs.'
        WHEN SUM(agent_spawns) >= 15 THEN '⚠️ Agent budget at 75%. Approaching limit.'
        WHEN SUM(agent_spawns) >= 10 THEN 'ℹ️ Agent count: 10+. High agent usage.'
        ELSE '✓ Agent count within budget.'
    END AS budget_message
FROM execution_state
WHERE goal_id = :goal_id;

-- Note: Budget is advisory, not blocking. Execution continues regardless.
-- Purpose: Track resource usage and inform user of optimization opportunities.
```

#### Budget Warning Thresholds

Add to SKILL.md:

```markdown
## Agent Budget Alerts (Advisory, Not Blocking)

At runtime, emit INFORMATIONAL warnings:
- **10 agents:** "ℹ️ Agent count: 10+. High agent usage."
- **15 agents:** "⚠️ Agent budget at 75%. Approaching limit."
- **20 agents:** "⚠️ Agent budget exhausted. Consider simplifying goal scope for future runs."

**Important:** Budget warnings are ADVISORY only. They do NOT stop execution.
**Purpose:** Track resource usage and inform optimization opportunities.

**Token budget by goal_type:**
- exam: 150k tokens
- degree: 300k tokens (larger scope)
- skill: 100k tokens (smaller scope)
- topic: 75k tokens (smallest scope)

**Note:** Token budgets are also advisory. Execution continues regardless of budget status.
```

#### Session Evidence: What Worked vs Failed

| Pattern | Session (Failed) | Proposed (Adaptive) |
|---------|------------------|---------------------|
| Agent count | 21 (untracked) | 5-20 (tracked) |
| Agent types | All generic | Two-tier (discovery/deep-dive/repair) |
| Coordination | Ad-hoc | Wave-based with gates |
| Budget control | None | Max 20, SQL-tracked |
| Verification | Post-hoc | Gates after each wave |
| Deep research | After fixes | From start (Tier 2 spawns on complexity) |

### Phase 1: Agent Registry (Day 1)

**Tasks:**
1. Create `docs/learnloop/agents/` directory
2. Write agent definition files:
   - `discovery-official.md`
   - `discovery-academic.md`
   - `discovery-practical.md`
   - `discovery-expert.md`
   - `critic.md`
3. Verify agents loadable by Claude Code

**Verification:**
```bash
ls -la docs/learnloop/agents/
# Expected: 5 .md files
```

### Phase 2: Schema Migration (Day 1)

**Tasks:**
1. Write `migrations/005-comprehensive-schema.sql`
2. Write `integrity.sql` checks
3. Write `backup.sql` protocols
4. Run migration on test goal

**Verification:**
```sql
SELECT COUNT(*) FROM sqlite_master WHERE type='table';
-- Expected: >= 15 tables

PRAGMA integrity_check;
-- Expected: ok
```

### Phase 3: SKILL.md Refactor (Day 2)

**Tasks:**
1. Add pre-flight validation section
2. Add phase gates after each workflow step
3. Add vault creation to database initialization
4. Add vault location guard
5. Add naming convention enforcement
6. Add verification queries for all 12 workflows

**Verification:**
- Count phase gates: >= 6 for syllabus_generation
- Verify vault path check exists
- Verify interview persistence gate exists

### Phase 4: Verification Queries (Day 2)

**Tasks:**
1. Write `verification.sql` with all gates
2. Write workflow-specific verification queries
3. Add retry logic instructions

**Verification:**
```sql
-- Run all gates
SELECT * FROM verification_queries;
-- Expected: All PASS
```

### Phase 5: Testing (Day 3)

**Tasks:**
1. Create test goal
2. Run full syllabus_generation workflow
3. Verify all gates fire correctly
4. Verify database populated correctly
5. Verify vault structure exists
6. Verify all 12 workflows have gates

**Success Criteria:**
- [ ] Goal created in `~/.learnloop/goals/{goal_id}/`
- [ ] Database exists at correct location
- [ ] Interview data in goal_meta table
- [ ] 4 discovery agents spawned (not general-purpose)
- [ ] Research metadata populated
- [ ] Vault created at `~/Obsidian/LL-{goal-slug}/`
- [ ] Syllabus.md in vault
- [ ] All satisfaction queries pass
- [ ] Can run progress_dashboard workflow
- [ ] Can run review_session workflow

---

## Open Questions

### Architecture

1. **Agent tool access:** Can registered agents access WebSearch, Write, Read, Bash?
2. **Concurrent limits:** Can 4 agents spawn simultaneously?
3. **Migration safety:** How to handle existing goals with old schema?

### Workflow

1. **User cancellation:** What happens if user cancels mid-workflow?
2. **Partial state:** Allow partial completion or force full completion?
3. **Expert mode:** Allow users to skip gates if they know what they're doing?

### Testing

1. **Test goals:** Create dedicated test fixtures?
2. **WebSearch mocking:** How to test without real WebSearch?
3. **Integration tests:** Automate workflow verification?

---

## Success Metrics

| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| Interview persistence | 0% | 100% | SQL query after Phase 1 |
| Discovery agents correct | 0% | 100% | Agent type in tool calls |
| Research metadata tracked | 0% | 100% | SQL query after Phase 2 |
| Vault location enforced | 0% | 100% | Path validation |
| All 12 workflows gated | 0% | 100% | Count of gates |
| Satisfaction criteria run | 0% | 100% | SQL execution logs |
| Hidden topics detected | 0% | 100% | Query for 3 methods |
| Database at correct location | 100%* | 100% | Path check |

*Database was created correctly in session, but other checks failed.

---

**Status:** Comprehensive design complete  
**Next:** User approval → Invoke writing-plans skill  
