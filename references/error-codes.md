# MIT Learning Skill - Error Codes

## Error Code Ranges

| Range | Category |
|-------|----------|
| E001-E099 | Goal errors |
| E100-E199 | Topic errors |
| E200-E299 | FSRS errors |
| E300-E399 | Vault errors |
| E400-E499 | Export errors |
| E500-E599 | Session errors |

## Goal Errors (E001-E099)

| Code | Description | Resolution |
|------|-------------|------------|
| E001 | Goal ID already exists | Use different goal_id |
| E002 | Goal not found | Check goal_id spelling |
| E003 | Maximum concurrent goals reached (3) | Archive inactive goal |
| E004 | Goal path inaccessible | Check file permissions |
| E005 | Goal type invalid | Use: exam|skill|degree|topic |

## Topic Errors (E100-E199)

| Code | Description | Resolution |
|------|-------------|------------|
| E101 | Topic not found | Check topic_id |
| E102 | Prerequisite not satisfied | Complete prerequisites first |
| E103 | Maximum topics limit (500) | Split into multiple goals |
| E104 | Topic already exists | Use different topic_id |
| E105 | Circular prerequisite detected | Check dependency graph |

## FSRS Errors (E200-E299)

| Code | Description | Resolution |
|------|-------------|------------|
| E201 | Invalid stability value | Use positive number |
| E202 | Invalid difficulty value | Use 1-10 range |
| E203 | Invalid performance score | Use 0.0-1.0 range |
| E204 | FSRS calculation failed | Use default interval (7 days) |
| E205 | State transition invalid | Reset topic state |

## Vault Errors (E300-E399)

| Code | Description | Resolution |
|------|-------------|------------|
| E301 | Vault path not accessible | Check directory exists |
| E302 | Note write failed | Check write permissions |
| E303 | Invalid note format | Check markdown syntax |
| E304 | Dashboard update failed | Check file permissions |
| E305 | Archive operation failed | Check source file exists |

## Export Errors (E400-E499)

| Code | Description | Resolution |
|------|-------------|------------|
| E401 | Export format not supported | Use markdown or apkg |
| E402 | Export path not writable | Check permissions |
| E403 | Export data incomplete | Check topic data |

## Session Errors (E500-E599)

| Code | Description | Resolution |
|------|-------------|------------|
| E501 | Session not found | Check session_id |
| E502 | Session already ended | Start new session |
| E503 | Performance not recorded | Provide performance score |
| E504 | Session timeout exceeded | Restart session |
