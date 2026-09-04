# Interview: Per-Note - Focus

## Trigger
Before each note generation, ask user about the focus mode for this specific note.

## Question
What focus mode should guide this note's content?

## Response Options
- [ ] Option A: Exam-oriented - Prioritize testable material, practice questions, exam tips
- [ ] Option B: Practical - Emphasize real-world application, hands-on examples, tool usage
- [ ] Option C: Theoretical - Focus on concepts, theory, underlying principles
- [ ] Option D: Custom: ___________

## Adaptive Follow-ups
IF response = A (Exam-oriented) THEN: Ask about exam relevance - "Any specific exam topics to prioritize?"
IF response = B (Practical) THEN: Ask about context - "Any specific use case or project in mind?"
IF response = C (Theoretical) THEN: Confirm depth alignment - "Theoretical focus pairs well with Expert depth. Confirm?"
IF response = D (Custom) THEN: Clarify - "Describe your desired focus mode"

## Storage
```json
{
  "focus_mode": "exam-oriented|practical|theoretical|custom",
  "custom_focus": null,
  "exam_topics": [],
  "practical_context": null,
  "timestamp": "2026-09-04T10:00:00Z"
}
```

## Completion Check
Category complete when user selects one option and any focus-specific clarifications are answered.
