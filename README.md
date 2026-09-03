# MIT Learning Skill

**Intent-driven learning skill with FSRS-6 spaced repetition, gamification, and zero Python dependency.**

---

## Table of Contents

1. [What This Skill Does](#what-this-skill-does)
2. [Quick Start](#quick-start)
3. [Installation](#installation)
4. [Features](#features)
5. [12 Workflows](#12-workflows)
6. [Architecture](#architecture)
7. [FSRS-6 Algorithm](#fsrs-6-algorithm)
8. [Demo Commands](#demo-commands)
9. [File Structure](#file-structure)
10. [Testing](#testing)
11. [Research Foundation](#research-foundation)
12. [Error Handling](#error-handling)
13. [Contributing](#contributing)

---

## What This Skill Does

MIT Learning Skill helps you:
- **Create personalized learning plans** for any goal (exams, skills, degrees, topics)
- **Study effectively** with FSRS-6 spaced repetition (20-30% fewer reviews than traditional SRS)
- **Track progress** across multiple learning goals with visual dashboards
- **Build lasting knowledge** with evidence-based learning techniques
- **Stay motivated** with streak mechanics and achievement system

---

## Quick Start

### 1. Create a Learning Goal
```
"I want to learn TypeScript fundamentals"
```

The skill will:
- Analyze your goal type (exam/skill/degree/topic)
- Generate a personalized syllabus with topics
- Initialize SQLite database with FSRS-6 tracking
- Set up spaced repetition schedule

### 2. Learn Topics
```
"Teach me about Type System Basics"
```

The skill will:
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
   cp -r MIT/ ~/.claude/skills/mit-learning/
   ```

2. **First goal creation auto-initializes database:**
   Say: "I want to learn TypeScript fundamentals"
   The skill automatically creates `~/.mit-learning/goals/typescript-fundamentals/memory.db`

3. **Verify installation:**
   ```bash
   sqlite3 --version
   ls docs/superpowers/mcp-queries/
   # Should show: schema.sql, fsrs.sql, learning.sql, etc.
   ```

---

## Features

| Feature | Description | Benefit |
|---------|-------------|---------|
| **Intent-Driven** | No commands to memorize - just say what you want | Natural conversation |
| **FSRS-6 Scheduler** | Free Spaced Repetition Scheduler algorithm | 20-30% fewer reviews |
| **Pure SQLite MCP** | Zero Python dependency | Simpler architecture |
| **Streak System** | Loss aversion mechanic with streak freeze | 3.6x higher engagement |
| **Achievement System** | Early wins + layered difficulty | Sustained motivation |
| **Obsidian Integration** | Per-goal vault with knowledge graph | Visual connections |
| **Multi-Goal Isolation** | Separate SQLite database per goal | Organized progress |
| **Claim Triangulation** | ≥3 sources per research claim | Verified information |

---

## 12 Workflows

### Planning Workflows

| Workflow | Description | Trigger Example |
|----------|-------------|-----------------|
| `syllabus_generation` | Create learning plan from goal | "I want to learn Python" |
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
│      ~/.mit-learning/goals/{goal_id}/memory.db      │
│      Persistent state, FSRS tracking, sessions      │
└───────────────────────┬─────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│                COLD (Obsidian Vault)                │
│          ~/Obsidian/MIT-{goal-slug}/                │
│      Notes, knowledge graph, long-term storage      │
└─────────────────────────────────────────────────────┘
```

### Database Schema (8 Tables)

```sql
goal_meta        -- Goal configuration
topics           -- Topics with mastery tracking
fsrs_state       -- FSRS-6 state per topic
sessions         -- Learning/review session history
prerequisites    -- Topic dependency graph
note_registry    -- Obsidian vault links
streak_state     -- Daily streak tracking
achievements     -- Unlocked achievements
```

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

**SQL Implementation:**
```sql
UPDATE topics
SET mastery = 1 - EXP(-0.5 * stability / difficulty)
WHERE id = :topic_id;
```

### State Machine

```
State 0 (New) → State 1 (Learning)    [First review]
State 1 (Learning) → State 2 (Review)  [Performance >= 0.6]
State 2 (Review) → State 3 (Relearning) [Performance < 0.6]
State 3 (Relearning) → State 2         [Performance >= 0.6]
```

---

## Demo Commands

### Creating Goals

```bash
# Exam preparation
"I want to prepare for AWS Solutions Architect exam"

# Skill acquisition
"Teach me TypeScript fundamentals"

# Topic study
"I want to learn about Machine Learning"

# Degree preparation
"Help me prepare for my Computer Science degree"
```

### Learning Sessions

```bash
# Start learning
"Teach me about IAM and Access Management"
"Learn TypeScript Type System"
"Explain Supervised Learning to me"

# Continue learning
"Continue with my AWS certification"
"What's next in my TypeScript learning?"
"Continue learning Machine Learning"

# Prerequisite activation
"What should I know before learning Neural Networks?"
"Connect this to what I already know"
```

### Review Sessions

```bash
# Review queue
"What's due for review today?"
"Show me my flashcards"
"Time for spaced repetition"

# Review specific topic
"Review IAM with me"
"Quiz me on Type System"
"Test my knowledge of Supervised Learning"

# Elaborative interrogation
"Why does FSRS-6 work better than SM-2?"
"Explain the mechanism of gradient descent"
"How does the retrievability formula work?"
```

### Practice Sessions

```bash
# Single topic practice
"Give me practice problems on IAM policies"
"Test myself on TypeScript generics"
"Practice Supervised Learning concepts"

# Interleaved practice
"Mixed practice on AWS topics"
"Random problems from my syllabus"
"Quiz me on multiple topics"
```

### Progress Tracking

```bash
# Dashboard
"How am I doing?"
"Show my progress"
"Dashboard"

# Specific metrics
"What's my streak?"
"How many topics have I mastered?"
"What's my mastery level?"
"Am I on track?"
```

### Schedule Management

```bash
# Schedule optimization
"Optimize my study schedule"
"When should I study?"
"Plan my week"

# Current affairs (for exam goals)
"What's happening today?"
"Current affairs for my exam"
"News relevant to my syllabus"
```

---

## File Structure

```
MIT/
├── SKILL.md                    # Main skill instructions
├── README.md                   # This file
└── docs/
    └── superpowers/
        └── mcp-queries/        # SQLite MCP query templates
            ├── README.md       # Query documentation
            ├── schema.sql      # Database initialization (8 tables)
            ├── fsrs.sql        # FSRS-6 algorithm in SQL
            ├── learning.sql    # Learning session queries
            ├── review.sql      # Review session queries
            ├── practice.sql    # Practice session queries
            ├── research.sql    # Research workflow queries
            ├── streak.sql      # Streak tracking queries
            └── backup.sql      # Backup operations
        └── tests/              # SQL test suite
            ├── unit/test_fsrs.sql
            ├── integration/test_workflows.sql
            ├── edge-cases/test_edge_cases.sql
            └── run_tests.sh
```

---

## Testing

### Run SQL Tests

```bash
cd docs/superpowers/tests
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

=== Edge Case Tests ===
✓ Test: Empty queue handling
✓ Test: Maximum mastery (1.0)
✓ Test: Maximum stability (365)

=== ALL 11 TESTS PASSED ===
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

---

## Contributing

This skill follows:
- One feature per commit
- All tests must pass before commit
- SQL queries use parameterized syntax (`:param`)
- CHECK constraints for data safety

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-09-03 | Pure SQLite MCP architecture, zero Python dependency |

---

## License

MIT License - See LICENSE file for details.
