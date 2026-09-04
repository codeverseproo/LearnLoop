# Interview: Per-Goal - Baseline Knowledge

## Trigger
After goal creation, before syllabus generation. First prompt in the per-goal interview sequence.

## Question
How would you describe your current knowledge level for **{goal_name}**?

## Response Options
- [ ] A: No prior knowledge — I'm starting from scratch
- [ ] B: Beginner — I understand basic concepts but haven't applied them
- [ ] C: Intermediate — I've studied this before and can apply basic principles
- [ ] D: Advanced — I have practical experience and want to fill specific gaps
- [ ] E: Expert — I'm preparing for certification/expert-level mastery

## Adaptive Follow-ups
IF response = A THEN: "What drew you to this subject? What do you hope to achieve?"
IF response = B THEN: "Which basic concepts are you familiar with? List 2-3 topics."
IF response = C THEN: "What topics have you studied? Which areas feel weakest?"
IF response = D THEN: "What specific gaps or weak areas do you want to address?"
IF response = E THEN: "What's driving your expert-level preparation? Certification? Career advancement?"

## Secondary Question
Are there any specific topics within **{goal_name}** that you:
- Already feel confident about (can skip or review lightly)?
- Want to prioritize or focus on more deeply?

## Storage
```json
{
  "baseline_knowledge": "{response_letter}",
  "baseline_description": "{selected_option_text}",
  "baseline_topics": ["{topics_listed}"],
  "confidence_topics": ["{skip_topics}"],
  "priority_topics": ["{focus_topics}"],
  "version": 1,
  "completed_at": "{ISO_date}"
}
```

## Completion Check
Category complete when:
- Baseline level selected (A-E)
- At least one topic identified (either confidence or priority)
- Timestamp recorded

---

## Budget Configuration

**Question to user:**

"How many agents can this goal use for deep research?"

**Options:**
1. **Conservative (10 agents)** — Standard research, fast execution
2. **Balanced (20 agents)** — Recommended for comprehensive goals
3. **Aggressive (50 agents)** — Deep research, complex topics
4. **Unlimited** — No constraints, use as many as needed

**Store in goal_meta:**
```sql
UPDATE goal_meta
SET agent_budget = :budget_value,
    budget_enforcement = 'warning'
WHERE goal_id = :goal_id;
```

**Values:**
- Conservative: `agent_budget = 10`
- Balanced: `agent_budget = 20`
- Aggressive: `agent_budget = 50`
- Unlimited: `agent_budget = -1`

## Output Format After Interview

```json
{
  "baseline_knowledge": "beginner|intermediate|advanced",
  "timeline_weeks": 12,
  "intensity": "relaxed|standard|intensive",
  "agent_budget": 20,
  "budget_enforcement": "warning"
}
```
