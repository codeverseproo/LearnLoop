---
name: mit-learning
description: Intent-driven learning skill for personalized education with comprehensive research capabilities. Triggers when user wants to learn topics, prepare for exams, practice skills, conduct research, or track learning progress. Compiles layered research (Academic + Official → Broad Web → Curated) into single-source summaries. Adapts to user's goals, timeline, and baseline. Use this skill whenever the user mentions learning, studying, reviewing, exam prep, skill acquisition, spaced repetition, flashcards, mastery tracking, or research compilation.
---

# MIT Learning Skill

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
| **WARM** | SQLite (`~/.mit-learning/goals/{goal_id}/memory.db`) | 1-5ms | Permanent |
| **COLD** | Obsidian vault (`~/Obsidian/MIT-{goal-slug}/`) | 10-50ms | Permanent |

---

## 2. Twelve Workflows

### Planning Workflows

#### 1. syllabus_generation

Create structured learning plan from goal.

| Aspect | Detail |
|--------|--------|
| **Triggers** | "I want to learn X", "Create a study plan for Y", "Syllabus for Z exam" |
| **Prerequisites** | Goal identified, timeline known (optional) |
| **Steps** | 1. Parse goal type (exam/skill/degree/topic) <br> 2. Identify topics from curriculum/body of knowledge <br> 3. Build prerequisite graph <br> 4. Estimate time per topic <br> 5. Create sequential learning path <br> 6. Initialize SQLite database <br> 7. Write syllabus to vault |
| **Outputs** | `memory.db` with topics table, `00-Dashboard/Syllabus.md` in vault |

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

## 3. 50+ Natural Language Triggers

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

## 4. FSRS-6 Constants

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

```
S' = S * (1 + f(D) * 0.1 * p_factor * f(S) * f(R))

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

## 5. Error Code Quick Reference

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

## References

| File | Contents |
|------|----------|
| `references/workflows-extended.md` | Detailed workflow specifications |
| `references/error-codes.md` | Full error code definitions |
| `references/fsrs-constants.md` | FSRS-6 algorithm details |
| `references/vault-setup.md` | Obsidian vault configuration |
| `references/achievement-definitions.md` | Gamification specifications |
| `references/research-methodology.md` | Layered research approach |

## Scripts

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
