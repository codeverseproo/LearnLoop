# LearnLoop Orchestrator v2.0

**State machine architecture with mandatory blocking guards, telemetry tracking, and budget enforcement.**

---

## Overview

The LearnLoop orchestrator enforces a strict state machine that prevents skipping critical stages:

1. **Mandatory 3-Stage Interview** - Cannot create goals without capturing user preferences
2. **Discovery Research** - 4 parallel agents gather comprehensive sources
3. **Deep-Dive Analysis** - Additional research on complex topics
4. **Critic Quality Gate** - Mandatory blocking review with repair loop
5. **Output Generation** - Syllabus creation only after all gates pass

---

## State Machine

```
ONBOARDING ──[GUARD G1]──> WAVE1_RUNNING
    │                          │
    │ [BLOCK if interview      │ [Spawn 4 discovery agents]
    │  incomplete]             │
    │                          ▼
    │                    WAVE1_RUNNING ──[GUARD G2]──> WAVE2_RUNNING
    │                                                      │
    │                                                      │ [Spawn 0-10 deep-dive agents]
    │                                                      ▼
    │                                                WAVE2_RUNNING ──[GUARD G3]──> WAVE3_RUNNING
    │																		  │
    │																		  │ [Spawn critic agent]
    │																		  ▼
    │																	WAVE3_RUNNING ──[GUARD G4]──> BLOCKED
    │																		  │           │
    │																		  │           └──> WAVE4_REPAIR
    │																		  │                (max 5 cycles)
    │																		  │
    │																		  └──[PASS]──> WAVE5_OUTPUT
    │																						    │
    │																						    └──> COMPLETE
    │																				(Generate Syllabus)
```

---

## Guard Reference

### G1: Pre-WAVE1 Interview Guard

**SQL:** `docs/learnloop/mcp-queries/gates/pre-wave1-interview.sql`

**Purpose:** Block agent spawns if interview incomplete

**Blocking Conditions:**
- `onboarding_complete = 0` → Trigger Stage 1-2 interview
- `goal_interview_complete = 0` → Trigger Stage 3 interview

**Query:**
```sql
SELECT
    onboarding_complete,
    goal_interview_complete,
    agent_budget,
    CASE
        WHEN onboarding_complete = 0 THEN 'BLOCK: Stage 1-2 Interview Required'
        WHEN goal_interview_complete = 0 THEN 'BLOCK: Stage 3 Goal Interview Required'
        ELSE 'PASS'
    END AS guard_status,
    CASE
        WHEN onboarding_complete = 0 THEN 'Interview incomplete. Run: /learnloop to start interview.'
        WHEN goal_interview_complete = 0 THEN 'Goal profile needed. Complete Stage 3 interview.'
        ELSE 'Interview complete. Proceed to WAVE1.'
    END AS message
FROM goal_meta
WHERE goal_id = :goal_id;
```

### G2: Post-WAVE1 Discovery Guard

**SQL:** `docs/learnloop/mcp-queries/gates/wave1-discovery.sql`

**Purpose:** Verify all 4 discovery agents completed

**Blocking Condition:**
- Missing agent results → Retry failed agents (max 2 retries)

### G3: Post-WAVE2 Deep-Dive Guard

**SQL:** `docs/learnloop/mcp-queries/gates/wave2-deep-dive.sql`

**Purpose:** Verify deep-dive agents completed (if spawned)

**Blocking Condition:**
- Deep-dive agents incomplete → Retry failed agents

### G4: Pre-WAVE5 Output Guard

**SQL:** `docs/learnloop/mcp-queries/gates/pre-wave5-output.sql`

**Purpose:** Block syllabus generation without critic approval

**Blocking Conditions:**
- No critic verdict → Route to WAVE3
- `verdict = 'REJECT'` AND `repair_cycles < 5` → Route to WAVE4 repair loop

**Query:**
```sql
SELECT
    COALESCE(cv.verdict, 'NONE') AS verdict,
    COALESCE(cv.repair_cycle, 0) AS repair_cycle,
    COALESCE(es.repair_cycles, 0) AS repair_cycles,
    CASE
        WHEN cv.verdict IS NULL THEN 'BLOCK: No critic verdict found'
        WHEN cv.verdict = 'REJECT' AND es.repair_cycles < 5 THEN 'BLOCK: Repair loop incomplete'
        WHEN cv.verdict IN ('APPROVED', 'APPROVED_WITH_WARNINGS') THEN 'PASS'
        WHEN cv.verdict = 'REJECT' AND es.repair_cycles >= 5 THEN 'PASS: Force approved (max cycles)'
        ELSE 'BLOCK: Unknown verdict state'
    END AS guard_status,
    CASE
        WHEN cv.verdict IS NULL THEN 'Critic agent not run. Complete WAVE3 first.'
        WHEN cv.verdict = 'REJECT' AND es.repair_cycles < 5 THEN 'Critic rejected. Repair needed (cycle ' || (es.repair_cycles + 1) || '/5).'
        WHEN cv.verdict = 'APPROVED' THEN 'Critic approved. Proceed to output.'
        WHEN cv.verdict = 'APPROVED_WITH_WARNINGS' THEN 'Critic approved with warnings. Proceed to output.'
        WHEN cv.verdict = 'REJECT' AND es.repair_cycles >= 5 THEN 'Max repair cycles reached. Force approving with warnings.'
        ELSE 'Unknown state. Manual review required.'
    END AS message
FROM execution_state es
LEFT JOIN critic_verdict cv ON cv.goal_id = es.goal_id
WHERE es.goal_id = :goal_id
ORDER BY cv.created_at DESC
LIMIT 1;
```

---

## Wave Execution

### Wave 1: Discovery Agents (4 agents, parallel)

**Agents:**
- `learnloop:discovery-official` - Official documentation
- `learnloop:discovery-academic` - Academic papers
- `learnloop:discovery-practical` - Practical tutorials
- `learnloop:discovery-expert` - Expert blogs/forums

**Telemetry:**
```sql
-- Start
INSERT INTO phase_telemetry (goal_id, phase, wave, started_at)
VALUES (:goal_id, 'WAVE1', 1, CURRENT_TIMESTAMP);

-- Complete
UPDATE phase_telemetry
SET completed_at = CURRENT_TIMESTAMP,
    duration_seconds = (julianday(CURRENT_TIMESTAMP) - julianday(started_at)) * 86400,
    gate_result = 'PASS',
    success = 1
WHERE goal_id = :goal_id AND phase = 'WAVE1' AND completed_at IS NULL;
```

### Wave 2: Deep-Dive Agents (0-10 agents, batched)

**Trigger:** Topics with `complexity >= 7` OR `source_count < 3`

**Batches:**
- Batch 1: topics[0:4]
- Batch 2: topics[4:8] (if needed)
- Batch 3: topics[8:10] (max 10)

### Wave 3: Critic Agent (Mandatory Blocking)

**Agent:** `learnloop:critic`

**Timeout:** 120 seconds

**Timeout Recovery Protocol:**
```
ON CRITIC_TIMEOUT (120s):
  1. INSERT INTO phase_telemetry (goal_id, phase, error_code, phase_status, success)
     VALUES (:goal_id, 'WAVE3', 'E501', 'failed', 0);
  2. Check execution_state.attempts:
     - IF attempts < max_attempts: Retry critic spawn (max 1 retry)
     - IF attempts >= max_attempts: APPROVED_WITH_WARNINGS with confidence=0.5
  3. Log timeout to agent_spawn_log with status='timeout'
```

**Verdict Storage:**
```sql
INSERT INTO critic_verdict (goal_id, verdict, confidence, warnings_count, challenges, repair_cycle)
VALUES (:goal_id, :verdict, :confidence, :warnings_count, :challenges, 0);
```

### Wave 4: Repair Loop (Max 5 Cycles)

**Trigger:** `critic_verdict = 'REJECT'`

**Process:**
1. Extract challenges from critic verdict
2. Spawn repair agents (max 5 parallel)
3. Each repair: minimum 10 WebSearch calls
4. Update topics in database
5. Increment `repair_cycles`
6. Re-run critic (back to WAVE3)

**Exit Conditions:**
- `verdict IN ('APPROVED', 'APPROVED_WITH_WARNINGS')`
- `repair_cycles >= 5` → Force approve
- Budget exhausted with hard_limit
- User cancellation

### Wave 5: Output Generation

**Output:** `00-Dashboard/Syllabus.md` in Obsidian vault

**Structure:**
- Executive Summary
- Core Topics (High Confidence)
- Hidden Topics
- Knowledge Graph
- Source Bibliography
- Warnings

---

## Budget Enforcement

### Budget Values

| Value | Mode | Description |
|-------|------|-------------|
| `10` | Conservative | Limited agent spawns |
| `20` | Balanced | Default budget |
| `50` | Aggressive | Extended research |
| `-1` | Unlimited | No constraints |

### Enforcement Modes

| Mode | Behavior |
|------|----------|
| `advisory` (default) | Warnings at thresholds, no blocking |
| `hard_limit` | Blocks agent spawns when exhausted |

### Budget Check

**SQL:** `docs/learnloop/mcp-queries/gates/budget-check.sql`

```sql
SELECT
    gm.agent_budget,
    gm.budget_enforcement,
    SUM(es.agent_spawns) as total_agents,
    CASE
        WHEN gm.agent_budget = -1 THEN 'UNLIMITED'
        WHEN SUM(es.agent_spawns) >= gm.agent_budget THEN 'EXHAUSTED'
        WHEN SUM(es.agent_spawns) >= gm.agent_budget * 0.75 THEN 'WARN_75PCT'
        WHEN SUM(es.agent_spawns) >= gm.agent_budget * 0.5 THEN 'WARN_50PCT'
        ELSE 'OK'
    END as budget_status
FROM execution_state es
JOIN goal_meta gm ON es.goal_id = gm.goal_id
WHERE es.goal_id = :goal_id
GROUP BY es.goal_id;
```

### Implementation

**Before each agent spawn:**
```bash
# Check budget
BUDGET_RESULT=$(sqlite3 ~/.learnloop/goals/{goal_id}/memory.db < docs/learnloop/mcp-queries/gates/budget-check.sql)
BUDGET_STATUS=$(echo "$BUDGET_RESULT" | awk -F'|' '{print $5}')
ENFORCEMENT=$(echo "$BUDGET_RESULT" | awk -F'|' '{print $3}')

IF BUDGET_STATUS = 'EXHAUSTED' AND ENFORCEMENT = 'hard_limit':
  echo "⚠️ Budget exhausted. Cannot spawn more agents."
  # Force approve with warnings
  # Route to WAVE5
ELSE:
  echo "📊 {BUDGET_MESSAGE}"
  # Proceed with spawn
fi
```

---

## Telemetry Layer

### Schema

```sql
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
    error_code TEXT,
    gate_result TEXT CHECK(gate_result IN ('PASS', 'FAIL', 'SKIP')),
    PRIMARY KEY (goal_id, phase, started_at)
);
```

### Tracked Metrics

| Metric | Description |
|--------|-------------|
| `started_at` | Phase start timestamp |
| `completed_at` | Phase completion timestamp |
| `duration_seconds` | Total phase duration |
| `success` | 1 = success, 0 = failure |
| `gate_result` | PASS/FAIL/SKIP |
| `error_message` | Error details if failed |
| `error_code` | E001-E699 error code |

### Query Examples

**Get all phases for a goal:**
```sql
SELECT phase, wave, duration_seconds, gate_result, success
FROM phase_telemetry
WHERE goal_id = :goal_id
ORDER BY started_at;
```

**Get average phase durations:**
```sql
SELECT phase, AVG(duration_seconds) as avg_duration
FROM phase_telemetry
WHERE success = 1
GROUP BY phase;
```

**Get failed phases:**
```sql
SELECT goal_id, phase, error_message, error_code
FROM phase_telemetry
WHERE success = 0
ORDER BY started_at DESC;
```

---

## Testing

### Test Results (2026-09-04)

All 8 orchestrator flow tests passed:

| Test | Description | Status |
|------|-------------|--------|
| 1 | Pre-WAVE1 blocks interview incomplete | ✅ PASS |
| 2 | Pre-WAVE1 passes after interview complete | ✅ PASS |
| 3 | Pre-WAVE5 blocks without critic verdict | ✅ PASS |
| 4 | Pre-WAVE5 passes with APPROVED | ✅ PASS |
| 5 | Pre-WAVE5 blocks REJECT incomplete repair | ✅ PASS |
| 6 | Pre-WAVE5 force approves max cycles | ✅ PASS |
| 7 | Telemetry tracking WAVE1-WAVE2 | ✅ PASS |
| 8 | Budget check at 50% threshold | ✅ PASS |

**Test file:** `docs/learnloop/tests/orchestrator-flow-tests.md`

---

## Error Handling

### Guard Failures

| Guard | Failure Action |
|-------|---------------|
| G1 (Interview) | Trigger interview flow |
| G2 (Wave1) | Retry failed agents (max 2) |
| G3 (Wave2) | Retry failed agents |
| G4 (Critic) | Route to repair loop |

### Error Codes

| Code | Description |
|------|-------------|
| E001-E099 | Goal errors |
| E100-E199 | Topic errors |
| E200-E299 | FSRS errors |
| E300-E399 | Vault errors |
| E400-E499 | Session errors |
| E500-E599 | Research errors |
| E600-E699 | System errors |

---

## Files Reference

### SQL Gates

- `docs/learnloop/mcp-queries/gates/pre-wave1-interview.sql`
- `docs/learnloop/mcp-queries/gates/wave1-discovery.sql`
- `docs/learnloop/mcp-queries/gates/wave2-deep-dive.sql`
- `docs/learnloop/mcp-queries/gates/pre-wave5-output.sql`
- `docs/learnloop/mcp-queries/gates/budget-check.sql`

### Schema

- `docs/learnloop/mcp-queries/schema.sql` - Full database schema with telemetry tables

### Skill Instructions

- `~/.claude/skills/learnloop/SKILL.md` - Main skill file with orchestrator implementation
