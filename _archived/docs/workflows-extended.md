# Extended Workflow Specifications

## 1. syllabus_generation

**Trigger:** Goal type identified + action == create

### Detailed Steps

1. **Analyze Intent**
   - Parse goal type: exam|skill|degree|topic
   - Parse timeline from context
   - Parse baseline if stated
   - Ask ONE clarifying question if unclear

2. **Generate Goal ID**
   ```
   goal_id = slugify(f"{subject}-{exam_type}")
   Example: "upsc-prelims", "python-basics"
   ```

3. **Create Goal Directory**
   ```
   path = ~/.mit-learning/goals/{goal_id}/
   mkdir -p path
   ```

4. **Initialize Database**
   ```python
   from scripts.sqlite_init import init_database
   db_path = init_database(goal_id, Path(path), goal_type)
   ```

5. **Generate Syllabus**
   - Use backward design from goal
   - Create prerequisite graph
   - Estimate time per topic
   - Order by dependencies

6. **Set Up Vault**
   ```python
   from scripts.vault_manager import VaultManager
   vault = VaultManager(vault_path, goal_id)
   vault.create_vault_structure()
   vault.update_dashboard(initial_data)
   ```

7. **Output Syllabus**

### Output Template

```markdown
# [Goal Name] Learning Plan

## Intent
- Type: [exam|skill|degree|topic]
- Timeline: [duration]
- Depth: [overview|standard|mastery]

## Topics

### T01: [Topic Name]
- Status: Available
- Mastery: 0%
- Prerequisites: None
- Estimated time: [X hours]

### T02: [Topic Name]
- Status: Blocked
- Mastery: 0%
- Prerequisites: T01
- Estimated time: [Y hours]

## Streak
- Current: 0 days
- Streak Freeze: Available

## Next Steps
1. Start with T01, OR
2. Take diagnostic assessment for placement
```

---

## 2. diagnostic_assessment

**Trigger:** Before syllabus_generation OR user request

### Detailed Steps

1. **Select Topic Cluster**
   - Choose fundamental concepts
   - Cover breadth of domain

2. **Generate Questions (5-10)**
   - Mix difficulty levels
   - Include prerequisite tests
   - Multiple choice + short answer

3. **Present and Record**
   - Show one question at a time
   - Record response time
   - Note confidence level

4. **Calculate Baseline**
   ```
   baseline = weighted_score(prerequisite_tests, fundamentals)
   confidence = bootstrap_confidence_interval(responses)
   ```

5. **Identify Gaps**
   - Compare to goal requirements
   - Find missing prerequisites
   - Highlight weak areas

6. **Recommend Starting Point**
   ```
   start_topic = find_first_gap(prerequisite_graph, baseline)
   ```

### Output Template

```markdown
# Diagnostic Assessment - [Domain]

## Results
| Metric | Value |
|--------|-------|
| Estimated baseline | [beginner|intermediate|advanced] |
| Confidence | [X%] |
| Correct | [N]/[M] |

## Gap Analysis
**Missing prerequisites:**
- [topic list]

**Weak areas:**
- [topic list]

**Strong areas:**
- [topic list]

## Recommendation
Start with T[XX] to address gaps before proceeding.
```

---

## 3. learning_session

**Trigger:** Active goal + action == continue

### Detailed Steps

1. **Load Goal Context**
   ```python
   conn = get_connection(goal_id)
   next_topic = get_available_topic(conn)
   ```

2. **Prior Knowledge Activation**
   - Show prerequisite concepts
   - Ask brief check-in questions
   - Note any confusion

3. **Generate Note**
   - Adapt to baseline level
   - Include worked examples
   - Add embedded practice

4. **Check Research Need**
   ```python
   if topic_requires_research(topic):
       sources = research_agent.query(topic)
       content = synthesize_with_citations(sources)
   ```

5. **Write to Vault**
   ```python
   vault.write_note(
       topic_id=topic_id,
       content=note_content,
       mastery=0.0,
       related=find_related_topics(topic_id)
   )
   ```

6. **Update Session State**
   - Record session start
   - Update streak counter

7. **Present to User**

### Note Template

```markdown
---
id: T01-topic-slug
created: '2026-08-31'
mastery: 0.0
next_review: '2026-09-01'
related:
  - '[[T00-prerequisite]]'
---

# [Topic Name]

## Overview
[Brief introduction]

## Key Concepts
[Adapted to baseline]

## Examples
[Worked examples]

## Connections
- Builds on [[T00-prerequisite]]
- Relates to [[T05-related]]

## Practice
[Embedded retrieval]

## References
1. [Source with URL]
```

---

## 4. review_session

**Trigger:** Topics due OR action == review

### Detailed Steps

1. Load goal and query FSRS state
2. Calculate priority queue (retrievability-based)
3. For each topic:
   - Show key concepts
   - Prompt retrieval
   - Record performance
   - Update FSRS state
4. Update mastery scores
5. Update streak if daily complete

### Priority Calculation
```python
priority = retrievability - threshold
# Negative = overdue (high priority)
# Positive = not due (low priority)
```

---

## 5. progress_dashboard

**Trigger:** action == check

### Detailed Steps

1. Query mastery stats from SQLite
2. Calculate completion rate
3. Identify bottlenecks
4. Generate recommendations
5. Calculate predictions
6. Update vault dashboard

### Dashboard Template

```markdown
# Progress Dashboard

## Overall Mastery
| Metric | Value |
|--------|-------|
| Total topics | [N] |
| Mastered (>=90%) | [M] |
| In progress | [K] |
| Not started | [L] |

## Streak
- Current: [X] days
- Best: [Y] days
- Freeze available: [yes/no]

## Predictions
- Estimated completion: [date]
- Daily reviews needed: [N]

## Recommendations
1. [Priority recommendation]
2. [Secondary recommendation]
```

---

## 6. prior_knowledge_activation

**Trigger:** Before learning new topic

### Detailed Steps

1. Identify prerequisite topics
2. Show brief summary of each
3. Ask 2-3 recall questions
4. Note confusion points
5. Link to new topic
6. Proceed to note generation

### Output Format

```markdown
## Before We Begin: Quick Review

**Connected to:** [[T01-prerequisite]]

**Recall:**
1. What is [key concept]?
2. How does [concept A] relate to [concept B]?

**Your responses help tailor the upcoming material.**
```

---

## 7. elaborative_interrogation

**Trigger:** After note generation OR user request

### Detailed Steps

1. Extract key claims from note
2. Generate "Why?" and "How?" questions
3. Present one question at a time
4. Wait for user response
5. Provide elaboration with evidence
6. Update note with elaboration

### Output Format

```markdown
## Elaborative Questions

**Why does [phenomenon] occur?**
[Your answer]

**Elaboration:**
[Detailed explanation with evidence]

---

**How does [process] work step-by-step?**
[Your answer]

**Elaboration:**
[Step-by-step breakdown]
```

---

## 8. practice_session

**Trigger:** action == practice OR topic marked for practice

### Detailed Steps

1. Identify practice-worthy topics
2. Generate practice problems
3. Present one problem at a time
4. Record response correctness
5. Update FSRS state
6. Update mastery score

### Problem Generation

```python
problems = generate_problems(
    topic_id=topic_id,
    difficulty=current_mastery,
    count=5
)
```

---

## 9. interleaved_practice

**Trigger:** action == interleave OR auto-scheduled

### Detailed Steps

1. Select 2-4 related topics
2. Determine interleaving order (randomized)
3. Present mixed problem set
4. Track per-topic performance
5. Update each topic's FSRS state
6. Award interleaving achievement if applicable

### Interleaving Rules

- Topics must share some connection
- Order randomized, not blocked
- Minimum 2 topics, maximum 4
- Track interleaved_sessions counter

---

## 10. metacognitive_reflection

**Trigger:** After session OR user request

### Detailed Steps

1. Summarize session topics
2. Prompt confidence ratings
3. Ask "What was most challenging?"
4. Ask "What would you do differently?"
5. Record reflection in session log
6. Update metacognitive metrics

### Reflection Template

```markdown
## Session Reflection

**Topics covered:** T01, T02, T03

**Confidence ratings:**
- T01: [1-5]
- T02: [1-5]
- T03: [1-5]

**Most challenging:**
[User response]

**What to improve:**
[User response]

**Next session focus:**
[AI recommendation]
```

---

## 11. current_affairs_digest

**Trigger:** Scheduled OR action == digest

### Detailed Steps

1. Query current affairs sources
2. Filter by relevance to goal
3. Summarize key developments
4. Link to relevant topics
5. Generate review questions
6. Store in vault

### Digest Template

```markdown
# Current Affairs Digest - [Date]

## Headlines
1. [Headline 1] - Links to: [[T05]], [[T12]]
2. [Headline 2] - Links to: [[T08]]

## Deep Dive
[Summary of most relevant development]

## Practice Questions
1. How does [development] affect [topic]?
2. What are the implications of [change]?
```

---

## 12. study_schedule_optimization

**Trigger:** Weekly OR action == optimize

### Detailed Steps

1. Analyze past week performance
2. Identify optimal study times
3. Balance new learning vs review
4. Recommend session lengths
5. Suggest topic ordering
6. Present optimized schedule

### Optimization Output

```markdown
## Weekly Schedule Optimization

### Recommended Daily Schedule
| Time | Activity | Duration |
|------|----------|----------|
| Morning | New learning | 45 min |
| Afternoon | Review session | 20 min |
| Evening | Practice | 15 min |

### This Week's Focus
- Priority topics: [T05, T08, T12]
- Reviews due: [N] sessions
- Practice recommended: [M] problems

### Adjustments from Last Week
- [Observation 1]
- [Observation 2]
```
