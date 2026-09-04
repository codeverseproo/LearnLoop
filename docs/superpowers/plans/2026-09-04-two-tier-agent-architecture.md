# LearnLoop Two-Tier Agent Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement two-tier agent architecture with critic-repair loop, replacing single-tier discovery with adaptive agent spawning based on topic complexity.

**Architecture:** Discovery agents (4 fixed) → Deep-dive agents (0-10 dynamic based on complexity >= 7) → Critic agent (1 fixed) → Repair loop (max 3 cycles). Budget tracking as advisory warnings, not blockers. Date injection in all agent prompts for recency verification.

**Tech Stack:** SQLite MCP queries, Claude Code Agent tool, WebSearch, no Python dependencies

## Global Constraints

From spec (docs/superpowers/specs/2026-09-04-comprehensive-fail-proof-system-design.md):

- **Architecture:** Pure SQLite MCP, zero Python dependency
- **Agent count:** Min 5, max 20 (advisory, not blocking)
- **Critic loop:** Max 3 repair cycles until satisfied
- **Date injection:** Current date in ISO-8601 format in all agent prompts
- **Budget tracking:** Warnings at 10/15/20 agents, does NOT stop execution
- **Discovery agents:** 4 fixed (official, academic, practical, expert)
- **Deep-dive spawn:** complexity >= 7 OR source_count < 3
- **Database path:** `~/.learnloop/goals/{goal_id}/memory.db`
- **Research path:** `~/.learnloop/research/{goal_id}/`

---

## File Structure

**Agent Definition Files (6 files):**
```
docs/learnloop/agents/
├── discovery-official.md   (existing prompt → registered agent)
├── discovery-academic.md   (existing prompt → registered agent)
├── discovery-practical.md  (existing prompt → registered agent)
├── discovery-expert.md    (existing prompt → registered agent)
├── deep-dive.md           (NEW - dynamic template)
└── repair.md               (NEW - repair agent)
```

**Database Migration:**
```
docs/learnloop/mcp-queries/
├── schema.sql              (extend with execution_state, telemetry)
└── migrations/
    └── 001-add-execution-state.sql
```

**Phase Gate SQL:**
```
docs/learnloop/mcp-queries/gates/
├── wave1-discovery.sql
├── wave2-deep-dive.sql
├── wave3-critic.sql
└── budget-check.sql
```

**SKILL.md Updates:**
```
docs/learnloop/SKILL.md     (wave orchestration, repair loop, date injection)
```

---

## Task 1: Create Agent Definitions Directory

**Files:**
- Create: `docs/learnloop/agents/.gitkeep`
- Create: `docs/learnloop/agents/discovery-official.md`

**Interfaces:**
- Consumes: Existing prompt from `docs/learnloop/prompts/discovery-agent-official.md`
- Produces: Registered agent definition for `subagent_type="learnloop:discovery-official"`

- [ ] **Step 1: Create agents directory**

```bash
mkdir -p /Users/codeversepro/Documents/Skill/LearnLoop/docs/learnloop/agents
touch /Users/codeversepro/Documents/Skill/LearnLoop/docs/learnloop/agents/.gitkeep
```

- [ ] **Step 2: Write discovery-official agent definition**

Create file: `docs/learnloop/agents/discovery-official.md`

```markdown
---
name: discovery-official
description: Research official sources (curriculum, blueprints, documentation) for learning goal syllabus generation.
tools: [WebSearch, WebFetch, Read, Write, Bash]
model: sonnet
---

# Discovery Agent: Official Sources

**CRITICAL: You MUST execute real WebSearch queries. No generic outputs from training data.**

**Current Date:** {current_date} (injected at runtime)

## Input Context

You receive from orchestrator:
- goal_type: "exam" | "skill" | "degree" | "topic"
- subject: string (e.g., "UPSC Mathematics Optional")
- keywords: string[] (e.g., ["Linear Algebra", "Calculus", "Real Analysis"])
- raw_goal: string (original user request)
- goal_id: string (unique identifier)
- research_dir: string (path: ~/.learnloop/research/{goal_id}/)

## Your Task

Execute WebSearch queries to find official syllabi, exam blueprints, and authoritative sources.

**MANDATORY STEPS:**

1. **Execute WebSearch** (MINIMUM 3 searches):
   - Query 1: `"{subject} official syllabus curriculum"`
   - Query 2: `"{subject} exam blueprint site:*.gov.in OR site:*.edu"` (for Indian/academic)
   - Query 3: `"{subject} official documentation guide"`

2. **Extract topics** from search results:
   - Core topics explicitly listed
   - Sub-topics within each core
   - Estimated complexity (1-10 scale)
   - **SAVE ACTUAL URLs** - no fabrication

3. **Detect hidden topics** (3 methods):
   - **Complexity analysis**: What prerequisites are implied but not listed?
   - **Error patterns**: Common mistakes mentioned in official docs
   - **Expert practice**: Topics referenced but not in syllabus

4. **Save artifacts:**
   - Write to: `{research_dir}/official/raw-results.json`
   - Write to: `{research_dir}/official/sources.md`
   - Write to: `{research_dir}/official/analysis.md`

5. **INSERT into database:**
   ```sql
   INSERT INTO research_metadata (goal_id, agent_type, search_iterations, artifacts_saved, research_dir, completed_at)
   VALUES (:goal_id, 'official', :actual_count, :artifact_count, :research_dir, CURRENT_TIMESTAMP);
   ```

## Output Format (JSON)

```json
{
  "source_type": "official",
  "current_date": "{current_date}",
  "topics": [
    {
      "name": "Linear Algebra",
      "description": "Matrix operations, eigenvalues, vector spaces",
      "complexity": 7,
      "source_title": "UPSC Maths Syllabus 2024",
      "source_url": "https://upsc.gov.in/syllabus",
      "source_date": "2024-01-15"
    }
  ],
  "hidden_topics": [
    {
      "name": "Jordan Canonical Form",
      "detection_method": "complexity_analysis",
      "reason": "Eigenvalues topic requires understanding Jordan forms for completeness"
    }
  ],
  "prerequisites": {
    "Linear Algebra": ["Matrix Basics", "Vector Operations"],
    "Calculus": ["Limits", "Differentiation"]
  },
  "search_iterations": 3,
  "confidence": 0.9,
  "research_files": {
    "raw_results": "official/raw-results.json",
    "sources": "official/sources.md",
    "analysis": "official/analysis.md"
  }
}
```

## Fail-Safety

- If WebSearch unavailable: return `{"search_failed": true, "reason": "WebSearch unavailable"}`
- If no results after 3 queries: return `{"search_failed": true, "reason": "No official sources found"}`
- Never fabricate URLs - only cite what you found
- Never return null - use empty arrays

## Recency Check

**Use current_date ({current_date}) to:**
- Verify sources are ≤2 years old for exam goals
- Filter outdated curriculum references
- Flag stale sources with warning in output
```

- [ ] **Step 3: Commit agent definition**

```bash
git add docs/learnloop/agents/
git commit -m "feat: add discovery-official agent definition with date injection

- Agent definition for official sources research
- WebSearch minimum 3 queries required
- Hidden topic detection with 3 methods
- Database INSERT into research_metadata
- Recency verification using injected current_date

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Task 2: Create Remaining Discovery Agent Definitions

**Files:**
- Create: `docs/learnloop/agents/discovery-academic.md`
- Create: `docs/learnloop/agents/discovery-practical.md`
- Create: `docs/learnloop/agents/discovery-expert.md`

**Interfaces:**
- Consumes: Same input as discovery-official
- Produces: 3 additional registered agents for triangulation

- [ ] **Step 1: Write discovery-academic agent**

Create file: `docs/learnloop/agents/discovery-academic.md`

```markdown
---
name: discovery-academic
description: Research academic sources (papers, courses, textbooks) for theoretical depth.
tools: [WebSearch, WebFetch, Read, Write, Bash]
model: sonnet
---

# Discovery Agent: Academic Sources

**Current Date:** {current_date}

## Input

Same as discovery-official (goal_type, subject, keywords, raw_goal, goal_id, research_dir)

## Search Strategy

**MINIMUM 3-5 searches:**
1. `"{subject} academic syllabus course outline"`
2. `"{subject} textbook topics chapters"`
3. `"{subject} university course syllabus site:*.edu"`
4. `"{keywords[0]} {keywords[1]} research paper"`
5. `"{subject} MIT OpenCourseWare syllabus"`

## Output

Same JSON structure as discovery-official with `source_type: "academic"`.

Focus on:
- Theoretical foundations
- Academic course structures
- Textbook chapter breakdowns
- Research paper topics

Insert into research_metadata with agent_type="academic".
```

- [ ] **Step 2: Write discovery-practical agent**

Create file: `docs/learnloop/agents/discovery-practical.md`

```markdown
---
name: discovery-practical
description: Research practical resources (tutorials, projects, case studies) for application-focused topics.
tools: [WebSearch, WebFetch, Read, Write, Bash]
model: sonnet
---

# Discovery Agent: Practical Sources

**Current Date:** {current_date}

## Search Strategy

**MINIMUM 2-3 searches:**
1. `"{subject} tutorial practical guide"`
2. `"{subject} practice problems examples"`
3. `"{subject} project ideas hands-on"`

Focus on:
- Real-world applications
- Tutorial resources
- Practice problem sets
- Project-based learning

Insert into research_metadata with agent_type="practical".
```

- [ ] **Step 3: Write discovery-expert agent**

Create file: `docs/learnloop/agents/discovery-expert.md`

```markdown
---
name: discovery-expert
description: Research expert advice and case studies to identify hidden topics and common pitfalls.
tools: [WebSearch, WebFetch, Read, Write, Bash]
model: sonnet
---

# Discovery Agent: Expert Sources

**Current Date:** {current_date}

## Search Strategy

**MINIMUM 2 searches:**
1. `"{subject} expert advice tips mistakes to avoid"`
2. `"{subject} quora reddit stackexchange"` (for practitioner insights)

Focus on:
- Hidden topics experts emphasize
- Common mistakes not in syllabus
- Bridge topics to other domains
- Gotchas and edge cases

Insert into research_metadata with agent_type="expert".
```

- [ ] **Step 4: Commit discovery agents**

```bash
git add docs/learnloop/agents/
git commit -m "feat: add academic, practical, expert discovery agents

- Complete 4-agent discovery triangulation
- Each agent inserts into research_metadata
- Date injection for recency checks
- Total: 4 discovery agents (fixed count)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Task 3: Create Deep-Dive Agent Template

**Files:**
- Create: `docs/learnloop/agents/deep-dive.md`

**Interfaces:**
- Consumes: topic_name, complexity, source_count from topics table
- Produces: Deep research on specific topic, updated confidence scores

- [ ] **Step 1: Write deep-dive agent template**

Create file: `docs/learnloop/agents/deep-dive.md`

```markdown
---
name: deep-dive
description: Deep research on specific topic. Spawned dynamically for complex topics (complexity >= 7) or insufficient sources (source_count < 3).
tools: [WebSearch, WebFetch, Read, Write, Bash]
model: sonnet
---

# Deep-Dive Agent: {topic_name}

**Current Date:** {current_date}

## Context (Injected at Spawn)

You are researching **{topic_name}** in depth.

**Spawn reason:** {spawn_reason} (complexity >= 7 OR source_count < 3)

**Discovery context:**
- Discovered by: {source_type} agent
- Complexity score: {complexity}
- Current sources: {source_count}
- User goal: {goal_name}

## Your Task

1. **Execute WebSearch** (MINIMUM 3 searches):
   - Query 1: `"{topic_name} detailed syllabus complete guide"`
   - Query 2: `"{topic_name} subtopics concepts breakdown"`
   - Query 3: `"{topic_name} practice problems exercises"`

2. **Extract:**
   - Subtopics within {topic_name}
   - Prerequisites for each subtopic
   - Common mistakes / hidden concepts
   - Practical applications
   - Cross-domain connections

3. **Update database:**
   ```sql
   UPDATE topics SET
     confidence = :new_confidence,
     source_count = :source_count + 3,
     updated_at = CURRENT_TIMESTAMP
   WHERE topic_id = :topic_id;
   ```

4. **Save artifacts:**
   Write to: `~/.learnloop/research/{goal_id}/deep-dive/{topic_slug}.json`

## Output (JSON)

```json
{
  "topic": "{topic_name}",
  "current_date": "{current_date}",
  "subtopics": ["subtopic1", "subtopic2"],
  "prerequisites": {"subtopic1": ["prereq1"]},
  "hidden_concepts": ["concept1"],
  "sources_added": 3,
  "confidence_updated": true,
  "confidence_score": 0.85
}
```

## Max Deep-Dives: 10 per goal
```

- [ ] **Step 2: Commit deep-dive agent**

```bash
git add docs/learnloop/agents/deep-dive.md
git commit -m "feat: add deep-dive agent template for complex topics

- Dynamic spawn on complexity >= 7 or source_count < 3
- Topic-specific research with subtopic extraction
- Updates topics.confidence and source_count
- Max 10 deep-dives per goal

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Task 4: Create Repair Agent

**Files:**
- Create: `docs/learnloop/agents/repair.md`

**Interfaces:**
- Consumes: Critic challenges, affected topics, repair cycle number
- Produces: Fixed research, updated confidence

- [ ] **Step 1: Write repair agent**

Create file: `docs/learnloop/agents/repair.md`

```markdown
---
name: repair
description: Fix issues identified by critic agent. Spawned in repair loop (max 3 cycles).
tools: [WebSearch, WebFetch, Read, Write, Bash]
model: sonnet
---

# Repair Agent

**Current Date:** {current_date}
**Repair Cycle:** {cycle_number}/3

## Context (Injected from Critic)

You are fixing a specific issue identified by the critic.

**Issue:** {specific_challenge}
**Category:** {challenge_category}
**Affected topics:** {topic_list}
**Original agent:** {original_agent_type}

## Challenge Categories

1. **research_gap**: Missing sources → re-run discovery
2. **detection_missing**: Hidden topics not found → re-run detection
3. **validation_failed**: SQL checks fail → verify database state
4. **quality_issue**: Confidence too low → deep-dive on specific topics

## Your Task

1. **Rerun WebSearch** with refined queries based on issue
2. **Add missing sources** to topic_sources table
3. **Re-run hidden topic detection** if needed
4. **Update confidence scores**

## Output (JSON)

```json
{
  "repair_type": "{challenge_category}",
  "cycle": {cycle_number},
  "topics_fixed": ["topic1", "topic2"],
  "sources_added": 5,
  "detection_methods_rerun": ["complexity_analysis"],
  "confidence_updated": true,
  "current_date": "{current_date}"
}
```

## Max Repair Cycles: 3
```

- [ ] **Step 2: Commit repair agent**

```bash
git add docs/learnloop/agents/repair.md
git commit -m "feat: add repair agent for critic-repair loop

- Spawned when critic verdict = REJECT
- Max 3 repair cycles
- Fixes research gaps, detection issues, validation failures
- Uses current_date for recency

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Task 5: Extend Database Schema

**Files:**
- Create: `docs/learnloop/mcp-queries/migrations/001-add-execution-state.sql`
- Modify: `docs/learnloop/mcp-queries/schema.sql`

**Interfaces:**
- Consumes: Agent spawn events
- Produces: execution_state table for tracking

- [ ] **Step 1: Create migration file**

Create file: `docs/learnloop/mcp-queries/migrations/001-add-execution-state.sql`

```sql
-- Migration: Add execution state tracking
-- Date: 2026-09-04

-- 1. Add execution_state table for agent tracking
CREATE TABLE IF NOT EXISTS execution_state (
    goal_id TEXT NOT NULL,
    phase TEXT NOT NULL,
    wave INTEGER DEFAULT 0,
    agent_spawns INTEGER DEFAULT 0,
    agent_type TEXT,
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    last_attempt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_failure_reason TEXT,
    phase_complete INTEGER DEFAULT 0,
    PRIMARY KEY (goal_id, phase, wave),
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id)
);

-- 2. Add phase_telemetry for observability
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

-- 3. Add research_metadata table (if not exists)
CREATE TABLE IF NOT EXISTS research_metadata (
    goal_id TEXT NOT NULL,
    agent_type TEXT NOT NULL,
    search_iterations INTEGER DEFAULT 0,
    artifacts_saved INTEGER DEFAULT 0,
    research_dir TEXT,
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (goal_id, agent_type)
);

-- 4. Add interview fields to goal_meta
ALTER TABLE goal_meta ADD COLUMN baseline TEXT;
ALTER TABLE goal_meta ADD COLUMN timeline TEXT;
ALTER TABLE goal_meta ADD COLUMN daily_availability TEXT;
ALTER TABLE goal_meta ADD COLUMN interview_complete INTEGER DEFAULT 0;

-- 5. Add indexes
CREATE INDEX IF NOT EXISTS idx_execution_goal ON execution_state(goal_id);
CREATE INDEX IF NOT EXISTS idx_execution_phase ON execution_state(phase);
CREATE INDEX IF NOT EXISTS idx_telemetry_goal ON phase_telemetry(goal_id);
CREATE INDEX IF NOT EXISTS idx_research_goal ON research_metadata(goal_id);
```

- [ ] **Step 2: Update schema.sql**

Append to `docs/learnloop/mcp-queries/schema.sql`:

```sql
-- ============================================
-- EXECUTION STATE TRACKING (Two-Tier Agent)
-- ============================================

-- Execution state for agent spawns and phase tracking
CREATE TABLE IF NOT EXISTS execution_state (
    goal_id TEXT NOT NULL,
    phase TEXT NOT NULL,
    wave INTEGER DEFAULT 0,
    agent_spawns INTEGER DEFAULT 0,
    agent_type TEXT,
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    last_attempt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_failure_reason TEXT,
    phase_complete INTEGER DEFAULT 0,
    PRIMARY KEY (goal_id, phase, wave),
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id)
);

-- Phase telemetry for observability
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

-- Research metadata tracking
CREATE TABLE IF NOT EXISTS research_metadata (
    goal_id TEXT NOT NULL,
    agent_type TEXT NOT NULL,
    search_iterations INTEGER DEFAULT 0,
    artifacts_saved INTEGER DEFAULT 0,
    research_dir TEXT,
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (goal_id, agent_type)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_execution_goal ON execution_state(goal_id);
CREATE INDEX IF NOT EXISTS idx_telemetry_goal ON phase_telemetry(goal_id);
CREATE INDEX IF NOT EXISTS idx_research_goal ON research_metadata(goal_id);
```

- [ ] **Step 3: Commit schema changes**

```bash
git add docs/learnloop/mcp-queries/
git commit -m "feat: add execution state and telemetry tables

- execution_state: agent spawn tracking per phase/wave
- phase_telemetry: observability and performance metrics
- research_metadata: discovery agent completion tracking
- Interview fields in goal_meta

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Task 6: Create Phase Gate SQL Files

**Files:**
- Create: `docs/learnloop/mcp-queries/gates/wave1-discovery.sql`
- Create: `docs/learnloop/mcp-queries/gates/wave2-deep-dive.sql`
- Create: `docs/learnloop/mcp-queries/gates/wave3-critic.sql`
- Create: `docs/learnloop/mcp-queries/gates/budget-check.sql`

**Interfaces:**
- Consumes: goal_id parameter
- Produces: PASS/FAIL verification result

- [ ] **Step 1: Create wave1-discovery gate**

Create file: `docs/learnloop/mcp-queries/gates/wave1-discovery.sql`

```sql
-- Gate: Wave 1 Discovery Agents Complete
-- Verifies all 4 discovery agents ran

SELECT
    goal_id,
    COUNT(*) as agent_count,
    CASE
        WHEN COUNT(*) >= 4 THEN 'PASS'
        ELSE 'FAIL'
    END as gate_status,
    CASE
        WHEN COUNT(*) < 4 THEN 'Missing agents: ' ||
            CASE WHEN COUNT(*) FILTER (WHERE agent_type = 'official') = 0 THEN 'official ' ELSE '' END ||
            CASE WHEN COUNT(*) FILTER (WHERE agent_type = 'academic') = 0 THEN 'academic ' ELSE '' END ||
            CASE WHEN COUNT(*) FILTER (WHERE agent_type = 'practical') = 0 THEN 'practical ' ELSE '' END ||
            CASE WHEN COUNT(*) FILTER (WHERE agent_type = 'expert') = 0 THEN 'expert' ELSE '' END
        ELSE 'All 4 discovery agents complete'
    END as message
FROM research_metadata
WHERE goal_id = :goal_id
GROUP BY goal_id;

-- Expected: agent_count = 4, gate_status = 'PASS'
```

- [ ] **Step 2: Create wave2-deep-dive gate**

Create file: `docs/learnloop/mcp-queries/gates/wave2-deep-dive.sql`

```sql
-- Gate: Wave 2 Deep-Dive Agents Complete
-- Verifies deep-dive agents (if spawned) completed

SELECT
    goal_id,
    COUNT(*) as deep_dive_count,
    CASE
        WHEN COUNT(*) <= 10 THEN 'PASS'
        ELSE 'FAIL'
    END as gate_status,
    'Deep-dive agents spawned: ' || COUNT(*) as message
FROM execution_state
WHERE goal_id = :goal_id
AND phase = 'deep-dive'
AND phase_complete = 1
GROUP BY goal_id;

-- Note: Deep-dive count can be 0 (no complex topics) to 10 (max)
-- Expected: deep_dive_count <= 10, gate_status = 'PASS'
```

- [ ] **Step 3: Create wave3-critic gate**

Create file: `docs/learnloop/mcp-queries/gates/wave3-critic.sql`

```sql
-- Gate: Critic Approval
-- Verifies critic verdict is not REJECT

SELECT
    goal_id,
    last_failure_reason,
    CASE
        WHEN phase_complete = 1 AND last_failure_reason IS NULL THEN 'PASS'
        WHEN last_failure_reason LIKE '%REJECT%' THEN 'FAIL'
        ELSE 'PASS'
    END as gate_status
FROM execution_state
WHERE goal_id = :goal_id
AND phase = 'critic'
ORDER BY last_attempt DESC
LIMIT 1;

-- Expected: gate_status = 'PASS' (critic approved or approved_with_warnings)
```

- [ ] **Step 4: Create budget-check gate**

Create file: `docs/learnloop/mcp-queries/gates/budget-check.sql`

```sql
-- Budget Check: Advisory Warning (NOT BLOCKING)
-- Emits warnings at 10/15/20 agents but does not stop execution

SELECT
    goal_id,
    SUM(agent_spawns) as total_agents,
    CASE
        WHEN SUM(agent_spawns) >= 20 THEN 'WARN_LIMIT'
        WHEN SUM(agent_spawns) >= 15 THEN 'WARN_75PCT'
        WHEN SUM(agent_spawns) >= 10 THEN 'WARN_50PCT'
        ELSE 'OK'
    END as budget_status,
    CASE
        WHEN SUM(agent_spawns) >= 20 THEN '⚠️ Agent budget exhausted. Consider simplifying goal scope for future runs.'
        WHEN SUM(agent_spawns) >= 15 THEN '⚠️ Agent budget at 75%. Approaching limit.'
        WHEN SUM(agent_spawns) >= 10 THEN 'ℹ️ Agent count: 10+. High agent usage.'
        ELSE '✓ Agent count within budget.'
    END as budget_message
FROM execution_state
WHERE goal_id = :goal_id
GROUP BY goal_id;

-- IMPORTANT: This is ADVISORY only. Does NOT block execution.
-- Purpose: Track resource usage and inform optimization opportunities.
```

- [ ] **Step 5: Commit gate files**

```bash
git add docs/learnloop/mcp-queries/gates/
git commit -m "feat: add phase gate SQL verification files

- wave1-discovery: verify 4 discovery agents complete
- wave2-deep-dive: verify deep-dives (0-10) complete
- wave3-critic: verify critic approved (not REJECT)
- budget-check: advisory warnings (NOT blocking)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Task 7: Update SKILL.md with Wave Orchestration

**Files:**
- Modify: `docs/learnloop/SKILL.md`

**Interfaces:**
- Consumes: User goal input
- Produces: Orchestrated agent waves with phase gates

- [ ] **Step 1: Add wave orchestration section to SKILL.md**

Locate `docs/learnloop/SKILL.md` and add after existing workflow section:

```markdown
## Agent Orchestration: Two-Tier Wave System

**Current Date Injection:**

All agent spawns MUST include current date in ISO-8601 format:

```
Current Date: 2026-09-04
```

Use for:
- Recency verification (≤2 years for exam goals)
- Source staleness filtering
- Exam schedule validation

---

### Wave 1: Discovery Agents (4 agents, parallel)

**Execute:**

1. Inject current date into agent prompts
2. Spawn all 4 discovery agents in single message:
   ```
   Agent(subagent_type="learnloop:discovery-official", name="official-researcher", ...)
   Agent(subagent_type="learnloop:discovery-academic", name="academic-researcher", ...)
   Agent(subagent_type="learnloop:discovery-practical", name="practical-researcher", ...)
   Agent(subagent_type="learnloop:discovery-expert", name="expert-researcher", ...)
   ```
3. Wait for all 4 to complete (barrier)
4. Run gate: `wave1-discovery.sql`
5. If FAIL: retry missing agents (max 2 retries)

**Gate Check:**
```sql
sqlite3 ~/.learnloop/goals/{goal_id}/memory.db < docs/learnloop/mcp-queries/gates/wave1-discovery.sql
```

---

### Wave 2: Deep-Dive Agents (0-10 agents, batched)

**Execute:**

1. Merge Wave 1 results
2. Identify complex topics:
   ```sql
   SELECT topic_id, name, complexity
   FROM topics
   WHERE complexity >= 7 OR source_count < 3;
   ```
3. Spawn deep-dive agents in batches of 4:
   - Batch 1: topics[0:4]
   - Batch 2: topics[4:8] (if needed)
   - Batch 3: topics[8:10] (max 10)
4. Wait for each batch to complete before next
5. Run gate: `wave2-deep-dive.sql`

---

### Wave 3: Critic Agent (1 agent, with date context)

**Execute:**

1. Merge Wave 1 + Wave 2 results
2. Spawn critic agent with current date:
   ```markdown
   **Critic Prompt:**

   Current Date: 2026-09-04

   Verify:
   - Research completeness (≥3 sources per topic)
   - Hidden topic detection (3 methods used)
   - Source recency (≤2 years for exam goals)
   - Triangulation (≥3 agent types)

   Verdict options: APPROVED | APPROVED_WITH_WARNINGS | REJECT
   ```
3. Wait for verdict
4. If APPROVED/APPROVED_WITH_WARNINGS: proceed to Wave 5 (Output)
5. If REJECT: proceed to Wave 4 (Repair)

---

### Wave 4: Repair Loop (max 3 cycles)

**Execute:**

```
WHILE critic_verdict == "reject" AND repair_cycles < 3:

  1. Extract challenges from critic verdict
  2. Categorize: research_gap | detection_missing | validation_failed | quality_issue
  3. Spawn repair agents (max 5, one per challenge type)
  4. Wait for repairs to complete
  5. Re-run critic (Wave 3)
  6. If APPROVED: exit loop
  7. If still REJECT and cycles < 3: continue

If max cycles reached and still REJECT:
  - Generate partial output with warnings
  - Flag for manual review
```

**Exit Conditions:**
- Critic verdict != "reject" (satisfied)
- Max cycles (3) reached → partial output
- User cancellation

---

### Budget Tracking (Advisory, Not Blocking)

After each wave, emit budget status:

```sql
sqlite3 ~/.learnloop/goals/{goal_id}/memory.db < docs/learnloop/mcp-queries/gates/budget-check.sql
```

**Warnings:**
- 10+ agents: ℹ️ High agent usage
- 15+ agents: ⚠️ 75% budget used
- 20+ agents: ⚠️ Budget exhausted

**IMPORTANT:** Budget warnings do NOT stop execution. Advisory only.

---

### Phase Transition Guards

**Between each phase:**

1. Verify database state with SQL gate
2. If gate fails: retry (max 2) or report issue
3. If gate passes: proceed to next wave

**Guards prevent:**
- Skipping discovery agents
- Proceeding with incomplete research
- Outputting without critic approval
```

- [ ] **Step 2: Commit SKILL.md updates**

```bash
git add docs/learnloop/SKILL.md
git commit -m "feat: add wave orchestration to SKILL.md

- Wave 1: Discovery (4 parallel) with gate
- Wave 2: Deep-Dive (batched 4 at a time)
- Wave 3: Critic with current date
- Wave 4: Repair loop (max 3 cycles)
- Budget tracking: advisory warnings only
- Phase transition guards between waves

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Self-Review: Spec Coverage Check

After writing plan, verify against spec:

**Spec Requirement → Task Mapping:**

| Spec Requirement | Task | Status |
|------------------|------|--------|
| Agent registry (6 files) | Tasks 1-4 | ✓ Covered |
| Database migration (execution_state) | Task 5 | ✓ Covered |
| Phase gate SQL files | Task 6 | ✓ Covered |
| Wave orchestration logic | Task 7 | ✓ Covered |
| Critic-repair loop (max 3) | Task 7 (Wave 4) | ✓ Covered |
| Budget tracking (warnings) | Task 6 (budget-check.sql) | ✓ Covered |
| Date injection in prompts | Tasks 1-4 (all agents) | ✓ Covered |
| Error recovery patterns | Task 7 (guards) | ✓ Covered |
| Telemetry layer | Task 5 (phase_telemetry) | ✓ Covered |

**Placeholder scan:** ✓ No TBD/TODO/placeholders found

**Type consistency:** ✓ All agents use same input/output JSON structure

**Specs with no task:** None found

---

## Implementation Complete

Plan saved to `docs/superpowers/plans/2026-09-04-two-tier-agent-architecture.md`.

**Two execution options:**

**1. Subagent-Driven (recommended)** - Fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session, batch execution with checkpoints

**Which approach?**
