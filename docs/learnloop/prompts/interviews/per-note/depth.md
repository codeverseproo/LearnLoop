# Interview: Per-Note - Depth

## Trigger
Before each note generation, ask user about desired depth level for this specific note.

## Question
How detailed should this note be?

## Response Options
- [ ] Option A: Overview - High-level summary, key concepts only (5-10 min read)
- [ ] Option B: Detailed - Full explanations, examples, diagrams (20-30 min read)
- [ ] Option C: Expert - Deep dive, advanced nuances, research references (45+ min read)
- [ ] Option D: Custom: ___________

## Adaptive Follow-ups
IF response = A (Overview) THEN: Confirm scope - "Overview selected. Will cover only essential points. Proceed?"
IF response = B (Detailed) THEN: Ask about primary focus - "Detailed selected. Any specific aspect to emphasize?"
IF response = C (Expert) THEN: Warn about time - "Expert depth requires significant study time. Time budget OK?"
IF response = D (Custom) THEN: Clarify - "Describe your desired depth level"

## Storage
```json
{
  "depth": "overview|detailed|expert|custom",
  "custom_depth": null,
  "timestamp": "2026-09-04T10:00:00Z"
}
```

## Completion Check
Category complete when user selects one option and any follow-up clarifications are answered.
