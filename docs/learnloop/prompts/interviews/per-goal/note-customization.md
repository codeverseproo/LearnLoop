# Interview: Per-Goal - Note Customization

## Trigger
After timeline assessment. Fourth and final prompt in the per-goal interview sequence.

## Question
What default note format works best for your learning style?

## Response Options
- [ ] A: Structured — Clear headings, bullet points, organized sections
- [ ] B: Detailed — Comprehensive explanations, extensive examples
- [ ] C: Concise — Key points only, summary-focused, quick reference
- [ ] D: Visual — Diagrams, mind maps, tables, flowcharts emphasized
- [ ] E: Academic — Formal style, citations, quiz-style review sections

## Adaptive Follow-ups
IF response = A THEN: "Good for review. Want checkboxes for progress tracking?"
IF response = B THEN: "For deep understanding. Include worked examples by default?"
IF response = C THEN: "Quick reference focus. Include flashcard-style Q&A sections?"
IF response = D THEN: "Visual learner. Prefer Mermaid diagrams or ASCII tables?"
IF response = E THEN: "Academic rigor. Include practice questions in each note?"

## Secondary Questions

### Question 2: Default Depth
What depth level should your notes default to?
- [ ] Overview — High-level concepts, ~500 words/topic
- [ ] Detailed — In-depth coverage, ~1500 words/topic
- [ ] Expert — Comprehensive with advanced applications, ~2500+ words/topic

### Question 3: Default Inclusions
What should be included by default in every note?

Check all that apply:
- [ ] Real-world examples
- [ ] Practice exercises
- [ ] Flashcard prompts
- [ ] Prerequisites/dependencies
- [ ] Common pitfalls/warnings
- [ ] Quick reference summary
- [ ] Next steps/further reading

### Question 4: Output Format
Preferred output location for generated notes?
- [ ] Obsidian vault (default: `{vault_path}/notes/`)
- [ ] Markdown files in project directory
- [ ] Display in chat only (no file saved)

## Storage
```json
{
  "note_format": "{response_letter}",
  "format_description": "{selected_option_text}",
  "default_depth": "{depth_level}",
  "default_inclusions": {
    "examples": "{true/false}",
    "exercises": "{true/false}",
    "flashcards": "{true/false}",
    "prerequisites": "{true/false}",
    "pitfalls": "{true/false}",
    "summary": "{true/false}",
    "further_reading": "{true/false}"
  },
  "visual_format": "{mermaid/ascii/none}",
  "progress_checkboxes": "{true/false}",
  "output_location": "{obsidian/markdown/chat}",
  "version": 1,
  "completed_at": "{ISO_date}"
}
```

## Completion Check
Category complete when:
- Note format selected (A-E)
- Default depth chosen
- At least one default inclusion specified
- Output location selected
- Timestamp recorded

## Goal Interview Completion
This is the final prompt in the per-goal interview sequence.

After completion:
1. Set `goal_interview_complete = 1` in `goal_meta`
2. Store combined data in `goal_profile_json`
3. Proceed to syllabus generation workflow
