# LearnLoop Multi-Goal Scheduler Design

**Priority-based scheduling for parallel goal execution with resource allocation.**

---

## Overview

The multi-goal scheduler enables LearnLoop to manage multiple learning goals simultaneously, allocating agent budgets and execution slots across competing priorities.

---

## Design Principles

1. **User Priority First** - Explicit user-assigned priority overrides all heuristics
2. **Fair Resource Distribution** - No goal starves; minimum budget floor enforced
3. **Progress Awareness** - Goals near completion get slight boost
4. **Budget Isolation** - Per-goal budgets prevent cascade exhaustion

---

## Priority Queue Design

### Priority Levels

| Level | Name | Weight | Description |
|-------|------|--------|-------------|
| 0 | `critical` | 100 | User-marked urgent (exam tomorrow) |
| 1 | `high` | 75 | Active goal with recent sessions |
| 2 | `normal` | 50 | Default priority |
| 3 | `low` | 25 | Background goals, no recent activity |
| 4 | `suspended` | 0 | Paused by user or system |

### Priority Score Calculation

```sql
-- priority_score.sql
SELECT
    goal_id,
    goal_type,
    priority_level,
    CASE
        WHEN priority_level = 'critical' THEN 100
        WHEN priority_level = 'high' THEN 75
        WHEN priority_level = 'normal' THEN 50
        WHEN priority_level = 'low' THEN 25
        ELSE 0
    END
    + CASE
        WHEN EXISTS (
            SELECT 1 FROM phase_telemetry
            WHERE goal_id = gm.goal_id
            AND phase = 'WAVE5'
            AND success = 1
        ) THEN 10  -- Near completion bonus
        ELSE 0
    END
    - CASE
        WHEN last_activity_date < date('now', '-7 days') THEN 20  -- Stale penalty
        ELSE 0
    END AS priority_score
FROM goal_meta gm
LEFT JOIN streak_state ss ON gm.goal_id = ss.goal_id
WHERE onboarding_complete = 1
ORDER BY priority_score DESC, created_at ASC;
```

### Queue Structure

```
┌─────────────────────────────────────────┐
│          PRIORITY QUEUE                  │
├─────────────────────────────────────────┤
│  [critical_goals]  ← processed first     │
│  [high_goals]                            │
│  [normal_goals]                          │
│  [low_goals]                             │
│  [suspended_goals]  ← not scheduled     │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│       SCHEDULER DISPATCH                 │
├─────────────────────────────────────────┤
│  Round-robin within priority tier        │
│  Max concurrent goals: 3                 │
│  Per-goal agent limit: 4 parallel        │
└─────────────────────────────────────────┘
```

---

## Resource Allocation

### Global Constraints

| Resource | Limit | Rationale |
|----------|-------|-----------|
| Max concurrent goals | 3 | Prevents resource contention |
| Max agents per goal | 4 | Matches WAVE1 discovery pattern |
| Global agent pool | 12 | 3 goals × 4 agents |
| Default per-goal budget | 20 | Balanced mode default |

### Per-Goal Budget Pool

Each goal has a **budget pool** tracked in `goal_meta.agent_budget`:

```sql
-- budget_allocation.sql
UPDATE goal_meta
SET agent_budget = CASE
    WHEN goal_type = 'exam' AND timeline = 'intensive' THEN 50
    WHEN goal_type = 'exam' THEN 30
    WHEN goal_type = 'skill' THEN 20
    WHEN goal_type = 'degree' THEN 40
    ELSE 20
END
WHERE goal_id = :goal_id;
```

### Budget Pool vs Isolated Budgets

**Option A: Budget Pool (Recommended)**

Shared budget across all phases with per-phase tracking:

```
goal_meta.agent_budget = 20 (total)
    ├── WAVE1: 4 agents (discovery)
    ├── WAVE2: 0-10 agents (deep-dive)
    ├── WAVE3: 1 agent (critic)
    ├── WAVE4: 0-5 agents (repair, max 5 cycles)
    └── WAVE5: 1 agent (output)
```

**Advantages:**
- Flexible allocation based on complexity
- Simple budget exhaustion handling
- User sees single budget number

**Implementation:**

```sql
-- check_pool_budget.sql
SELECT
    gm.agent_budget,
    gm.budget_enforcement,
    (SELECT COUNT(*) FROM agent_spawn_log WHERE goal_id = :goal_id) as spent,
    gm.agent_budget - (SELECT COUNT(*) FROM agent_spawn_log WHERE goal_id = :goal_id) as remaining,
    CASE
        WHEN gm.agent_budget = -1 THEN 'UNLIMITED'
        WHEN (SELECT COUNT(*) FROM agent_spawn_log WHERE goal_id = :goal_id) >= gm.agent_budget THEN 'EXHAUSTED'
        ELSE 'OK'
    END as status
FROM goal_meta gm
WHERE gm.goal_id = :goal_id;
```

**Option B: Isolated Budgets**

Fixed budget per phase:

```
WAVE1: 4 agents (reserved)
WAVE2: 8 agents (reserved)
WAVE3: 2 agents (reserved)
WAVE4: 5 agents (reserved)
WAVE5: 1 agent (reserved)
TOTAL: 20 agents (pre-allocated)
```

**Advantages:**
- Guaranteed phase completion
- No single phase hogs budget

**Disadvantages:**
- Inflexible for simple goals
- Wasted budget on WAVE2 if no deep-dives needed

**Hybrid Approach (Not Recommended):**
- Reserved cores + flexible overflow
- Adds complexity without proportional benefit

---

## Round-Robin Scheduling

### Algorithm

```
1. Get eligible goals (onboarding_complete = 1, priority != 'suspended')
2. Sort by priority_score DESC, created_at ASC
3. Select top N goals (N = max_concurrent, default 3)
4. For each scheduling window (5 minutes):
   a. For each active goal in priority order:
      - Check budget remaining
      - Check available agent slots (< 4 active)
      - Spawn next phase agent
   b. If goal completes, replace from queue
5. Repeat
```

### Scheduling Window

```
┌─────────────────────────────────────────┐
│        5-MINUTE WINDOW                   │
├─────────────────────────────────────────┤
│  Min 0: Evaluate priority queue         │
│  Min 1: Spawn agents for top 3 goals    │
│  Min 2-4: Monitor agent completion      │
│  Min 5: Check for completed goals       │
│          Rotate queue if needed          │
└─────────────────────────────────────────┘
```

### Implementation

**Scheduler loop pseudo-code:**

```bash
#!/bin/bash
# scheduler.sh

MAX_CONCURRENT=3
MAX_AGENTS_PER_GOAL=4
SCHEDULING_INTERVAL=300  # 5 minutes

while true; do
    # Get active goals
    ACTIVE_GOALS=$(sqlite3 ~/.learnloop/registry.db "
        SELECT goal_id, priority_score
        FROM goal_queue_view
        WHERE status = 'active'
        ORDER BY priority_score DESC
        LIMIT $MAX_CONCURRENT
    ")

    # For each active goal
    echo "$ACTIVE_GOALS" | while read -r goal_id score; do
        # Check budget
        BUDGET_STATUS=$(check_budget "$goal_id")

        if [[ "$BUDGET_STATUS" == "EXHAUSTED" ]]; then
            echo "Goal $goal_id budget exhausted"
            continue
        fi

        # Check active agents
        ACTIVE_COUNT=$(count_active_agents "$goal_id")

        if [[ $ACTIVE_COUNT -lt $MAX_AGENTS_PER_GOAL ]]; then
            # Spawn next phase agent
            spawn_next_agent "$goal_id"
        fi
    done

    sleep $SCHEDULING_INTERVAL
done
```

---

## Conflict Resolution

### Priority Tie-Breaking

```sql
-- tie_breaker.sql
SELECT goal_id, priority_score,
    CASE
        WHEN priority_score = priority_score THEN
            -- Tie: use deadline proximity
            CASE
                WHEN deadline IS NOT NULL THEN
                    julianday(deadline) - julianday('now')
                ELSE 999
            END
        ELSE 0
    END as days_until_deadline
FROM goal_meta
WHERE goal_id IN (:tied_goals)
ORDER BY days_until_deadline ASC, created_at ASC
LIMIT 1;
```

### Resource Contention

When all goals have budget remaining but global pool exhausted:

```sql
-- contention_resolution.sql
SELECT goal_id,
    (SELECT COUNT(*) FROM agent_spawn_log WHERE goal_id = gm.goal_id) as spent,
    gm.agent_budget
FROM goal_meta gm
WHERE goal_id IN (:active_goals)
ORDER BY
    -- Prefer goals that have spent less of their budget
    (SELECT COUNT(*) FROM agent_spawn_log WHERE goal_id = gm.goal_id) * 1.0 / gm.agent_budget ASC
LIMIT 1;
```

---

## Monitoring

### Scheduler Metrics

```sql
-- scheduler_metrics.sql
SELECT
    COUNT(DISTINCT goal_id) as active_goals,
    COUNT(*) as total_active_agents,
    AVG(agent_budget) as avg_budget,
    SUM(CASE WHEN budget_status = 'EXHAUSTED' THEN 1 ELSE 0 END) as exhausted_goals
FROM goal_queue_view
WHERE status = 'active';
```

### Queue Health

```sql
-- queue_health.sql
SELECT
    priority_level,
    COUNT(*) as goal_count,
    SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active,
    SUM(CASE WHEN status = 'waiting' THEN 1 ELSE 0 END) as waiting
FROM goal_queue_view
GROUP BY priority_level
ORDER BY
    CASE priority_level
        WHEN 'critical' THEN 0
        WHEN 'high' THEN 1
        WHEN 'normal' THEN 2
        WHEN 'low' THEN 3
        ELSE 4
    END;
```

---

## Configuration

### User-Adjustable Parameters

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `max_concurrent_goals` | 3 | 1-5 | Simultaneous goals |
| `scheduler_interval` | 300s | 60-600s | Check frequency |
| `priority_boost_completion` | 10 | 0-20 | Near-completion bonus |
| `stale_penalty` | 20 | 0-30 | Inactivity penalty |

### Query for User Settings

```sql
-- Get scheduler config
SELECT key, value FROM system_config
WHERE key LIKE 'scheduler.%';
```

---

## Future Enhancements

1. **Dynamic Priority Adjustment** - Auto-promote goals with approaching deadlines
2. **Budget Borrowing** - Allow goals to lend unused budget to others
3. **Pause/Resume** - User control over goal scheduling
4. **Time-Based Scheduling** - Prefer certain goals during specific hours
5. **Dependency Graph** - Schedule prerequisite goals first

---

## Related Files

- `docs/learnloop/mcp-queries/gates/budget-check.sql` - Budget enforcement
- `docs/learnloop/architecture/orchestrator-v2.md` - State machine design
- `docs/learnloop/mcp-queries/views/goal-queue-view.sql` - Priority queue view
