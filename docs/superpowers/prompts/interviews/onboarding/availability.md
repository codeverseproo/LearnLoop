# Interview: Onboarding - Availability

## Trigger
Activates when `onboarding_complete = 0` in goal_meta table (first skill use with no prior onboarding).

## Question
How much time can you dedicate to learning each day?

## Response Options
- [ ] Option A: Less than 1 hour (light schedule)
- [ ] Option B: 1-2 hours (moderate schedule)
- [ ] Option C: 2-4 hours (dedicated schedule)
- [ ] Option D: 4+ hours (intensive schedule)
- [ ] Option E: Custom: ________ hours

## Adaptive Follow-ups
IF response = A THEN: Ask about available days per week
IF response = B THEN: Ask about preferred time windows (morning/afternoon/evening)
IF response = C THEN: Ask about preferred days and times
IF response = D THEN: Ask if this is sustainable long-term, then preferred schedule
IF response = E THEN: Validate input (1-12 hours), then ask about preferred schedule

### Follow-up Question 2
Which days do you typically have available for learning?

## Response Options (Question 2)
- [ ] Option A: Weekdays only (Mon-Fri)
- [ ] Option B: Weekends only (Sat-Sun)
- [ ] Option C: All days (7 days/week)
- [ ] Option D: Custom: Select specific days

### Follow-up Question 3
When do you prefer to learn?

## Response Options (Question 3)
- [ ] Option A: Morning (6am-12pm)
- [ ] Option B: Afternoon (12pm-6pm)
- [ ] Option C: Evening (6pm-10pm)
- [ ] Option D: Late night (10pm-2am)
- [ ] Option E: Flexible (any time)

## Storage
```json
{
  "availability_json": {
    "hours_per_day": 2,
    "days_per_week": ["mon", "tue", "wed", "thu", "fri"],
    "preferred_times": ["morning", "evening"],
    "version": 1,
    "completed_at": "2026-09-04T10:00:00Z"
  }
}
```

Update query:
```sql
UPDATE goal_meta
SET availability_json = json(?),
    onboarding_complete = CASE WHEN learning_style_json != '{}' THEN 1 ELSE 0 END
WHERE goal_id = ?;
```

## Completion Check
This category is complete when:
1. `hours_per_day` is recorded (integer 1-12)
2. `days_per_week` array is populated (at least 1 day)
3. `preferred_times` array is populated (at least 1 time slot)
4. JSON stored in `availability_json` column

Proceed to: `onboarding/learning-style.md`
