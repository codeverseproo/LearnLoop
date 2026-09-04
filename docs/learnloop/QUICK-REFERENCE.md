# LearnLoop v2.0 Quick Reference

**Fast lookup for common operations**

---

## Guard Checks

### Pre-WAVE1 Interview Guard
```bash
sqlite3 ~/.learnloop/goals/{goal_id}/memory.db < docs/learnloop/mcp-queries/gates/pre-wave1-interview.sql
```

| guard_status | Action |
|--------------|--------|
| `PASS` | Proceed to WAVE1 |
| `BLOCK: Stage 1-2 Interview Required` | Trigger onboarding interview |
| `BLOCK: Stage 3 Goal Interview Required` | Trigger goal interview |

### Pre-WAVE5 Output Guard
```bash
sqlite3 ~/.learnloop/goals/{goal_id}/memory.db < docs/learnloop/mcp-queries/gates/pre-wave5-output.sql
```

| guard_status | Action |
|--------------|--------|
| `PASS` | Generate syllabus |
| `BLOCK: No critic verdict found` | Route to WAVE3 |
| `BLOCK: Repair loop incomplete` | Route to WAVE4 |
| `PASS: Force approved (max cycles)` | Generate syllabus with warnings |

### Budget Check
```bash
sqlite3 ~/.learnloop/goals/{goal_id}/memory.db < docs/learnloop/mcp-queries/gates/budget-check.sql
```

| budget_status | Threshold |
|---------------|-----------|
| `OK` | < 50% |
| `WARN_50PCT` | 50% |
| `WARN_75PCT` | 75% |
| `EXHAUSTED` | 100% |
| `UNLIMITED` | No limit |

---

## Telemetry Queries

### Get All Phases
```sql
SELECT phase, wave, duration_seconds, gate_result, success
FROM phase_telemetry
WHERE goal_id = :goal_id
ORDER BY started_at;
```

### Get Average Durations
```sql
SELECT phase, AVG(duration_seconds) as avg_seconds
FROM phase_telemetry
WHERE success = 1
GROUP BY phase;
```

### Get Failed Phases
```sql
SELECT goal_id, phase, error_message, error_code
FROM phase_telemetry
WHERE success = 0
ORDER BY started_at DESC;
```

### Get Phase Duration
```sql
SELECT 
    phase,
    (julianday(completed_at) - julianday(started_at)) * 86400 as seconds
FROM phase_telemetry
WHERE goal_id = :goal_id AND phase = 'WAVE1';
```

---

## Budget Management

### Set Budget (Interview)
```sql
UPDATE goal_meta 
SET agent_budget = 20, budget_enforcement = 'warning'
WHERE goal_id = :goal_id;
```

### Budget Values
| Value | Mode |
|-------|------|
| `10` | Conservative |
| `20` | Balanced (default) |
| `50` | Aggressive |
| `-1` | Unlimited |

### Enforcement Modes
| Mode | Behavior |
|------|----------|
| `warning` | Advisory only |
| `hard_limit` | Blocks when exhausted |

---

## Interview Status

### Check Interview Complete
```sql
SELECT 
    onboarding_complete,
    goal_interview_complete,
    CASE
        WHEN onboarding_complete = 0 THEN 'BLOCKED: Need Stage 1-2'
        WHEN goal_interview_complete = 0 THEN 'BLOCKED: Need Stage 3'
        ELSE 'READY'
    END as status
FROM goal_meta
WHERE goal_id = :goal_id;
```

### Mark Interview Complete
```sql
UPDATE goal_meta 
SET 
    onboarding_complete = 1,
    goal_interview_complete = 1
WHERE goal_id = :goal_id;
```

---

## Critic Verdict

### Check Latest Verdict
```sql
SELECT verdict, confidence, warnings_count, repair_cycle
FROM critic_verdict
WHERE goal_id = :goal_id
ORDER BY created_at DESC
LIMIT 1;
```

### Insert Verdict
```sql
INSERT INTO critic_verdict (goal_id, verdict, confidence, warnings_count, challenges, repair_cycle)
VALUES (:goal_id, 'APPROVED', 0.9, 0, '[]', 0);
```

### Verdict Types
| Verdict | Action |
|---------|--------|
| `APPROVED` | Proceed to output |
| `APPROVED_WITH_WARNINGS` | Proceed with warnings |
| `REJECT` | Route to repair loop |

---

## Execution State

### Get Repair Cycles
```sql
SELECT repair_cycles 
FROM execution_state 
WHERE goal_id = :goal_id;
```

### Increment Repair Cycles
```sql
UPDATE execution_state 
SET repair_cycles = repair_cycles + 1
WHERE goal_id = :goal_id;
```

### Get Agent Spawns
```sql
SELECT SUM(agent_spawns) as total_agents
FROM execution_state
WHERE goal_id = :goal_id;
```

---

## Common Errors

| Code | Description | Fix |
|------|-------------|-----|
| E001 | Goal not found | Create goal first |
| E002 | Interview incomplete | Run interview |
| E003 | Budget exhausted | Increase budget or set unlimited |
| E501 | Critic timeout | Retry critic spawn |
| E502 | No critic verdict | Run WAVE3 first |
| E503 | Repair limit reached | Force approve or manual review |

---

## File Paths

| Resource | Path |
|----------|------|
| Goal database | `~/.learnloop/goals/{goal_id}/memory.db` |
| Schema | `docs/learnloop/mcp-queries/schema.sql` |
| Guard queries | `docs/learnloop/mcp-queries/gates/*.sql` |
| Skill instructions | `~/.claude/skills/learnloop/SKILL.md` |
| Test results | `docs/learnloop/tests/orchestrator-flow-tests.md` |

---

## Test Commands

### Create Test Database
```bash
mkdir -p ~/.learnloop/goals/test
sqlite3 ~/.learnloop/goals/test/memory.db < docs/learnloop/mcp-queries/schema.sql
```

### Run All Guards
```bash
cd ~/.learnloop/goals/test
sqlite3 memory.db < ../../../docs/learnloop/mcp-queries/gates/pre-wave1-interview.sql
sqlite3 memory.db < ../../../docs/learnloop/mcp-queries/gates/pre-wave5-output.sql
sqlite3 memory.db < ../../../docs/learnloop/mcp-queries/gates/budget-check.sql
```

### Clean Test Databases
```bash
rm -rf ~/.learnloop/goals/test-*
```

---

## Version

- **Version:** 2.0.0
- **Release:** 2026-09-04
- **Docs:** `docs/learnloop/architecture/orchestrator-v2.md`
