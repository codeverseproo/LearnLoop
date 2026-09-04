# Interview: Per-Note - Additional Content

## Trigger
Before each note generation, ask user about additional content to include in this note.

## Question
What additional content should this note include?

## Response Options
- [ ] Option A: Examples - Real-world examples and case studies
- [ ] Option B: Exercises - Practice problems and self-check questions
- [ ] Option C: Flashcards - Ready-to-review flashcard format
- [ ] Option D: Multiple - Select more than one (specify: ___________)

## Adaptive Follow-ups
IF response = A (Examples) THEN: Ask quantity - "How many examples? (1-3 typical)"
IF response = B (Exercises) THEN: Ask difficulty - "Exercise difficulty: beginner, intermediate, advanced?"
IF response = C (Flashcards) THEN: Ask format - "Flashcard format: Q&A, fill-blank, or mixed?"
IF response = D (Multiple) THEN: Clarify combination - "Which combinations? Examples + Exercises, all three, other?"

## Storage
```json
{
  "include_examples": false,
  "include_exercises": false,
  "include_flashcards": false,
  "example_count": 0,
  "exercise_difficulty": null,
  "flashcard_format": null,
  "timestamp": "2026-09-04T10:00:00Z"
}
```

## Completion Check
Category complete when user specifies which additional content types to include (can be none, one, or multiple).
