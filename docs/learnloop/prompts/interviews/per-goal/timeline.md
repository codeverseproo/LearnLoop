# Interview: Per-Goal - Timeline

## Trigger
After exam requirements assessment. Third prompt in the per-goal interview sequence.

## Question
How many weeks do you have to prepare for **{goal_name}**?

## Response Options
- [ ] A: Less than 4 weeks — Intensive cramming needed
- [ ] B: 4-8 weeks — Accelerated pace
- [ ] C: 8-12 weeks — Standard preparation
- [ ] D: 12-24 weeks — Extended, thorough preparation
- [ ] E: 24+ weeks or flexible — Self-paced, no deadline

## Adaptive Follow-ups
IF response = A THEN: "This is an aggressive timeline. Can you commit 3+ hours daily?"
IF response = B THEN: "Accelerated pace. How many hours can you study per day?"
IF response = C THEN: "Standard timeline. What's your preferred study intensity?"
IF response = D THEN: "Extended preparation. Any milestone dates or checkpoints?"
IF response = E THEN: "Flexible timeline. What pace feels sustainable for you?"

## Secondary Questions

### Question 2: Study Intensity
What intensity level works best for your schedule and learning style?
- [ ] Light — 30-60 minutes/day, 3-4 days/week
- [ ] Moderate — 1-2 hours/day, 4-5 days/week
- [ ] Intensive — 2-3 hours/day, 5-6 days/week
- [ ] Full-time — 4+ hours/day, 6-7 days/week

### Question 3: Milestones
Do you have any intermediate goals or checkpoints?
Examples: "Complete fundamentals by week 4", "Practice exams by week 8"

## Storage
```json
{
  "timeline_weeks": "{weeks_number}",
  "timeline_category": "{response_letter}",
  "intensity": "{intensity_level}",
  "hours_per_day": "{hours}",
  "days_per_week": "{days}",
  "milestones": [
    {"week": "{week_num}", "goal": "{milestone_description}"}
  ],
  "version": 1,
  "completed_at": "{ISO_date}"
}
```

## Completion Check
Category complete when:
- Timeline weeks selected (A-E)
- Intensity level chosen
- Hours per day estimated
- Timestamp recorded
