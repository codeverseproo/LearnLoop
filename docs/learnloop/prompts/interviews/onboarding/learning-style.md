# Interview: Onboarding - Learning Style

## Trigger
Activates after `availability_json` is populated (onboarding availability complete).

## Question
How do you learn most effectively?

## Response Options
- [ ] Option A: Visual learner (diagrams, charts, videos, mind maps)
- [ ] Option B: Auditory learner (lectures, podcasts, discussions, verbal explanations)
- [ ] Option C: Kinesthetic learner (hands-on practice, labs, exercises, real-world application)
- [ ] Option D: Reading/writing learner (textbooks, articles, note-taking, documentation)
- [ ] Option E:Mixed: Multiple styles equally effective

## Adaptive Follow-ups
IF response = A THEN: Ask about visual format preferences
IF response = B THEN: Ask about audio format preferences
IF response = C THEN: Ask about hands-on activity preferences
IF response = D THEN: Ask about reading format preferences
IF response = E THEN: Ask for secondary style preference

### Follow-up Question 2
What pacing works best for you?

## Response Options (Question 2)
- [ ] Option A: Self-paced (no deadlines, learn at my own speed)
- [ ] Option B: Moderately structured (weekly milestones, flexible within)
- [ ] Option C: Highly structured (daily goals, scheduled sessions)
- [ ] Option D: Interval-based (intensive sprints with breaks)

### Follow-up Question 3
What note format helps you retain information best?

## Response Options (Question 3)
- [ ] Option A: Structured outlines (hierarchical, bullet points, clear sections)
- [ ] Option B: Narrative summaries (paragraphs, storytelling, flowing text)
- [ ] Option C: Question-answer format (Q&A, flashcard-ready, self-testing)
- [ ] Option D: Visual summaries (mind maps, diagrams, concept maps)
- [ ] Option E: Minimal notes (key points only, reference links)

## Storage
```json
{
  "learning_style_json": {
    "primary_style": "visual",
    "secondary_style": "kinesthetic",
    "pacing": "self-paced",
    "note_format": "structured",
    "version": 1,
    "completed_at": "2026-09-04T10:05:00Z"
  }
}
```

Update query:
```sql
UPDATE goal_meta
SET learning_style_json = json(?),
    onboarding_complete = 1
WHERE goal_id = ?;
```

## Completion Check
This category is complete when:
1. `primary_style` is recorded (visual/auditory/kinesthetic/reading/mixed)
2. `pacing` is recorded (self-paced/moderately-structured/highly-structured/interval-based)
3. `note_format` is recorded (structured/narrative/qanda/visual/minimal)
4. JSON stored in `learning_style_json` column
5. `onboarding_complete = 1` flag set

Onboarding interview sequence complete. Proceed to per-goal interview if goal exists, otherwise return to workflow.
