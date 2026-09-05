---
name: learnloop
description: Intent-driven learning skill for personalized education with comprehensive research capabilities. Triggers when user wants to learn topics, prepare for exams, practice skills, conduct research, or track learning progress. Compiles layered research (Academic + Official → Broad Web → Curated) into single-source summaries. Adapts to user's goals, timeline, and baseline. Use this skill whenever the user mentions learning, studying, reviewing, exam prep, skill acquisition, spaced repetition, flashcards, mastery tracking, or research compilation.
---

# LearnLoop

Intent-driven learning system with FSRS-6 spaced repetition, streak mechanics, and Obsidian integration.

---

## 1. Overview

### 8 Key Features

| Feature | Description | Benefit |
|---------|-------------|---------|
| **FSRS-6 Scheduler** | Free Spaced Repetition Scheduler algorithm | 20-30% fewer reviews than SM-2, optimal retention |
| **Streak System** | Daily engagement with freeze mechanic | 3.6x engagement via loss aversion |
| **Achievement System** | Early wins + layered difficulty | Motivation through gamification |
| **Obsidian Integration** | Per-goal vault with knowledge graph | Portable, future-proof notes |
| **Multi-Goal Isolation** | Separate SQLite per goal | Concurrent learning paths, no interference |
| **Layered Research** | Academic → Broad Web → Curated | Comprehensive, credible sources |
| **Single-Source Delivery** | One note, no external reading | Time-efficient, self-contained |
| **Claim Triangulation** | ≥3 sources per claim | Verified information with confidence scores |

### Three-Tier Memory Architecture

| Tier | Storage | Latency | Duration |
|------|---------|---------|----------|
| **HOT** | Session context (RAM) | 0ms | Session |
| **WARM** | SQLite (`~/.learnloop/goals/{goal_id}/memory.db`) | 1-5ms | Permanent |
| **COLD** | Obsidian vault (`~/Obsidian/LL-{goal-slug}/`) | 10-50ms | Permanent |

---

## 1.5 Database Initialization

Every new goal auto-initializes its SQLite database.

### Automatic Setup

On `syllabus_generation` workflow trigger:

1. **Generate goal_id** from goal name:
   - Lowercase, replace spaces with hyphens
   - Remove special characters
   - Example: "AWS Solutions Architect" → `aws-solutions-architect`

2. **Check database exists:**
   - Path: `~/.learnloop/goals/{goal_id}/memory.db`

3. **If not exists, initialize:**
   ```bash
   mkdir -p ~/.learnloop/goals/{goal_id}
   sqlite3 ~/.learnloop/goals/{goal_id}/memory.db < docs/learnloop/mcp-queries/schema.sql
   sqlite3 ~/.learnloop/goals/{goal_id}/memory.db "PRAGMA foreign_keys = ON;"
   ```

   **CRITICAL:** Foreign key enforcement must be enabled on every connection.
   Without `PRAGMA foreign_keys = ON;`, all FK constraints are advisory only.

4. **Verify initialization:**
   ```sql
   PRAGMA integrity_check;
   ```

### Database Location

| Path | Purpose |
|------|---------|
| `~/.learnloop/` | Base directory |
| `~/.learnloop/goals/{goal_id}/memory.db` | Per-goal SQLite |
| `~/.learnloop/research/{goal_id}/` | Research artifacts from discovery agents |
| `~/.learnloop/backups/` | Backup storage |

**Note:** Database initialization runs automatically on every new goal. No manual setup required.

---

## 1.6 Interview System (Mandatory 3-Stage)

**BLOCKING: No goal creation before interview complete.**

### Stage 1: Availability

**Trigger:** First skill use or new user detected

**Flow:**
1. Check `onboarding_complete` flag in goal_meta
2. If false → trigger `prompts/interviews/onboarding/availability.md`
3. Store in `goal_meta.availability_json`
4. Mark `stage_1_complete = 1`

**Questions:**
- hours_per_day: integer
- preferred_times: string (morning/afternoon/evening)
- constraints: text (work schedule, etc.)

### Stage 2: Learning Style

**Trigger:** After Stage 1 complete

**Flow:**
1. Check `stage_2_complete` flag
2. If false → trigger `prompts/interviews/onboarding/learning-style.md`
3. Store in `goal_meta.learning_style_json`
4. Mark `stage_2_complete = 1`

**Questions:**
- format_preference: video|reading|interactive
- pace: self-paced|structured
- difficulty_tolerance: conservative|moderate|aggressive

### Stage 3: Goal Profile + Budget

**Trigger:** After database initialization

**Flow:**
1. Check `goal_interview_complete` flag
2. If false → trigger `prompts/interviews/per-goal/baseline.md`
3. Store in `goal_meta.goal_profile_json`
4. Capture `agent_budget` (10/20/50/-1)
5. Mark `goal_interview_complete = 1`, `onboarding_complete = 1`

**Questions:**
- baseline_knowledge: beginner|intermediate|advanced
- timeline_weeks: integer
- intensity: relaxed|standard|intensive
- **agent_budget**: Conservative(10)|Balanced(20)|Aggressive(50)|Unlimited(-1)

### Blocking Enforcement

```markdown
IF onboarding_complete = 0:
  BLOCK execution
  RETURN: "Interview required. Continue with Stage 1?"

IF goal_interview_complete = 0:
  BLOCK goal creation
  RETURN: "Goal interview required. Continue with Stage 3?"
```

### Budget Storage

```sql
UPDATE goal_meta
SET agent_budget = :budget_value,
    budget_enforcement = 'warning',
    stage_3_complete = 1,
    goal_interview_complete = 1,
    onboarding_complete = 1
WHERE goal_id = :goal_id;
```

---

## 2. Twelve Workflows

### Planning Workflows

#### 1. syllabus_generation

Create research-based learning plan with hidden topic detection.

| Aspect | Detail |
|--------|--------|
| **Triggers** | "I want to learn X", "Create a study plan for Y", "Syllabus for Z exam" |
| **Prerequisites** | Goal identified, timeline known (optional) |
| **Steps** | See §2.1 Research-Based Syllabus Generation (9 steps) |
| **Outputs** | SQLite with all tables + topic_links + topic_sources, `00-Dashboard/Syllabus.md` |

---

### §2.1 Research-Based Syllabus Generation (9 Steps)

#### Step 1: Parse Goal (Hybrid)

**Deterministic parsing (cannot fail):**
```json
{
  "goal_id": "aws-solutions-architect",
  "goal_type": "exam",
  "subject": "AWS Solutions Architect",
  "keywords": ["AWS", "Solutions Architect", "SAA", "certification"],
  "timeline": "3 months",
  "raw_goal": "I want to pass the AWS Solutions Architect exam in 3 months"
}
```

**Pass to each agent:**
- Structured data (goal_type, subject, keywords)
- Raw goal (fallback if parsing unclear)

#### Step 2: Database Initialization

See §1.5 - Auto-initialize `~/.learnloop/goals/{goal_id}/memory.db`

#### Step 2.5: Execute Pre-WAVE1 Guard (MANDATORY BLOCKING)

**CRITICAL: This guard MUST pass before any agent spawns.**

**Execute guard query:**
```bash
GUARD_RESULT=$(sqlite3 ~/.learnloop/goals/{goal_id}/memory.db < docs/learnloop/mcp-queries/gates/pre-wave1-interview.sql)
GUARD_STATUS=$(echo "$GUARD_RESULT" | awk -F'|' '{print $4}')
```

**Guard Handling:**

| guard_status | Action |
|--------------|--------|
| `PASS` | Proceed to Step 3 |
| `BLOCK: Stage 1-2 Interview Required` | STOP. Trigger `prompts/interviews/onboarding/availability.md` |
| `BLOCK: Stage 3 Goal Interview Required` | STOP. Trigger `prompts/interviews/per-goal/baseline.md` |

**Log guard check:**
```sql
INSERT INTO phase_telemetry (goal_id, phase, gate_result, error_message)
VALUES (:goal_id, 'GUARD_G1', :guard_status, :message);
```

**CANNOT PROCEED WITHOUT PASS. No exceptions.**

#### Step 3: Launch Discovery Agents (Calibrated by Goal)

**CRITICAL: Agents MUST execute real WebSearch — no generic outputs from training data.**

**Calibration factors from interview data:**
- goal_type: affects priority of source types
- timeline_weeks + intensity: affects search depth
- baseline_knowledge: affects complexity starting point
- hours_per_day: affects topic granularity

| Goal Type | Primary Agents | Min Searches | Focus |
|-----------|----------------|--------------|-------|
| exam | official, practical | 4 each | Exam blueprints, practice tests |
| skill | practical, expert | 3 each | Tutorials, case studies |
| degree | academic, official | 5 each | Theory, curriculum |
| topic | all 4 | 2 each | Broad coverage |

**Timeline-based adjustment:**
- timeline_weeks ≤ 4: 2 searches per agent (accelerated)
- timeline_weeks 5-12: 3 searches per agent (standard)
- timeline_weeks > 12: 4 searches per agent (comprehensive)

**Intensity adjustment:**
- intensity = "intensive": +1 search per agent
- intensity = "relaxed": standard searches

**Baseline knowledge adjustment:**
- baseline_knowledge = "advanced": skip foundational topics, focus on hidden/gaps
- baseline_knowledge = "beginner": add prerequisite searches

**Agent spawning with interview params:**
```json
{
  "goal_type": "exam",
  "timeline_weeks": 12,
  "intensity": "standard",
  "baseline_knowledge": "intermediate",
  "min_searches": 3,
  "calibrated_by": [
    {"agent": "official", "priority": 1, "searches": 4},
    {"agent": "practical", "priority": 2, "searches": 4},
    {"agent": "academic", "priority": 3, "searches": 3},
    {"agent": "expert", "priority": 4, "searches": 3}
  ]
}
```

Spawn 4 agents simultaneously using `Agent` tool:

**Agent Execution Requirements:**

1. **MUST use WebSearch tool** — each agent runs calibrated minimum queries (see table above)
2. **MUST cite real URLs** — no fabricated sources
3. **MUST save research artifacts** to `~/.learnloop/research/{goal_id}/`:
   - `{agent_type}-raw-results.json` — full search outputs
   - `{agent_type}-sources.md` — curated source list with URLs
   - `{agent_type}-analysis.md` — hidden topic detection reasoning

4. **MUST record metadata** to `research_metadata` table:
   ```sql
   INSERT INTO research_metadata (goal_id, agent_type, search_iterations, research_dir, artifacts_saved)
   VALUES (:goal_id, :agent_type, :search_iterations, :research_dir, 3);
   ```

5. **If WebSearch unavailable or fails:**
   - Agent returns: `{"search_failed": true, "reason": "..."}`
   - Confidence marked as 0.2
   - Skill prompts user: "Web search unavailable. Syllabus will be less comprehensive. Continue?"

**Each agent returns:**
- topics[] with sources (real URLs)
- hidden_topics[] with detection method
- prerequisites{}
- related_topics{}
- cross_domain{}
- confidence score (based on actual search results)
- search_iterations: number (must be ≥ calibrated minimum for valid research)

#### Step 4: Merge Results

**Merge logic:**

1. **Union all topics** (dedupe by fuzzy match, threshold 0.85 similarity)

2. **Conflict Resolution:**
   - If agents disagree on topic existence: require ≥2 agents to include
   - If agents disagree on complexity: use weighted average by confidence
   - If agents disagree on prerequisites: union all + flag for user review

3. **Confidence Weighting:**
   ```
   confidence = avg(agent.confidence) × min(1.0, source_count / 3)
   ```
   - **High confidence:** topic in ≥3 source types (official/academic/practical/expert)
   - **Medium confidence:** topic in 2 source types
   - **Low confidence:** topic in 1 source type (flag for verification)

4. **Triangulation:**
   - For each claim about a topic: require ≥3 independent sources
   - Sources from same domain count as 1
   - Store triangulation score in `topics.confidence`

5. **Hidden Topics:**
   - Collect from all agents
   - Dedupe by name similarity (fuzzy match)
   - Tag with detection methods: `complexity_analysis`, `error_pattern`, `expert_practice`

6. **Union all prerequisite, related, and cross-domain links**

**Fail-safety:**
- If 1 agent fails: proceed with 3 agents, note in warnings
- If 2+ agents fail: prompt user to retry

#### Step 5: Build Knowledge Graph

**Create links in SQLite:**

| Link Type | Source | Storage |
|-----------|--------|---------|
| prerequisite | Agents (prerequisites{}) | `prerequisites` table |
| enabled_by | Derived (reverse of prerequisite) | `topic_links` table |
| related_to | Agents (related_topics{}) | `topic_links` table |
| cross_domain | Agents (cross_domain{}) | `topic_links` table |

**Insert queries:**
```sql
-- Prerequisites
INSERT INTO prerequisites (topic_id, prerequisite_id) VALUES (?, ?);

-- Other links
INSERT INTO topic_links (from_topic, to_topic, link_type, confidence)
VALUES (?, ?, 'related_to', ?);
```

#### Step 6: Run Critic Loop (Max 3 Rounds)

Launch critic agent with merged research:
- Read: `prompts/critic-agent.md`
- Input: merged JSON from Step 4
- Output: verdict + challenges

**Critic verdict handling:**
- `reject`: Identify gaps from challenges → re-research specific topics → back to Step 3 (max 2 re-research rounds)
- `approve_with_warnings`: Present warnings to user → user accepts or requests fixes
- `approve`: Proceed to Step 7

**Max iterations:**
- 3 critic rounds total
- If still rejected after 3: force approve with warnings

#### Step 7: Check Satisfaction Criteria

Verify 7 criteria using SQL queries from `research.sql`:

| # | Criterion | Pass Threshold | SQL Query |
|---|-----------|----------------|-----------|
| 1 | Minimum sources | ≥3 per core topic | `SELECT ... HAVING source_count < 3` |
| 2 | Hidden topic coverage | All 3 detection methods ran | `SELECT ... detection_method` |
| 3 | Prerequisites checked | All topics have entry | `SELECT ... WHERE p.id IS NULL` |
| 4 | Critic approved | No critical challenges | Check verdict = "approve" |
| 5 | Cross-validation | ≥50% topic overlap | `SELECT ... overlap_ratio` |
| 6 | Recency | Sources ≤2 years old | `SELECT ... avg_age_months` |
| 7 | Goal type fit | Topic count matches | `SELECT ... fit_status` |

**Verification queries:**

1. **Minimum sources:**
   ```sql
   SELECT topic_id, name, COUNT(ts.id) AS source_count
   FROM topics t LEFT JOIN topic_sources ts ON t.id = ts.topic_id
   WHERE t.is_hidden = 0 GROUP BY t.id HAVING source_count < 3;
   ```

2. **Hidden topic detection:**
   ```sql
   SELECT CASE WHEN COUNT(DISTINCT detection_method) = 3 THEN 1 ELSE 0 END
   FROM topics WHERE is_hidden = 1 AND detection_method IS NOT NULL;
   ```

3. **Prerequisites coverage:**
   ```sql
   SELECT t.topic_id, t.name FROM topics t
   LEFT JOIN prerequisites p ON t.id = p.topic_id
   WHERE p.id IS NULL AND t.is_hidden = 0;
   ```

5. **Cross-validation:**
   ```sql
   SELECT CAST(COUNT(DISTINCT ts1.topic_id) AS REAL) /
   (SELECT COUNT(*) FROM topics WHERE is_hidden = 0) AS overlap_ratio
   FROM topic_sources ts1 WHERE EXISTS (
     SELECT 1 FROM topic_sources ts2
     WHERE ts2.topic_id = ts1.topic_id AND ts2.source_type != ts1.source_type
   );
   ```

6. **Recency:**
   ```sql
   SELECT AVG((julianday('now') - julianday(source_date)) / 30) AS avg_age_months
   FROM topic_sources WHERE source_date IS NOT NULL;
   ```

7. **Goal type fit:**
   ```sql
   SELECT goal_type, COUNT(*) AS topic_count,
   CASE goal_type WHEN 'exam' THEN CASE WHEN COUNT(*) BETWEEN 30 AND 60 THEN 'PASS' ELSE 'FAIL' END ... END
   FROM topics WHERE is_hidden = 0;
   ```

**If criteria fail:**
- Critical: Re-research (max 2 rounds)
- Warnings: Proceed with flags

#### Step 7.5: Execute Pre-WAVE5 Guard (MANDATORY BLOCKING)

**CRITICAL: This guard MUST pass before syllabus generation.**

**Execute guard query:**
```bash
GUARD_RESULT=$(sqlite3 ~/.learnloop/goals/{goal_id}/memory.db < docs/learnloop/mcp-queries/gates/pre-wave5-output.sql)
GUARD_STATUS=$(echo "$GUARD_RESULT" | awk -F'|' '{print $4}')
```

**Guard Handling:**

| guard_status | Action |
|--------------|--------|
| `PASS` | Proceed to Step 8 |
| `PASS: Force approved (max cycles)` | Proceed to Step 8 with warning banner |
| `BLOCK: No critic verdict found` | STOP. Route to WAVE3 → spawn critic |
| `BLOCK: Repair loop incomplete` | STOP. Route to WAVE4 → repair loop |

**Log guard check:**
```sql
INSERT INTO phase_telemetry (goal_id, phase, gate_result, error_message)
VALUES (:goal_id, 'GUARD_G4', :guard_status, :message);
```

**CANNOT GENERATE OUTPUT WITHOUT PASS. No exceptions.**

#### Step 8: Generate Syllabus

**Log phase start:**
```sql
INSERT INTO phase_telemetry (goal_id, phase, wave, started_at)
VALUES (:goal_id, 'WAVE5_OUTPUT', 5, CURRENT_TIMESTAMP);
```

**Create `00-Dashboard/Syllabus.md` in Obsidian vault:**

Structure:
```markdown
# {Goal Name} Syllabus

**Generated:** {date}
**Goal Type:** {type}
**Timeline:** {timeline}
**Total Topics:** {n}
**Hidden Topics Found:** {m}

---

## Executive Summary
{Synthesis of research}

---

## Core Topics (High Confidence)
| # | Topic | Prerequisites | Sources | Confidence |
|---|-------|---------------|---------|------------|
...

## Hidden Topics
| # | Topic | Detection Method | Reason |
|---|-------|------------------|--------|
...

## Knowledge Graph
### Prerequisite Chain
{ASCII tree}

### Related Topics
{Bulleted lists}

### Cross-Domain Bridges
{Bulleted lists}

---

## Source Bibliography
{Table by topic}

---

## Warnings
{Any criteria warnings}
```

**Log phase complete after syllabus generation:**
```sql
UPDATE phase_telemetry
SET completed_at = CURRENT_TIMESTAMP,
    duration_seconds = (julianday(CURRENT_TIMESTAMP) - julianday(started_at)) * 86400,
    gate_result = 'PASS',
    success = 1
WHERE goal_id = :goal_id AND phase = 'WAVE5_OUTPUT' AND completed_at IS NULL;
```

#### Step 9: Store in SQLite

**Insert topics:**
```sql
INSERT INTO topics (topic_id, name, confidence, source_count, is_hidden, detection_method, status)
VALUES (?, ?, ?, ?, ?, ?, 'pending');

INSERT INTO topic_sources (topic_id, source_type, source_title, source_url, source_date)
VALUES (?, ?, ?, ?, ?);

INSERT INTO topic_links (from_topic, to_topic, link_type, confidence, source)
VALUES (?, ?, ?, ?, ?);

INSERT INTO prerequisites (topic_id, prerequisite_id)
VALUES (?, ?);
```

**Update goal_meta:**
```sql
UPDATE goal_meta
SET total_topics = (SELECT COUNT(*) FROM topics WHERE is_hidden = 0),
    mastered_topics = 0
WHERE goal_id = ?;

INSERT INTO streak_state (goal_id) VALUES (?);
```

---

## Research Output Example

```json
{
  "satisfied": true,
  "criteria": {
    "sources": {"pass": true, "avg_per_topic": 4.2},
    "hidden_detection": {"pass": true, "methods_run": 3, "found": 12},
    "prerequisites": {"pass": true, "coverage": 0.95},
    "critic": {"pass": true, "rounds": 2, "warnings": 3},
    "cross_validation": {"pass": true, "overlap": 0.52},
    "recency": {"pass": true, "avg_age_months": 8},
    "goal_fit": {"pass": true, "topic_count": 45, "goal_type": "exam"}
  },
  "warnings": ["Topic 'Edge Cases' has 2 sources only"]
}
```

#### 2. diagnostic_assessment

Evaluate baseline knowledge before starting.

| Aspect | Detail |
|--------|--------|
| **Triggers** | "Test my knowledge of X", "What do I know about Y", "Assess my baseline" |
| **Prerequisites** | Goal exists with topics |
| **Steps** | 1. Select sample topics from syllabus <br> 2. Generate assessment questions <br> 3. Score responses <br> 4. Calculate baseline mastery per topic <br> 5. Update topics table with initial mastery <br> 6. Skip known topics, flag weak areas |
| **Outputs** | Updated mastery values, `Diagnostic-Report.md` |

#### 3. study_schedule_optimization

Optimize daily/weekly study schedule.

| Aspect | Detail |
|--------|--------|
| **Triggers** | "Optimize my schedule", "When should I study", "Best time for review" |
| **Prerequisites** | Active goal with topics, user availability |
| **Steps** | 1. Load review queue (overdue items) <br> 2. Calculate priority scores (retrievability - 0.9) <br> 3. Consider user constraints (time, energy) <br> 4. Apply spaced repetition spacing <br> 5. Generate daily/weekly blocks <br> 6. Write schedule to vault |
| **Outputs** | `20-Review-Queue/Due-{date}.md`, schedule recommendations |

### Learning Workflows

#### 4. learning_session

Learn a new topic.

| Aspect | Detail |
|--------|--------|
| **Triggers** | "Learn X", "Teach me Y", "Start topic Z", "Continue learning" |
| **Prerequisites** | Topic exists in syllabus |
| **Steps** | 1. Load topic state from SQLite <br> 2. Activate prior knowledge (related topics) <br> 3. Present concept with explanation <br> 4. Generate practice problems <br> 5. Assess understanding <br> 6. Update FSRS state <br> 7. Write/update vault note |
| **Outputs** | Updated `fsrs_state` table, `10-Active-Topics/{topic_id}.md` |

#### 5. prior_knowledge_activation

Activate related knowledge before learning.

| Aspect | Detail |
|--------|--------|
| **Triggers** | "What should I know first", "Prerequisites for X", "Connect Y to what I know" |
| **Prerequisites** | Topic identified |
| **Steps** | 1. Query prerequisites table <br> 2. Check mastery of prerequisite topics <br> 3. Present review material for weak prerequisites <br> 4. Generate bridging questions <br> 5. Create concept map |
| **Outputs** | Prerequisite review, concept map in note |

#### 6. metacognitive_reflection

Reflect on learning process.

| Aspect | Detail |
|--------|--------|
| **Triggers** | "Reflect on my learning", "What worked", "How did I do" |
| **Prerequisites** | Completed sessions exist |
| **Steps** | 1. Load session history <br> 2. Analyze performance patterns <br> 3. Identify successful strategies <br> 4. Flag struggling areas <br> 5. Generate reflection prompts <br> 6. Write reflection note |
| **Outputs** | `50-Resources/Reflection-{date}.md` |

### Review Workflows

#### 7. review_session

Spaced repetition review.

| Aspect | Detail |
|--------|--------|
| **Triggers** | "Review", "What's due", "Spaced repetition", "Flashcards" |
| **Prerequisites** | Overdue topics exist |
| **Steps** | 1. Query topics WHERE next_review <= today <br> 2. Calculate priority (retrievability - 0.9) <br> 3. Sort by priority (lowest = most urgent) <br> 4. Present topic for review <br> 5. Collect performance rating <br> 6. Update FSRS state via scheduler <br> 7. Schedule next review |
| **Outputs** | Updated `fsrs_state`, `topics.next_review`, session record |

#### 8. elaborative_interrogation

Deep "why" and "how" questions.

| Aspect | Detail |
|--------|--------|
| **Triggers** | "Why does X work", "Explain the mechanism", "Deep dive into Y" |
| **Prerequisites** | Topic learned |
| **Steps** | 1. Load topic content <br> 2. Generate "why" questions <br> 3. Prompt for explanations <br> 4. Identify knowledge gaps <br> 5. Provide elaborated answers <br> 6. Update mastery with deeper understanding |
| **Outputs** | Extended note with Q&A, mastery update |

### Practice Workflows

#### 9. practice_session

Practice problems on a topic.

| Aspect | Detail |
|--------|--------|
| **Triggers** | "Practice X", "Give me problems on Y", "Test myself" |
| **Prerequisites** | Topic learned |
| **Steps** | 1. Load topic concepts <br> 2. Generate problems with varying difficulty <br> 3. Present problem, collect answer <br> 4. Score and provide feedback <br> 5. Calculate performance <br> 6. Update mastery and FSRS state |
| **Outputs** | Session record with performance, mastery update |

#### 10. interleaved_practice

Mixed problem sets across topics.

| Aspect | Detail |
|--------|--------|
| **Triggers** | "Mixed practice", "Random problems", "Interleaved review" |
| **Prerequisites** | Multiple active topics |
| **Steps** | 1. Select topics from same domain <br> 2. Randomize problem order (interleaving) <br> 3. Present mixed problems <br> 4. Score per topic <br> 5. Update FSRS states <br> 6. Track cross-topic interference effects |
| **Outputs** | Multi-topic session record, aggregated performance |

### Status Workflows

#### 11. progress_dashboard

View mastery and streak.

| Aspect | Detail |
|--------|--------|
| **Triggers** | "How am I doing", "Show progress", "Dashboard", "Stats" |
| **Prerequisites** | Active goal |
| **Steps** | 1. Query goal_meta for totals <br> 2. Count mastered/in_progress/pending <br> 3. Load streak_state <br> 4. Calculate percentages <br> 5. Generate visual progress bar <br> 6. Write/update dashboard |
| **Outputs** | `00-Dashboard/Progress.md` |

### Dynamic Workflows

#### 12. current_affairs_digest

Daily current events (exam prep).

| Aspect | Detail |
|--------|--------|
| **Triggers** | "Current affairs", "News for exam", "Today's events" |
| **Prerequisites** | Exam goal type |
| **Steps** | 1. WebSearch for current events relevant to exam <br> 2. Filter by exam syllabus topics <br> 3. Summarize key developments <br> 4. Link to syllabus concepts <br> 5. Write daily digest note |
| **Outputs** | `50-Resources/Current-Affairs-{date}.md` |

---

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

1. **Log phase start:**
   ```sql
   INSERT INTO phase_telemetry (goal_id, phase, wave, started_at)
   VALUES (:goal_id, 'WAVE1', 1, CURRENT_TIMESTAMP);
   ```

2. Inject current date into agent prompts
3. Spawn all 4 discovery agents in single message:
   ```
   Agent(subagent_type="learnloop:discovery-official", name="official-researcher", ...)
   Agent(subagent_type="learnloop:discovery-academic", name="academic-researcher", ...)
   Agent(subagent_type="learnloop:discovery-practical", name="practical-researcher", ...)
   Agent(subagent_type="learnloop:discovery-expert", name="expert-researcher", ...)
   ```

4. Wait for all 4 to complete (barrier)
5. Run gate: `wave1-discovery.sql`
6. If FAIL: retry missing agents (max 2 retries)
7. **Log phase complete:**
   ```sql
   UPDATE phase_telemetry
   SET completed_at = CURRENT_TIMESTAMP,
       duration_seconds = (julianday(CURRENT_TIMESTAMP) - julianday(started_at)) * 86400,
       gate_result = 'PASS',
       success = 1
   WHERE goal_id = :goal_id AND phase = 'WAVE1' AND completed_at IS NULL;
   ```

**Gate Check:**
```sql
sqlite3 ~/.learnloop/goals/{goal_id}/memory.db < docs/learnloop/mcp-queries/gates/wave1-discovery.sql
```

---

### Wave 2: Deep-Dive Agents (0-10 agents, batched)

**Execute:**

1. **Log phase start:**
   ```sql
   INSERT INTO phase_telemetry (goal_id, phase, wave, started_at)
   VALUES (:goal_id, 'WAVE2', 2, CURRENT_TIMESTAMP);
   ```

2. Merge Wave 1 results
3. Identify complex topics:
   ```sql
   SELECT topic_id, name, complexity
   FROM topics
   WHERE complexity >= 7 OR source_count < 3;
   ```
4. Spawn deep-dive agents in batches of 4:
   - Batch 1: topics[0:4]
   - Batch 2: topics[4:8] (if needed)
   - Batch 3: topics[8:10] (max 10)
5. Wait for each batch to complete before next
6. Run gate: `wave2-deep-dive.sql`
7. **Log phase complete:**
   ```sql
   UPDATE phase_telemetry
   SET completed_at = CURRENT_TIMESTAMP,
       duration_seconds = (julianday(CURRENT_TIMESTAMP) - julianday(started_at)) * 86400,
       gate_result = 'PASS',
       success = 1
   WHERE goal_id = :goal_id AND phase = 'WAVE2' AND completed_at IS NULL;
   ```

---

### Wave 3: Critic Agent (Mandatory Blocking)

**Execute:**

1. **Log phase start:**
   ```sql
   INSERT INTO phase_telemetry (goal_id, phase, wave, started_at)
   VALUES (:goal_id, 'WAVE3', 3, CURRENT_TIMESTAMP);
   ```

2. Merge Wave 1 + Wave 2 results into JSON
3. Spawn critic agent with current date:
   ```markdown
   Current Date: {current_date}
   Agent: learnloop:critic
   Input: merged_research.json
   ```
4. Wait for verdict (timeout: 120s)
5. Store verdict in `critic_verdict` table:
   ```sql
   INSERT INTO critic_verdict (goal_id, verdict, confidence, warnings_count, challenges, repair_cycle)
   VALUES (:goal_id, :verdict, :confidence, :warnings_count, :challenges, 0);
   ```
6. Run gate: `wave3-critic.sql`
7. If gate_status = 'RETRY' → Wave 4 (Repair)
8. If gate_status = 'PASS' → Wave 5 (Output)
9. If gate_status = 'FORCE_APPROVE' → Wave 5 with warnings
10. **Log phase complete:**
    ```sql
    UPDATE phase_telemetry
    SET completed_at = CURRENT_TIMESTAMP,
        duration_seconds = (julianday(CURRENT_TIMESTAMP) - julianday(started_at)) * 86400,
        gate_result = :gate_status,
        success = CASE WHEN :gate_status IN ('PASS', 'FORCE_APPROVE') THEN 1 ELSE 0 END
    WHERE goal_id = :goal_id AND phase = 'WAVE3' AND completed_at IS NULL;
    ```

### Wave 4: Repair Loop (Max 5 Cycles)

**Execute:**

```
repair_cycles = SELECT repair_cycles FROM execution_state WHERE goal_id = :goal_id

-- Log repair loop start
INSERT INTO phase_telemetry (goal_id, phase, wave, started_at)
VALUES (:goal_id, 'WAVE4_REPAIR', 4, CURRENT_TIMESTAMP);

WHILE critic_verdict = 'REJECT' AND repair_cycles < 5:

  1. Check budget remaining:
     user_budget = SELECT agent_budget FROM goal_meta WHERE goal_id = :goal_id
     agents_spawned = SELECT SUM(agent_spawns) FROM execution_state WHERE goal_id = :goal_id

     IF user_budget != -1 AND agents_spawned >= user_budget AND budget_enforcement = 'hard_limit':
       FORCE APPROVED_WITH_WARNINGS
       EXIT LOOP

  2. Extract challenges from critic verdict
  3. Spawn repair agents (max 5 parallel):
     ```
     for challenge in challenges[:5]:
       Agent(subagent_type="learnloop:repair",
             name="repair-{topic}",
             prompt="Current Date: {current_date}\nCycle: {repair_cycles + 1}/5\nChallenge: {challenge}")
     ```
  4. Each repair: minimum 10 WebSearch calls
  5. Update topics in database
  6. Increment repair_cycles:
     ```sql
     UPDATE execution_state
     SET repair_cycles = repair_cycles + 1
     WHERE goal_id = :goal_id;
     ```
  7. Re-run critic (Wave 3)
  8. If APPROVED → EXIT LOOP

IF repair_cycles >= 5:
  Force APPROVED_WITH_WARNINGS
  Log unresolved challenges
  Proceed to Wave 5 (Output)

-- Log repair loop complete
UPDATE phase_telemetry
SET completed_at = CURRENT_TIMESTAMP,
    duration_seconds = (julianday(CURRENT_TIMESTAMP) - julianday(started_at)) * 86400,
    gate_result = CASE WHEN repair_cycles >= 5 THEN 'FORCE_APPROVE' ELSE 'PASS' END,
    success = 1
WHERE goal_id = :goal_id AND phase = 'WAVE4_REPAIR' AND completed_at IS NULL;
```

**Exit Conditions:**
- critic_verdict IN ('APPROVED', 'APPROVED_WITH_WARNINGS')
- repair_cycles >= 5 → force approve
- User cancellation
- Budget exhausted with hard_limit enforcement

---

### Budget Tracking (Advisory, Not Blocking)

**After each wave, emit budget status:**

```bash
BUDGET_RESULT=$(sqlite3 ~/.learnloop/goals/{goal_id}/memory.db < docs/learnloop/mcp-queries/gates/budget-check.sql)
BUDGET_STATUS=$(echo "$BUDGET_RESULT" | awk -F'|' '{print $5}')
BUDGET_MESSAGE=$(echo "$BUDGET_RESULT" | awk -F'|' '{print $6}')
```

**Budget Status Values:**
- `UNLIMITED`: No budget constraint (agent_budget = -1)
- `OK`: Within budget (<50% used)
- `WARN_50PCT`: 50% threshold reached
- `WARN_75PCT`: 75% threshold reached
- `EXHAUSTED`: Budget exhausted (hard_limit may block)

**Emit warnings to user:**
```markdown
📊 Budget Status: {budget_message}
```

**Hard Limit Enforcement:**
When `budget_enforcement = 'hard_limit'` AND `budget_status = 'EXHAUSTED'`:
- Block further agent spawns
- Force APPROVED_WITH_WARNINGS
- Proceed to output generation

**Implementation in Wave Execution:**

Each wave checks budget BEFORE spawning agents:

```bash
# Pre-spawn budget check
BUDGET_RESULT=$(sqlite3 ~/.learnloop/goals/{goal_id}/memory.db < docs/learnloop/mcp-queries/gates/budget-check.sql)
BUDGET_STATUS=$(echo "$BUDGET_RESULT" | awk -F'|' '{print $5}')
ENFORCEMENT=$(echo "$BUDGET_RESULT" | awk -F'|' '{print $3}')

IF BUDGET_STATUS = 'EXHAUSTED' AND ENFORCEMENT = 'hard_limit':
  echo "⚠️ Budget exhausted. Cannot spawn more agents."
  echo "Force approving with warnings."
  # Route to Wave 5
ELSE:
  # Proceed with agent spawn
  echo "📊 {BUDGET_MESSAGE}"
fi
```

**IMPORTANT:** Budget warnings do NOT stop execution unless `budget_enforcement = 'hard_limit'`. User can choose advisory (default) or hard_limit mode during interview.

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

---

## State Machine: Execution Flow

```
ONBOARDING ──[GUARD G1: interview?]──> BLOCKED
    │                                        │
    │                                        └── Trigger Interview Stage 1-3
    │
    └──[PASS G1]──> WAVE1_RUNNING
                        │
                        ├── Spawn 4 discovery agents (parallel)
                        │
WAVE1_RUNNING ──[GUARD G2: wave1_gate?]──> WAVE2_RUNNING
                        │                          │
                        │                          ├── Identify complex topics (SQL)
                        │                          ├── Spawn 0-10 deep-dive agents
                        │                          │
                        │                     WAVE2_RUNNING ──[GUARD G3: wave2_gate?]──> WAVE3_RUNNING
                        │                                                          │
                        │                                                          ├── Spawn critic agent
                        │                                                          ├── Wait for verdict
                        │                                                          │
                        │                                                     WAVE3_RUNNING ──[GUARD G4: critic?]──> BLOCKED
                        │                                                          │                           │
                        │                                                          │                           └── Route to WAVE4_REPAIR
                        │                                                          │
                        │                                                          └──[PASS G4]──> WAVE5_OUTPUT
                        │                                                                             │
WAVE4_REPAIR (loop, max 5 cycles)                                             │
    │                                                                          └── Generate Syllabus ──> COMPLETE
    ├── repair_cycles < 5 → re-spawn critic → WAVE3_RUNNING
    │
    └── repair_cycles >= 5 → WAVE5_OUTPUT (forced)
```

**State Transitions with Guards:**

| Current State | Guard | Next State | Condition |
|---------------|-------|------------|-----------|
| ONBOARDING | G1 | BLOCKED | `onboarding_complete = 0` |
| ONBOARDING | G1 | WAVE1_RUNNING | `onboarding_complete = 1` |
| WAVE1_RUNNING | G2 | WAVE1_RUNNING | `gate_status = 'FAIL'` (retry) |
| WAVE1_RUNNING | G2 | WAVE2_RUNNING | `gate_status = 'PASS'` |
| WAVE2_RUNNING | G3 | WAVE2_RUNNING | `gate_status = 'FAIL'` (retry) |
| WAVE2_RUNNING | G3 | WAVE3_RUNNING | `gate_status = 'PASS'` |
| WAVE3_RUNNING | G4 | BLOCKED | `verdict = 'REJECT' AND repair_cycles < 5` |
| WAVE3_RUNNING | G4 | WAVE5_OUTPUT | `verdict IN ('APPROVED', 'APPROVED_WITH_WARNINGS')` |
| WAVE3_RUNNING | G4 | WAVE5_OUTPUT | `verdict = 'REJECT' AND repair_cycles >= 5` (forced) |
| WAVE4_REPAIR | - | WAVE3_RUNNING | `repair_cycles < 5` |
| WAVE4_REPAIR | - | WAVE5_OUTPUT | `repair_cycles >= 5` (forced) |
| WAVE5_OUTPUT | - | COMPLETE | Syllabus generated |

---

## Guard Reference: Mandatory Checkpoints

### Guard Execution Order

| Order | Guard | SQL Query | Blocking Condition |
|-------|-------|-----------|-------------------|
| G1 | Pre-WAVE1 | `gates/pre-wave1-interview.sql` | `onboarding_complete = 0` OR `goal_interview_complete = 0` |
| G2 | Pre-WAVE2 | `gates/wave1-discovery.sql` | Discovery agents incomplete |
| G3 | Pre-WAVE3 | `gates/wave2-deep-dive.sql` | Deep-dives incomplete (if spawned) |
| G4 | Pre-WAVE5 | `gates/pre-wave5-output.sql` | No critic verdict OR verdict = 'REJECT' with repair_cycles < 5 |

### Guard Enforcement Pattern

**Every wave transition MUST execute guards:**

1. **Before WAVE1:**
   ```bash
   sqlite3 ~/.learnloop/goals/{goal_id}/memory.db < docs/learnloop/mcp-queries/gates/pre-wave1-interview.sql
   ```
   - IF `guard_status LIKE 'BLOCK:%'` → STOP, RETURN message, trigger interview
   - IF `guard_status = 'PASS'` → Proceed to spawn discovery agents

2. **Before WAVE3 (after WAVE2 gate passes):**
   - Verify `wave2_gate_status = 'PASS'` from previous gate
   - Spawn critic agent

3. **Before WAVE5:**
   ```bash
   sqlite3 ~/.learnloop/goals/{goal_id}/memory.db < docs/learnloop/mcp-queries/gates/pre-wave5-output.sql
   ```
   - IF `guard_status LIKE 'BLOCK:%'` → STOP, route to WAVE4 repair
   - IF `guard_status = 'PASS'` → Generate syllabus output

4. **Log every guard check:**
   ```sql
   INSERT INTO phase_telemetry (goal_id, phase, gate_result, error_message)
   VALUES (:goal_id, 'GUARD_CHECK', :guard_status, :message);
   ```

### Guard Failures: User Actions

| Guard | Failure Action | User Prompt |
|-------|---------------|-------------|
| G1 (Interview) | Trigger interview flow | "Interview required. Starting Stage 1?" |
| G2 (Wave1) | Retry failed agents | "Discovery incomplete. Retry with 4 agents?" |
| G3 (Wave2) | Retry deep-dives | "Deep-dive incomplete. Retry?" |
| G4 (Critic) | Route to repair | "Critic rejected. Starting repair cycle {n}/5?" |

**CRITICAL: Guards are BLOCKING. Cannot skip or bypass.**

---

## 3. MCP Query Templates

All data operations use SQLite MCP queries from `docs/learnloop/mcp-queries/`.

### Usage Pattern

```
User trigger → SKILL.md → mcp__sqlite__query → Return
```

### Query Files

| File | Purpose | Workflows |
|------|---------|-----------|
| schema.sql | Database initialization | New goal setup |
| fsrs.sql | FSRS-6 calculations | Review, Learning |
| learning.sql | Learning sessions | learning_session |
| review.sql | Review management | review_session |
| practice.sql | Practice tracking | practice_session |
| research.sql | Research storage | research |
| streak.sql | Gamification | progress_dashboard |
| backup.sql | Safety | Manual trigger |

---

## 4. 50+ Natural Language Triggers

### Learning Intents (15)

| Trigger | Workflow |
|---------|-----------|
| "I want to learn [topic]" | syllabus_generation |
| "Teach me [subject]" | learning_session |
| "Start learning [topic]" | learning_session |
| "Continue with my [goal]" | learning_session |
| "What's next in [subject]" | learning_session |
| "I need to understand [concept]" | learning_session |
| "Explain [topic] to me" | learning_session |
| "Help me learn [skill]" | learning_session |
| "Walk me through [topic]" | learning_session |
| "I'm studying for [exam]" | syllabus_generation |
| "Prepare me for [certification]" | syllabus_generation |
| "I have a test on [subject]" | diagnostic_assessment |
| "Assess my [topic] knowledge" | diagnostic_assessment |
| "What do I know about [subject]" | diagnostic_assessment |

### Review Intents (12)

| Trigger | Workflow |
|---------|-----------|
| "Review my flashcards" | review_session |
| "What's due for review" | review_session |
| "Spaced repetition" | review_session |
| "Time to review" | review_session |
| "I need to practice [topic]" | review_session |
| "Quiz me on [subject]" | review_session |
| "Test my retention" | review_session |
| "Show me overdue items" | review_session |
| "What should I review today" | review_session |
| "Run my daily review" | review_session |
| "Flashcard time" | review_session |
| "Check my memory on [topic]" | review_session |

### Practice Intents (10)

| Trigger | Workflow |
|---------|-----------|
| "Give me practice problems" | practice_session |
| "I want to practice [topic]" | practice_session |
| "Test myself on [subject]" | practice_session |
| "Mixed practice session" | interleaved_practice |
| "Random problems from [topics]" | interleaved_practice |
| "Interleaved practice" | interleaved_practice |
| "Drill [concept]" | practice_session |
| "More problems on [topic]" | practice_session |
| "Challenge me" | practice_session |
| "Let's solve problems" | practice_session |

### Status Intents (8)

| Trigger | Workflow |
|---------|-----------|
| "How am I doing" | progress_dashboard |
| "Show my progress" | progress_dashboard |
| "Dashboard" | progress_dashboard |
| "Stats for [goal]" | progress_dashboard |
| "What's my mastery level" | progress_dashboard |
| "How many topics mastered" | progress_dashboard |
| "What's my streak" | progress_dashboard |
| "Am I on track" | progress_dashboard |

### Research Intents (10)

| Trigger | Workflow |
|---------|-----------|
| "Research [topic] for me" | learning_session + research |
| "Find sources on [subject]" | research within learning_session |
| "What does the literature say about [topic]" | research |
| "Deep dive into [concept]" | elaborative_interrogation |
| "Why does [mechanism] work" | elaborative_interrogation |
| "Explain the theory behind [topic]" | elaborative_interrogation |
| "Compile information on [subject]" | research |
| "Summarize [topic] from papers" | research |
| "What's the evidence for [claim]" | research |
| "Compare [approach A] vs [approach B]" | research |

---

## 5. FSRS-6 Constants

### Core Parameters

```python
# scripts/fsrs_scheduler.py

# Target retention probability
RETRIEVABILITY_THRESHOLD = 0.9  # 90% retention target

# Default values for new items
STABILITY_DEFAULT = 2.5         # Days until 90% recall
DIFFICULTY_DEFAULT = 5.0       # 1-10 scale, mid-range

# Decay factor for mastery calculation
DECAY = -0.5

# Safety bounds
MAX_STABILITY = 365.0          # 1 year maximum
MAX_INTERVAL = 365             # Maximum review interval (days)
```

### FSRS Formulas

#### Retrievability (Power Law)

```
R(t, S) = (1 + t/(9*S))^(-1)

Where:
- R = probability of recall
- t = days since last review
- S = stability (days for 90% retention)
```

#### Stability Update (Success)

**SQL Implementation** (see `docs/learnloop/mcp-queries/fsrs.sql`):

```sql
 UPDATE fsrs_state
 SET stability = MIN(365.0, stability * (1 + (11.0 - difficulty) * 0.1 * (1 + (:performance - 0.6) * 2) * (1 + SQRT(stability)/10.0) * (0.5 + :retrievability)))
 WHERE topic_id = :topic_id AND :performance >= 0.6;
```

Where:
- f(D) = 11 - difficulty
- f(S) = 1 + sqrt(S)/10  (saturation effect)
- f(R) = 0.5 + retrievability
- p_factor = 1 + (performance - 0.6) * 2  (for performance >= 0.6)
```

#### Stability Update (Failure)

```
S' = S * (0.5 + performance * 0.5)

For performance < 0.6
```

#### Difficulty Update

```
D' = D + (5 - D) * 0.1 * 0.1 + (1 - performance) * 2 * 0.1

Mean reversion toward 5.0, adjusted by performance.
```

#### Interval Calculation

```
interval = 9 * S' * (R_threshold^(-1) - 1)
         = 9 * S' * (0.9^(-1) - 1)
         = 9 * S' * (1.111 - 1)
         = 9 * S' * 0.111
         ≈ S'

So interval ≈ stability when targeting 90% retention.
```

#### Mastery Score

```
mastery = 1 - exp(decay * S / D)
        = 1 - exp(-0.5 * stability / difficulty)

Range: 0.0 to 1.0
```

### State Machine

```
State 0 (New) → State 1 (Learning)    [First review]
State 1 (Learning) → State 2 (Review)  [Performance >= 0.6]
State 1 (Learning) → State 1           [Performance < 0.6] (stay)
State 2 (Review) → State 3 (Relearning) [Performance < 0.6]
State 2 (Review) → State 2              [Performance >= 0.6] (stay)
State 3 (Relearning) → State 2          [Performance >= 0.6]
State 3 (Relearning) → State 3          [Performance < 0.6] (stay)
```

---

## 6. Backup System

### Backup Creation

```bash
# Manual backup
cp ~/.learnloop/goals/{goal_id}/memory.db ~/.learnloop/backups/{goal_id}_$(date +%Y%m%d).db

# Automatic daily backup (cron)
0 0 * * * cp ~/.learnloop/goals/*/memory.db ~/.learnloop/backups/$(date +\%Y\%m\%d)/
```

### Verification

```sql
PRAGMA integrity_check;
SELECT 'topics' AS tbl, COUNT(*) FROM topics;
```

### Restore

```bash
cp ~/.learnloop/backups/{backup_file}.db ~/.learnloop/goals/{goal_id}/memory.db
```

---

## 7. Error Code Quick Reference

### E0XX: Input Errors

| Code | Name | Description | File |
|------|------|-------------|------|
| E001 | DUPLICATE_GOAL | Goal database already exists | sqlite_init.py |
| E002 | INVALID_TOLERANCE | Tolerance parameter out of range | fsrs_scheduler.py |
| E003 | GOAL_LIMIT_EXCEEDED | Maximum 3 concurrent goals | sqlite_init.py |
| E004 | INVALID_GOAL_ID | goal_id fails safe pattern | validation.py |
| E005 | INVALID_GOAL_TYPE | goal_type not in {exam, skill, degree, topic} | validation.py |

### E1XX: State Errors

| Code | Name | Description | File |
|------|------|-------------|------|
| E101 | TOPIC_NOT_FOUND | Topic ID doesn't exist in database | mastery_update.py |
| E102 | MAX_GOALS_REACHED | Cannot create more goals (limit: 3) | sqlite_init.py |
| E103 | VAULT_NOT_INITIALIZED | Obsidian vault path not configured | vault_manager.py |
| E104 | SESSION_IN_PROGRESS | Cannot start new session while active | workflow_router.py |

### E2XX: Calculation Errors

| Code | Name | Description | File |
|------|------|-------------|------|
| E201 | INVALID_STABILITY | Stability value negative | fsrs_scheduler.py |
| E202 | INVALID_DIFFICULTY | Difficulty outside 1-10 range | fsrs_scheduler.py |
| E203 | INVALID_PERFORMANCE | Performance outside [0.0, 1.0] | validation.py |
| E204 | CALCULATION_OVERFLOW | Numerical overflow in FSRS math | fsrs_scheduler.py |

### E3XX: Vault Errors

| Code | Name | Description | File |
|------|------|-------------|------|
| E301 | VAULT_WRITE_FAILED | Cannot write to Obsidian vault | vault_manager.py |
| E302 | INVALID_TOPIC_ID | topic_id fails safe pattern | validation.py |
| E303 | NOTE_NOT_FOUND | Note file doesn't exist | vault_manager.py |
| E304 | ARCHIVE_FAILED | Cannot move topic to archive | vault_manager.py |

### E4XX: Session Errors

| Code | Name | Description | File |
|------|------|-------------|------|
| E401 | SESSION_TIMEOUT | Session exceeded maximum duration | workflow_router.py |
| E402 | ASSESSMENT_INCOMPLETE | User left before completing assessment | workflow_router.py |
| E403 | SESSION_CANCELLED | User cancelled mid-session | workflow_router.py |

### E5XX: Research Errors

| Code | Name | Description | File |
|------|------|-------------|------|
| E501 | SOURCE_UNREACHABLE | Cannot fetch source URL | research_engine.py |
| E502 | INSUFFICIENT_SOURCES | Fewer than 3 sources for claim | research_engine.py |
| E503 | CLAIM_TIE_FAILED | Cannot connect sources to claim | research_engine.py |

### E6XX: System Errors

| Code | Name | Description | File |
|------|------|-------------|------|
| E601 | RESEARCH_CONTRADICTION | Sources contradict each other | research_engine.py |
| E602 | DATABASE_LOCKED | SQLite database is locked | sqlite_init.py |
| E603 | FSRS_RUNTIME_ERROR | Unspecified FSRS calculation failure | fsrs_scheduler.py |
| E699 | UNKNOWN_ERROR | Catch-all for unexpected errors | various |

---

## Error Recovery: User Choice Protocol

When errors occur during agent execution:

### Error Detection Flow

```
ERROR DETECTED
    │
    ├── WebSearch failed?
    │   ├── Try alternate source (different agent type)
    │   │   ├── Success → Continue
    │   │   └── Fail → Ask user
    │   │
    │   └── Ask user with 4 options
```

### User Choice Dialog

**AskUserQuestion format:**

```json
{
  "question": "WebSearch failed for topic '{topic_name}'. How would you like to proceed?",
  "header": "Error Recovery",
  "options": [
    {
      "label": "Retry All Sources",
      "description": "Try all search methods again with different queries"
    },
    {
      "label": "Test Connection",
      "description": "Diagnose network issues before retrying"
    },
    {
      "label": "Proceed Without This Topic",
      "description": "Continue, mark topic as incomplete with confidence 0.2"
    },
    {
      "label": "Cancel Goal",
      "description": "Stop execution and preserve progress"
    }
  ]
}
```

### Proceed Without Data Handling

When user chooses "Proceed Without":

```sql
UPDATE topics
SET confidence = 0.2,
    incomplete_flag = 1,
    incomplete_reason = 'WebSearch failed - user approved',
    status = 'pending'
WHERE topic_id = :topic_id;

INSERT INTO phase_telemetry (goal_id, phase, error_code, error_message)
VALUES (:goal_id, 'REPAIR', 'E506', 'User approved proceed without data');
```

### Error Codes for Recovery

| Code | Scenario | User Options |
|------|----------|--------------|
| E501 | WebSearch timeout | Retry/Test/Proceed/Cancel |
| E502 | Insufficient sources | Retry/Proceed/Cancel |
| E504 | Agent spawn failed | Retry/Cancel |
| E505 | Gate check failed | Retry/Skip/Cancel |
| E506 | Max repair cycles | Accept Warnings/Cancel |

### Telemetry Logging

Log all errors to phase_telemetry:

```sql
INSERT INTO phase_telemetry (goal_id, phase, phase_status, error_code, error_message)
VALUES (:goal_id, :phase, 'FAIL', :error_code, :error_message)
ON CONFLICT DO UPDATE SET
    error_code = :error_code,
    error_message = :error_message;
```

---

## 8. References

| File | Contents |
|------|----------|
| `references/workflows-extended.md` | Detailed workflow specifications |
| `references/error-codes.md` | Full error code definitions |
| `references/fsrs-constants.md` | FSRS-6 algorithm details |
| `references/vault-setup.md` | Obsidian vault configuration |
| `references/achievement-definitions.md` | Gamification specifications |
| `references/research-methodology.md` | Layered research approach |

## 9. Scripts

| Script | Purpose |
|--------|---------|
| `scripts/sqlite_init.py` | Database initialization |
| `scripts/fsrs_scheduler.py` | Spaced repetition scheduling |
| `scripts/mastery_update.py` | Progress tracking, streak management |
| `scripts/vault_manager.py` | Obsidian vault operations |
| `scripts/research_engine.py` | Layered research compilation |
| `scripts/validation.py` | Input validation, security |

---

**Skill Version:** 1.0.0
**FSRS Version:** 6 (Free Spaced Repetition Scheduler)
**Last Updated:** 2026-09-01
