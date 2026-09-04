# Interview: Per-Note - Time Budget

## Trigger
Before each note generation, ask user about time available for this note.

## Question
How much time do you have to study this note?

## Response Options
- [ ] Option A: Quick review - 10-15 minutes (overview scan)
- [ ] Option B: Standard session - 30-45 minutes (typical study session)
- [ ] Option C: Deep dive - 60-90 minutes (thorough study)
- [ ] Option D: Custom: ___________ minutes

## Adaptive Follow-ups
IF response = A (Quick review) THEN: Warn if depth conflicts - "Quick review works best with Overview depth. Adjust depth?"
IF response = B (Standard session) THEN: Confirm - "Standard session selected. Good for Detailed depth notes."
IF response = C (Deep dive) THEN: Ask about breaks - "Deep dive planned. Prefer single session or split into parts?"
IF response = D (Custom) THEN: Validate - "Custom time: X minutes. Confirm this fits your schedule."

## Storage
```json
{
  "time_budget_minutes": 30,
  "session_preference": "single|split",
  "split_count": 1,
  "timestamp": "2026-09-04T10:00:00Z"
}
```

## Completion Check
Category complete when user specifies time budget and any session preference clarifications are answered.
