# Achievement System Definitions

## Design Principles

1. **Early Accessibility**: 43.1% unlock on day one
2. **Harder = Better**: 74.2% retention for difficult achievements
3. **Discovery Focus**: Unlock content, not just badges

## Achievement Definitions

| ID | Name | Description | Difficulty | Trigger |
|----|------|-------------|------------|---------|
| first_topic | First Step | Complete your first topic | easy | topics_completed >= 1 |
| week_streak | Week Warrior | Maintain 7-day streak | medium | current_streak >= 7 |
| ten_topics | Knowledge Builder | Master 10 topics | hard | topics_mastered >= 10 |
| interleave_master | Pattern Seeker | 10 interleaved sessions | hard | interleaved_sessions >= 10 |
| early_bird | Early Bird | Session before 8am | medium | session_before_8am >= 1 |
| month_streak | Month Master | 30-day streak | hard | current_streak >= 30 |
| review_100 | Century Reviewer | 100 reviews completed | medium | total_reviews >= 100 |
| perfect_week | Perfect Week | 100% correct for 7 days | hard | perfect_days >= 7 |

## Streak Mechanics

- Activity = learning, review, or practice session
- Streak freeze: 1 per month, protects 1 missed day
- Reset to 0 if no activity and no freeze
- Warning at 8pm if no activity today

## Display Format

```markdown
## Achievements
- [x] First Step: Complete your first topic
- [x] Week Warrior: 7-day streak
- [ ] Knowledge Builder: Master 10 topics (7/10)
```
