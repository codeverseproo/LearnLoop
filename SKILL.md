---
name: mit-learning
description: Intent-driven learning skill for personalized education with comprehensive research capabilities. Triggers when user wants to learn topics, prepare for exams, practice skills, conduct research, or track learning progress. Compiles layered research (Academic + Official → Broad Web → Curated) into single-source summaries. Adapts to user's goals, timeline, and baseline.
---

# MIT Learning Skill

Intent-driven learning system with FSRS-6 spaced repetition, streak mechanics, and Obsidian integration.

## How This Skill Works

Uses **intent-driven workflow selection**. LLM reasons about your intent and dynamically selects appropriate workflow.

## Intent Analysis

| Dimension | Values | How Determined |
|-----------|--------|----------------|
| Goal Type | exam, skill, degree, topic | Named entities in message |
| Action | create, continue, review, assess, check | Verb analysis |
| Timeline | urgent, moderate, leisurely | Time expressions, deadlines |
| Baseline | beginner, intermediate, advanced | Self-assessment or diagnostic |
| Depth | overview, standard, mastery | Goal context |

## 12 Workflows

### Planning Workflows

1. **syllabus_generation** - Create learning plan from goal
2. **diagnostic_assessment** - Evaluate baseline before starting
3. **study_schedule_optimization** - Optimize daily/weekly schedule

### Learning Workflows

4. **learning_session** - Learn a new topic
5. **prior_knowledge_activation** - Activate related knowledge
6. **metacognitive_reflection** - Reflect on learning process

### Review Workflows

7. **review_session** - Spaced repetition review
8. **elaborative_interrogation** - Deep "why" and "how" questions

### Practice Workflows

9. **practice_session** - Practice problems
10. **interleaved_practice** - Mixed problem sets

### Status Workflows

11. **progress_dashboard** - View mastery and streak

### Dynamic Workflows

12. **current_affairs_digest** - Daily current events (exam prep)

## Output Principles

All outputs follow **guided flexibility**:

1. **Match user's context** - Exam prep vs hobby learning
2. **Adapt to timeline** - Urgent = essentials, leisurely = comprehensive
3. **Respect baseline** - Beginner = more scaffolding
4. **Use appropriate depth** - Overview vs mastery

## Key Features

| Feature | Description |
|---------|-------------|
| FSRS-6 Scheduler | 20-30% fewer reviews than SM-2 |
| Streak System | Loss aversion mechanic (3.6x engagement) |
| Achievement System | Early wins + layered difficulty |
| Obsidian Integration | Per-goal vault with knowledge graph |
| Multi-Goal Isolation | Separate SQLite per goal |
| **Layered Research** | Academic + Official → Broad Web → Curated |
| **Single-Source Delivery** | Comprehensive notes, no external reading needed |
| **Claim Triangulation** | ≥3 sources per claim with confidence scoring |

## Storage

- **Hot**: Session context (in-memory)
- **Warm**: `~/.mit-learning/goals/{goal_id}/memory.db`
- **Cold**: `~/Obsidian/MIT-{goal-slug}/`

## Quick Start

```
"I want to learn Python programming"
→ syllabus_generation workflow

"Research quantum computing for my exam"
→ research + learning_session workflow

"Continue with my current topic"
→ learning_session workflow

"What's due for review?"
→ review_session workflow

"How am I doing?"
→ progress_dashboard workflow
```

## References

See `references/` directory for:
- `workflows-extended.md` - Detailed workflow steps
- `error-codes.md` - E001-E599 definitions
- `fsrs-constants.md` - FSRS-6 formulas
- `vault-setup.md` - Obsidian configuration
- `achievement-definitions.md` - Gamification specs
- `research-methodology.md` - Layered research approach

## Scripts

Bundled Python scripts handle critical operations:
- `sqlite_init.py` - Database initialization
- `fsrs_scheduler.py` - Spaced repetition
- `mastery_update.py` - Progress tracking
- `vault_manager.py` - Obsidian vault operations
- `research_engine.py` - Layered research compilation

## Research Capability

**Layered approach for comprehensive coverage:**

1. **Tier 1: Academic + Official Sources**
   - Research papers (arXiv, PubMed, Google Scholar)
   - Government sources (.gov, .mil)
   - Institutional documentation (.edu, .org)
   - Academic publishers (Nature, Science, IEEE)

2. **Tier 2: Broad Web Sources**
   - News outlets, Wikipedia, blogs
   - General web search results
   - Community resources

3. **Tier 3: Curated Sources**
   - User-specified feeds
   - Domain-specific databases
   - Reference works

**Triangulation rules:**
- Each claim requires ≥3 independent sources
- Higher tier sources contribute more to confidence
- Unverified claims flagged for manual review
- All sources cited with provenance

**Output: Single comprehensive note**
- User reads nothing else
- All findings consolidated
- Confidence scores per claim
- Complete source bibliography

## Error Handling

All errors use codes E001-E599. See `references/error-codes.md` for details.

Graceful degradation ensures:
- FSRS failure → default 7-day interval
- Vault failure → SQLite-only fallback
- Research failure → mark "needs manual research"
