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
   ```

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

## 1.6 Interview System

Three-stage interview flow captures user preferences before generation.

### Onboarding Interview

| Trigger | Example Phrases |
|---------|-----------------|
| First skill use | "I want to learn X", "Create a study plan" (when no goal exists) |
| New user detected | No `onboarding_complete` flag in any goal |

**Flow:**
1. Check `onboarding_complete` flag
2. If false -> trigger `onboarding-availability.md`
3. Store in `availability_json`
4. Trigger `onboarding-learning-style.md`
5. Store in `learning_style_json`
6. Set `onboarding_complete = 1`

**Blocking Condition:** Onboarding incomplete -> no goal creation

### Per-Goal Interview

| Trigger | Example Phrases |
|---------|-----------------|
| Goal creation | After parsing goal, before database init |
| New goal detected | "I want to learn X" (new goal_id) |

**Flow:**
1. After database initialization (Step 2 of syllabus_generation)
2. Check `goal_interview_complete` flag
3. If false -> trigger 4 per-goal prompts sequentially
4. Store in `goal_profile_json`
5. Set `goal_interview_complete = 1`
6. Continue to discovery agents

**Blocking Condition:** Goal interview incomplete -> no syllabus generation

### Per-Note Interview

| Trigger | Example Phrases |
|---------|-----------------|
| Note generation | "Generate notes for X", "Create a note" |
| Learning session | Before presenting new content |

**Flow:**
1. Before note generation
2. Trigger 4 per-note prompts sequentially
3. Store in `note_preferences_json`
4. Generate note with preferences applied

**Non-Blocking:** Note preferences empty -> use goal defaults (per-note not mandatory for subsequent notes)

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

#### Step 8: Generate Syllabus

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
