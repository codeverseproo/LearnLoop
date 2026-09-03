# MIT Learning Skill

**Intent-driven learning skill for personalized education with FSRS-6 spaced repetition.**

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
"I want to prepare for UPSC Prelims in 3 months"
```
The skill will:
- Analyze your goal type (exam/skill/degree/topic)
- Generate a personalized syllabus
- Set up spaced repetition schedule
- Create an Obsidian vault for notes

### 2. Learn Topics
```
"Continue with Polity"
```
The skill will:
- Provide structured notes with worked examples
- Generate practice problems
- Activate prior knowledge connections

### 3. Review What You've Learned
```
"What's due for review?"
```
The skill will:
- Show topics ordered by retrievability (lowest first)
- Track your performance
- Adjust future review intervals

### 4. Check Progress
```
"How am I doing?"
```
The skill shows:
- Mastery percentage per topic
- Current streak and longest streak
- Topics mastered vs in progress

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
| `learning_session` | Learn a new topic | "Teach me about Indian Polity" |
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

## Features

| Feature | Description | Benefit |
|---------|-------------|---------|
| **Intent-Driven** | No commands to memorize - just say what you want | Natural conversation |
| **FSRS-6 Scheduler** | Free Spaced Repetition Scheduler algorithm | 20-30% fewer reviews |
| **Streak System** | Loss aversion mechanic with streak freeze | 3.6x higher engagement |
| **Achievement System** | Early wins + layered difficulty | Sustained motivation |
| **Obsidian Integration** | Per-goal vault with knowledge graph | Visual connections |
| **Multi-Goal Isolation** | Separate SQLite database per goal | Organized progress |
| **Open-Ended Research** | WebSearch + triangulation for notes | Accurate, cited content |

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

### FSRS-6 Algorithm

**DSR Model:**
- **D (Difficulty)**: 1-10 scale, how hard you find the topic
- **S (Stability)**: Days for recall probability to drop to 90%
- **R (Retrievability)**: Current probability of recall (0.0-1.0)

**Core Formula:**
```
R(t) = (1 + t/(9*S))^(-0.5)
```

Where:
- `t` = days since last review
- `S` = stability in days

**At 90% retention target:**
- Review interval ≈ stability
- Successful review → stability increases
- Failed review → stability decreases

---

## Installation

### Prerequisites
- SQLite3 (standard on macOS/Linux)
- Obsidian (optional, for vault integration)

### Setup

1. **Clone or copy the skill:**
   ```bash
   # If using as Claude Code skill:
   cp -r MIT/ ~/.claude/skills/mit-learning/
   ```

2. **Verify installation:**
   ```bash
   sqlite3 --version
   # SQLite MCP queries are ready to use
   ```

---

## File Structure

```
MIT/
├── SKILL.md                    # Main skill instructions
├── README.md                   # This file
├── docs/
│   └── superpowers/
│       └── mcp-queries/        # SQLite MCP query templates
│           ├── README.md       # Query documentation
│           ├── schema.sql      # Database initialization (8 tables)
│           ├── fsrs.sql        # FSRS-6 algorithm in SQL
│           ├── learning.sql    # Learning session queries
│           ├── review.sql      # Review session queries
│           ├── practice.sql    # Practice session queries
│           ├── research.sql    # Research workflow queries
│           ├── streak.sql      # Streak tracking queries
│           └── backup.sql      # Backup operations
```

---

## Usage Examples

### Example 1: Exam Preparation

```
User: "I want to prepare for UPSC Prelims in 3 months"

Skill analyzes:
- Goal type: exam
- Timeline: urgent (3 months)
- Creates goal: upsc-prelims

Skill generates:
1. Syllabus covering all GS papers + CSAT
2. Prerequisite graph showing topic dependencies
3. FSRS-6 review schedule optimized for 90-day timeline
4. Obsidian vault: ~/Obsidian/MIT-upsc-prelims/
```

### Example 2: Skill Acquisition

```
User: "Teach me Python programming"

Skill analyzes:
- Goal type: skill
- Timeline: moderate
- Baseline: beginner (assumed)

Skill provides:
1. Structured notes with worked examples
2. Code snippets and exercises
3. Practice problems with adaptive difficulty
4. Socratic tutoring for understanding
```

### Example 3: Daily Review

```
User: "What's due for review today?"

Skill queries:
- SQLite database for topics with retrievability < 90%
- Orders by priority (lowest retrievability first)
- Generates review queue in Obsidian

Output:
# Review Queue - 2026-08-31

## Queue
Priority-ordered by retrievability (lowest first).

### 1. T05: Constitutional Amendments 🔴
- Mastery: 35.0%
- Retrievability: 45.2%

### 2. T08: Medieval History 🟡
- Mastery: 62.0%
- Retrievability: 71.5%
```

---

## Configuration

### FSRS Constants

```python
STABILITY_DEFAULT = 2.5    # Days for new items
DIFFICULTY_DEFAULT = 5.0  # 1-10 scale (mid-range)
DECAY = -0.5              # Power function exponent
RETRIEVABILITY_THRESHOLD = 0.9  # Target retention
```

### Goal Limits

```python
MAX_CONCURRENT_GOALS = 3    # Prevents overload
MAX_TOPICS_PER_GOAL = 500   # Ensures focus
```

### Vault Directories

```
MIT-{goal-slug}/
├── 00-Dashboard/      # Progress tracking
├── 10-Active-Topics/  # Current learning
├── 20-Review-Queue/   # Due reviews
├── 30-Completed-Topics/ # Mastered
├── 40-Practice/       # Practice problems
└── 50-Resources/      # External links
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

All errors use codes E001-E599. See `references/error-codes.md` for details.

| Range | Category |
|-------|----------|
| E001-E099 | Goal errors |
| E100-E199 | Topic errors |
| E200-E299 | FSRS errors |
| E300-E399 | Vault errors |
| E400-E499 | Export errors |
| E500-E599 | Session errors |

**Graceful Degradation:**
- FSRS calculation failure → Default 7-day interval
- Vault write failure → SQLite-only fallback
- Research failure → Mark "needs manual research"

---

## Testing

Run the SQL test suite:

```bash
cd docs/superpowers/tests
./run_tests.sh
```

Expected output:
```
✓ All 11 tests passed
```

---

## License

MIT License - See LICENSE file for details.

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-09-03 | Pure SQLite MCP architecture, zero Python dependency |

---

## Contributing

This skill follows:
- PEP 8 style guidelines
- TDD (Test-Driven Development)
- One feature per commit
- All tests must pass before commit

---

## Support

For issues or questions:
1. Check `references/error-codes.md` for error descriptions
2. Review `references/workflows-extended.md` for workflow details
3. Open an issue with error code and steps to reproduce
