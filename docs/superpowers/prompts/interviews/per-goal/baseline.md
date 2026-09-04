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
