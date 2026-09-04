# LearnLoop

**Intent-driven learning skill with FSRS-6 spaced repetition, research-based syllabus generation, and zero Python dependency.**

---

## Table of Contents

1. [What This Skill Does](#what-this-skill-does)
2. [Quick Start](#quick-start)
3. [Installation](#installation)
4. [Features](#features)
5. [Three-Stage Interview System](#three-stage-interview-system)
6. [12 Workflows](#12-workflows)
7. [Architecture](#architecture)
8. [FSRS-6 Algorithm](#fsrs-6-algorithm)
9. [File Structure](#file-structure)
10. [Testing](#testing)
11. [Research Foundation](#research-foundation)
12. [Error Handling](#error-handling)

---

## What This Skill Does

LearnLoop helps you:
- **Create personalized learning plans** for any goal (exams, skills, degrees, topics) using layered research from academic, official, and expert sources
- **Study effectively** with FSRS-6 spaced repetition (20-30% fewer reviews than traditional SRS)
- **Track progress** across multiple learning goals with visual dashboards
- **Build lasting knowledge** with evidence-based learning techniques and claim triangulation
- **Stay motivated** with streak mechanics and achievement system
- **Capture preferences** through adaptive 3-stage interviews before content generation

---

## Quick Start

### 1. Create a Learning Goal
```
"I want to learn TypeScript fundamentals"
```

The skill will:
- Conduct onboarding interview (availability, learning style)
- Conduct per-goal interview (baseline, exam requirements, timeline, preferences)
- Analyze your goal type (exam/skill/degree/topic)
- Research and generate a personalized syllabus with hidden topic detection
- Initialize SQLite database with FSRS-6 tracking
- Set up spaced repetition schedule

### 2. Learn Topics
```
"Teach me about Type System Basics"
```

The skill will:
- Conduct per-note interview (depth, focus, content, time budget)
- Provide structured notes with examples
- Generate practice problems
- Track your performance
- Schedule next review

### 3. Review What You've Learned
```
"What's due for review?"
```

The skill will:
- Show topics ordered by priority (lowest retrievability first)
- Collect your performance rating
- Update FSRS stability estimates
- Schedule next review

### 4. Check Progress
```
"How am I doing?"
```

The skill shows:
- Mastery percentage per topic
- Current streak and longest streak
- Topics mastered vs in progress

---

## Installation

### Prerequisites
- SQLite3 (standard on macOS/Linux)
- Obsidian (optional, for vault integration)

### Setup

1. **Copy the skill:**
   ```bash
   cp -r LearnLoop/ ~/.claude/skills/learnloop/
   ```

2. **First goal creation auto-initializes database:**
   Say: "I want to learn TypeScript fundamentals"
   The skill automatically creates `~/.learnloop/goals/typescript-fundamentals/memory.db`

3. **Verify installation:**
   ```bash
   sqlite3 --version
   ls docs/learnloop/mcp-queries/
   # Should show: schema.sql, fsrs.sql, learning.sql, etc.
   ```

---

## Features

| Feature | Description | Benefit |
|---------|-------------|---------|
| **Research-Based Syllabus** | 4 parallel agents (official/academic/practical/expert) | Comprehensive coverage from credible sources |
| **Hidden Topic Detection** | 3 methods: complexity, error patterns, expert practice | No blind spots in your learning plan |
| **Knowledge Graph** | Prerequisite + related + cross-domain links | Connected learning |
| **Critic Quality Loop** | 7 checks, max 5 repair cycles, mandatory blocking | Verified syllabus quality |
| **3-Stage Interview System** | Onboarding → Per-Goal → Per-Note | Personalized content generation |
| **FSRS-6 Scheduler** | Free Spaced Repetition Scheduler algorithm | 20-30% fewer reviews |
| **Pure SQLite MCP** | Zero Python dependency | Simpler architecture |
| **Streak System** | Loss aversion mechanic with streak freeze | 3.6x higher engagement |
| **Multi-Goal Isolation** | Separate SQLite database per goal | Organized progress |
| **Budget Enforcement** | User-defined agent limits (10/20/50/unlimited) | Cost control with advisory or hard_limit modes |
| **Telemetry Layer** | Phase duration tracking, gate results | Observability and debugging |
| **Mandatory Guards** | 4 blocking checkpoints before key transitions | Prevents skipping critical stages |

---

## Three-Stage Interview System

The skill captures user preferences through adaptive sequential interviews before content generation.

### Stage 1: Onboarding Interview

**Trigger:** First skill use or new user detected

**Captures:**
- Availability (hours/day, days/week, preferred times)
- Learning style (visual/auditory/kinesthetic, pacing, note format)

**Blocking:** Must complete before goal creation

### Stage 2: Per-Goal Interview

**Trigger:** Goal creation

**Captures:**
- Baseline knowledge (goal-specific level, topics, priorities)
- Exam requirements (date, passing score, prerequisites)
- Timeline & intensity (weeks, hours/day, milestones)
- Note customization (default depth, format, inclusions)

**Blocking:** Must complete before syllabus generation

### Stage 3: Per-Note Interview

**Trigger:** Before each note generation

**Captures:**
- Depth level (overview/detailed/expert)
- Focus mode (exam-oriented/practical/theoretical)
- Additional content (examples/exercises/flashcards)
- Time budget (quick/standard/deep)

**Non-Blocking:** Uses goal defaults if skipped

### Interview Flow

```
First Use → Onboarding Interview → Goal Created → Per-Goal Interview
    ↓
Syllabus Generated → Note Request → Per-Note Interview → Content Generated
```

### Storage

Interview data stored in SQLite `goal_meta` table:
- `availability_json` - Onboarding availability
- `learning_style_json` - Onboarding learning style
- `goal_profile_json` - Per-goal profile (baseline, exam, timeline, customization)
- `note_preferences_json` - Per-note preferences (transient, overwritten each generation)
- `last_note_preferences_json` - Previous preferences for reuse

---

## 12 Workflows

### Planning Workflows

| Workflow | Description | Trigger Example |
|----------|-------------|-----------------|
| `syllabus_generation` | Research-based plan with hidden topic detection | "I want to learn Python" |
| `diagnostic_assessment` | Evaluate baseline before starting | "Test my current knowledge" |
| `study_schedule_optimization` | Optimize daily/weekly schedule | "Plan my study schedule" |

### Learning Workflows

| Workflow | Description | Trigger Example |
|----------|-------------|-----------------|
| `learning_session` | Learn a new topic | "Teach me about Polity" |
| `prior_knowledge_activation` | Connect to what you already know | "What should I know before this?" |
| `metacognitive_reflection` | Reflect on learning process | "Help me review my understanding" |

### Review Workflows

| Workflow | Description | Trigger Example |
|----------|-------------|-----------------|
| `review_session` | Spaced repetition review | "What's due for review?" |
| `elaborative_interrogation` | Deep "why" and "how" questions | "Why does this work this way?" |

### Practice Workflows

| Workflow | Description | Trigger Example |
|----------|-------------|-----------------|
| `practice_session` | Practice problems | "Give me practice questions" |
| `interleaved_practice` | Mixed problem sets | "Quiz me on multiple topics" |

### Status & Dynamic Workflows

| Workflow | Description | Trigger Example |
|----------|-------------|-----------------|
| `progress_dashboard` | View mastery and streak | "How am I doing?" |
| `current_affairs_digest` | Daily current events | "What's happening today?" |

---

## Architecture

### Orchestrator State Machine (v2.0)

LearnLoop enforces a strict state machine with mandatory blocking guards:

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

**Key Guards:**

| Guard | SQL Query | Blocking Condition |
|-------|-----------|-------------------|
| G1 (Pre-WAVE1) | `gates/pre-wave1-interview.sql` | `onboarding_complete = 0` OR `goal_interview_complete = 0` |
| G2 (Post-WAVE1) | `gates/wave1-discovery.sql` | Discovery agents incomplete |
| G3 (Post-WAVE2) | `gates/wave2-deep-dive.sql` | Deep-dives incomplete |
| G4 (Pre-WAVE5) | `gates/pre-wave5-output.sql` | No critic verdict OR `REJECT` with `repair_cycles < 5` |

**Telemetry Tracking:**

Every wave transition logs to `phase_telemetry` table:

```sql
-- On wave start
INSERT INTO phase_telemetry (goal_id, phase, wave, started_at)
VALUES (:goal_id, 'WAVE1', 1, CURRENT_TIMESTAMP);

-- On wave completion
UPDATE phase_telemetry
SET completed_at = CURRENT_TIMESTAMP,
    duration_seconds = (julianday(CURRENT_TIMESTAMP) - julianday(started_at)) * 86400,
    gate_result = 'PASS',
    success = 1
WHERE goal_id = :goal_id AND phase = 'WAVE1' AND completed_at IS NULL;
```

**Budget Enforcement:**

| Budget Mode | Behavior |
|-------------|----------|
| `advisory` (default) | Warnings at 50%/75%/100% thresholds |
| `hard_limit` | Blocks agent spawns when budget exhausted |

Budget values: `10` (Conservative), `20` (Balanced), `50` (Aggressive), `-1` (Unlimited)

### Three-Tier Memory System

```
┌─────────────────────────────────────────────────────┐
│                    HOT (Session)                    │
│              In-memory context                      │
│         Fast access, temporary storage              │
└───────────────────────┬─────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│                   WARM (SQLite)                     │
│      ~/.learnloop/goals/{goal_id}/memory.db      │
│      ~/.learnloop/research/{goal_id}/            │ ← Research artifacts from discovery agents
│      Persistent state, FSRS tracking, sessions      │
└───────────────────────┬─────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│                COLD (Obsidian Vault)                │
│          ~/Obsidian/LL-{goal-slug}/                │
│      Notes, knowledge graph, long-term storage      │
└─────────────────────────────────────────────────────┘
```

### Database Schema (12 Tables)

```sql
goal_meta            -- Goal configuration + interview data
topics               -- Topics with mastery, confidence, hidden flags
fsrs_state           -- FSRS-6 state per topic
sessions             -- Learning/review session history
prerequisites        -- Topic dependency graph
topic_links          -- Related/cross-domain connections
topic_sources        -- Source citations per topic
note_registry        -- Obsidian vault links
streak_state         -- Daily streak tracking
achievements         -- Unlocked achievements
```

### Interview Columns (goal_meta)

| Column | Type | Purpose |
|--------|------|---------|
| `availability_json` | TEXT | Onboarding: hours/day, days/week, preferred times |
| `learning_style_json` | TEXT | Onboarding: visual/auditory/kinesthetic, pacing |
| `goal_profile_json` | TEXT | Per-Goal: baseline, exam, timeline, customization |
| `note_preferences_json` | TEXT | Per-Note: transient preferences |
| `last_note_preferences_json` | TEXT | Previous note preferences for reuse |
| `onboarding_complete` | INTEGER | Flag: onboarding done |
| `goal_interview_complete` | INTEGER | Flag: goal interview done |

---

## FSRS-6 Algorithm

### Core Parameters

```python
RETRIEVABILITY_THRESHOLD = 0.9  # 90% retention target
STABILITY_DEFAULT = 2.5         # Days until 90% recall
DIFFICULTY_DEFAULT = 5.0        # 1-10 scale, mid-range
MAX_STABILITY = 365.0            # 1 year maximum
```

### Retrievability Formula

```
R(t, S) = (1 + t/(9*S))^(-1)

Where:
- R = probability of recall (0.0-1.0)
- t = days since last review
- S = stability (days for 90% retention)
```

**SQL Implementation:**
```sql
SELECT POWER(1 + (julianday('now') - julianday(last_review)) / (9.0 * stability), -1.0) AS retrievability
FROM fsrs_state;
```

### Stability Update

**On Success (performance ≥ 0.6):**
```sql
UPDATE fsrs_state
SET stability = MIN(365.0, stability * (1 + (11.0 - difficulty) * 0.1 * performance_factor * stability_factor * retrievability_factor))
WHERE topic_id = :topic_id AND :performance >= 0.6;
```

**On Failure (performance < 0.6):**
```sql
UPDATE fsrs_state
SET stability = MAX(1.0, stability * (0.5 + :performance * 0.5))
WHERE topic_id = :topic_id AND :performance < 0.6;
```

### Mastery Score

```
mastery = 1 - exp(-0.5 * stability / difficulty)

Range: 0.0 to 1.0
```

---

## File Structure

```
LearnLoop/
├── SKILL.md                    # Main skill instructions
├── README.md                   # This file
└── docs/
    └── superpowers/
        ├── architecture/       # Architecture documentation
        ├── mcp-queries/         # SQLite MCP query templates
        │   ├── schema.sql      # Database initialization
        │   ├── fsrs.sql        # FSRS-6 algorithm
        │   ├── learning.sql    # Learning session queries
        │   ├── review.sql      # Review session queries
        │   ├── interview-checks.sql  # Interview enforcement
        │   └── migrations/     # Schema migrations
        ├── prompts/            # Agent and interview prompts
        │   ├── interviews/     # 3-stage interview prompts
        │   │   ├── onboarding/
        │   │   ├── per-goal/
        │   │   └── per-note/
        │   ├── discovery-agent-*.md
        │   └── critic-agent.md
        ├── specs/              # Design specifications
        └── tests/              # SQL test suite
            ├── unit/test_fsrs.sql
            ├── integration/test_workflows.sql
            ├── integration/test_interviews.sql
            └── edge-cases/test_edge_cases.sql
```

---

## Testing

### Run SQL Tests

```bash
cd docs/learnloop/tests
./run_tests.sh
```

### Expected Output

```
=== FSRS Unit Tests ===
✓ Test 1: Retrievability formula
✓ Test 2: Mastery formula
✓ Test 3: Stability bounds
✓ Test 4: Difficulty bounds

=== Workflow Integration Tests ===
✓ Test: Topic+FSRS creation
✓ Test: Session tracking
✓ Test: Streak tracking
✓ Test: Achievements

=== Interview Integration Tests ===
✓ Test: Schema columns
✓ Test: Default values
✓ Test: JSON extraction
✓ Test: Enforcement logic
✓ Test: Rollback safety

=== ALL TESTS PASSED ===
```

---

## Research Foundation

This skill is built on evidence-based learning research:

| Principle | Effect Size | Source |
|-----------|-------------|--------|
| Spaced Repetition | d=0.42 | Bjork's Desirable Difficulties |
| Interleaved Practice | d=0.42 | Rohrer & Taylor (2007) |
| Retrieval Practice | d=0.50 | Karpicke & Roediger (2008) |
| Worked Examples | d=0.57 | Sweller (2006) |
| Mastery Learning | d=0.59 | Bloom (1968) |
| Intelligent Tutoring | d=0.66 | VanLehn (2011) |
| Gamification (learning-aligned) | g=0.78-0.82 | Sailer & Homner (2020) |

### Key Sources

- **FSRS-6**: Expertium (2024) - Based on 700M Anki reviews
- **Streak Psychology**: Duolingo retention studies (2023) - Loss aversion 3.6x engagement
- **Desirable Difficulties**: Bjork Learning & Forgetting Lab
- **Achievement Design**: Trophy.so study - 43.1% day-one unlock, harder = better retention

---

## Error Handling

All errors use codes E001-E699. See SKILL.md for details.

| Range | Category |
|-------|----------|
| E001-E099 | Goal errors |
| E100-E199 | Topic errors |
| E200-E299 | FSRS errors |
| E300-E399 | Vault errors |
| E400-E499 | Session errors |
| E500-E599 | Research errors |
| E600-E699 | System errors |

**Graceful Degradation:**
- FSRS calculation failure → Default 7-day interval
- Vault write failure → SQLite-only fallback
- Research failure → Mark "needs manual research"
- Interview incomplete → Block generation, prompt user

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0.1 | 2026-09-04 | Critical P0 fixes: telemetry race condition, FSRS formula correction, quality gates, timeout handling, WebSearch enforcement, error registry |
| 2.0.0 | 2026-09-04 | Orchestrator state machine with mandatory blocking guards, telemetry tracking, budget enforcement, critic repair loop (max 5 cycles) |
| 1.2.0 | 2026-09-04 | 3-stage interview system: onboarding, per-goal, per-note with JSON storage |
| 1.1.0 | 2026-09-03 | Research-based syllabus: 4 parallel agents, hidden topics, knowledge graph, critic loop |
| 1.0.0 | 2026-09-03 | Pure SQLite MCP architecture, zero Python dependency |

---

## License

MIT License - See LICENSE file for details.
