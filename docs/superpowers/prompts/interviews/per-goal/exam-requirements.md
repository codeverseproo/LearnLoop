# Interview: Per-Goal - Exam Requirements

## Trigger
After baseline knowledge assessment. Second prompt in the per-goal interview sequence.

## Question
Are you preparing for a specific certification or exam for **{goal_name}**?

## Response Options
- [ ] A: Yes — I have a specific exam date and target score
- [ ] B: Yes — I know the exam but haven't scheduled it yet
- [ ] C: Maybe — I'm considering certification but haven't decided
- [ ] D: No — this is for general knowledge or skill development

## Adaptive Follow-ups
IF response = A THEN: Ask exam details (date, passing score, provider)
IF response = B THEN: Ask which exam and expected timeline
IF response = C THEN: Ask which certifications interest them and why
IF response = D THEN: Skip to next category (timeline)

## Secondary Questions (if A or B selected)

### Question 2A: Exam Details
What is the exam name and provider?
Examples: "AWS SAA-C03", "CompTIA Security+", "PMP"

### Question 2B: Exam Date
When is your exam scheduled (or target date)?
Format: YYYY-MM-DD or "X weeks from now"

### Question 2C: Passing Score
What is the required passing score (if known)?
Examples: "720/1000", "70%", "Unsure"

### Question 2D: Prerequisites
Are there any prerequisite certifications or requirements?
Examples: "None", "AWS CCP first", "35 hours PM training"

## Storage
```json
{
  "exam_prep": "{response_letter}",
  "exam_name": "{exam_name}",
  "exam_provider": "{provider}",
  "exam_date": "{YYYY-MM-DD}",
  "passing_score": "{score}",
  "prerequisites": ["{prereq_list}"],
  "version": 1,
  "completed_at": "{ISO_date}"
}
```

## Completion Check
Category complete when:
- Exam intent selected (A-D)
- If A or B: exam name, date, and passing score recorded
- If C: exam name(s) of interest recorded
- Timestamp recorded
