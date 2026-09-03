# MIT Learning Skill - Error Handling Documentation

**Version 3.0 - Exhaustive Edition**

---

## Table of Contents

1. [Error Code Ranges](#1-error-code-ranges)
2. [Goal Errors (E001-E099)](#2-goal-errors-e001-e099)
3. [Topic Errors (E100-E199)](#3-topic-errors-e100-e199)
4. [FSRS Errors (E200-E299)](#4-fsrs-errors-e200-e299)
5. [Vault Errors (E300-E399)](#5-vault-errors-e300-e399)
6. [Export Errors (E400-E499)](#6-export-errors-e400-e499)
7. [Session Errors (E500-E599)](#7-session-errors-e500-e599)
8. [Research Errors (E600-E699)](#8-research-errors-e600-e699)
9. [Memory Errors (E700-E799)](#9-memory-errors-e700-e799)
10. [Network Errors (E800-E899)](#10-network-errors-e800-e899)
11. [System Errors (E900-E999)](#11-system-errors-e900-e999)
12. [Graceful Degradation](#12-graceful-degradation)

---

## 1. Error Code Ranges

| Range | Category | Count |
|-------|----------|-------|
| E001-E099 | Goal errors | 5 |
| E100-E199 | Topic errors | 5 |
| E200-E299 | FSRS errors | 5 |
| E300-E399 | Vault errors | 5 |
| E400-E499 | Export errors | 3 |
| E500-E599 | Session errors | 4 |
| E600-E699 | Research errors | 5 |
| E700-E799 | Memory errors | 5 |
| E800-E899 | Network errors | 3 |
| E900-E999 | System errors | 5 |

---

## 2. Goal Errors (E001-E099)

### E001: Goal Already Exists

| Attribute | Value |
|-----------|-------|
| **Code** | E001 |
| **Name** | GOAL_EXISTS |
| **Description** | A goal with this ID already exists |
| **Trigger** | Attempting to create a goal that already has a database |
| **User Message** | "A learning plan for '{goal_name}' already exists. Would you like to continue with the existing plan or create a new one with a different name?" |
| **Resolution** | Use different goal_id or continue with existing |
| **Prevention** | Check `~/.mit-learning/goals/{goal_id}/` before creating |

```python
# Handling
if db_path.exists():
    raise FileExistsError(f"E001: Goal database already exists at {db_path}")
```

### E002: Goal Not Found

| Attribute | Value |
|-----------|-------|
| **Code** | E002 |
| **Name** | GOAL_NOT_FOUND |
| **Description** | The specified goal does not exist |
| **Trigger** | Accessing a goal_id that has no database |
| **User Message** | "Learning plan '{goal_id}' not found. Check the spelling or create a new plan." |
| **Resolution** | Check spelling or create new goal |
| **Prevention** | List available goals first |

### E003: Maximum Goals Reached

| Attribute | Value |
|-----------|-------|
| **Code** | E003 |
| **Name** | MAX_GOALS_REACHED |
| **Description** | Maximum concurrent goals (3) reached |
| **Trigger** | Creating a 4th goal when 3 already exist |
| **User Message** | "You have 3 active learning plans. Please archive an existing plan before creating a new one." |
| **Resolution** | Archive an existing goal |
| **Prevention** | Check goal count before creating |

### E004: Invalid Goal ID

| Attribute | Value |
|-----------|-------|
| **Code** | E004 |
| **Name** | INVALID_GOAL_ID |
| **Description** | Goal ID contains invalid characters |
| **Trigger** | Goal ID with special characters, spaces, or too long |
| **User Message** | "Goal name must use only letters, numbers, hyphens, and underscores. Maximum 64 characters." |
| **Resolution** | Use valid characters |
| **Prevention** | Validate with regex before use |

```python
SAFE_ID_PATTERN = re.compile(r'^[a-zA-Z0-9-_]+$')
if not SAFE_ID_PATTERN.match(goal_id):
    raise ValidationError("E004", f"Invalid goal_id: {goal_id}")
```

### E005: Invalid Goal Type

| Attribute | Value |
|-----------|-------|
| **Code** | E005 |
| **Name** | INVALID_GOAL_TYPE |
| **Description** | Goal type must be exam, skill, degree, or topic |
| **Trigger** | Using unsupported goal type |
| **User Message** | "Goal type must be one of: exam, skill, degree, topic" |
| **Resolution** | Use valid goal type |

---

## 3. Topic Errors (E100-E199)

### E101: Topic Not Found

| Attribute | Value |
|-----------|-------|
| **Code** | E101 |
| **Name** | TOPIC_NOT_FOUND |
| **Description** | The specified topic does not exist |
| **Trigger** | Accessing non-existent topic_id |
| **User Message** | "Topic '{topic_id}' not found in this learning plan." |
| **Resolution** | Check topic_id or list available topics |

### E102: Prerequisite Not Satisfied

| Attribute | Value |
|-----------|-------|
| **Code** | E102 |
| **Name** | PREREQ_NOT_SATISFIED |
| **Description** | Topic prerequisites have not been completed |
| **Trigger** | Trying to learn topic before prerequisites mastered |
| **User Message** | "Complete prerequisites first: {prereq_list}" |
| **Resolution** | Complete prerequisite topics |
| **Graceful Handling** | Offer to start with prerequisite |

### E103: Maximum Topics Reached

| Attribute | Value |
|-----------|-------|
| **Code** | E103 |
| **Name** | MAX_TOPICS_REACHED |
| **Description** | Maximum topics per goal (500) reached |
| **Trigger** | Adding 501st topic to a goal |
| **User Message** | "This plan has reached 500 topics. Consider splitting into multiple goals." |
| **Resolution** | Create a new goal or remove unused topics |

### E104: Topic Already Exists

| Attribute | Value |
|-----------|-------|
| **Code** | E104 |
| **Name** | TOPIC_EXISTS |
| **Description** | Topic with this ID already exists |
| **Trigger** | Creating duplicate topic_id |
| **User Message** | "Topic '{topic_id}' already exists." |
| **Resolution** | Use different topic_id |

### E105: Circular Prerequisite

| Attribute | Value |
|-----------|-------|
| **Code** | E105 |
| **Name** | CIRCULAR_PREREQ |
| **Description** | Circular prerequisite dependency detected |
| **Trigger** | Setting prerequisites that create a cycle |
| **User Message** | "Cannot set prerequisite - this would create a circular dependency." |
| **Resolution** | Break the cycle by removing a prerequisite |

---

## 4. FSRS Errors (E200-E299)

### E201: Invalid Stability

| Attribute | Value |
|-----------|-------|
| **Code** | E201 |
| **Name** | INVALID_STABILITY |
| **Description** | Stability must be non-negative |
| **Trigger** | Negative stability value |
| **User Message** | "Internal error: Invalid scheduling parameters. Using default schedule." |
| **Resolution** | Reset to default |
| **Graceful Handling** | Use default 7-day interval |

```python
if stability < 0:
    raise ValueError("E201: Invalid stability value - must be non-negative")
```

### E202: Invalid Difficulty

| Attribute | Value |
|-----------|-------|
| **Code** | E202 |
| **Name** | INVALID_DIFFICULTY |
| **Description** | Difficulty must be in range 1-10 |
| **Trigger** | Difficulty outside valid range |
| **User Message** | "Internal error: Invalid difficulty. Using default." |
| **Graceful Handling** | Clamp to 1-10 range |

### E203: Invalid Performance

| Attribute | Value |
|-----------|-------|
| **Code** | E203 |
| **Name** | INVALID_PERFORMANCE |
| **Description** | Performance must be in range 0.0-1.0 |
| **Trigger** | Performance score outside valid range |
| **User Message** | "Invalid performance rating. Please rate 1-4." |
| **Resolution** | Provide valid rating |

### E204: FSRS Calculation Failed

| Attribute | Value |
|-----------|-------|
| **Code** | E204 |
| **Name** | FSRS_CALC_FAILED |
| **Description** | FSRS algorithm calculation error |
| **Trigger** | Numerical overflow, underflow, or NaN |
| **User Message** | "Scheduling calculation error. Using default review schedule." |
| **Graceful Handling** | Use default 7-day interval |

### E205: Invalid State Transition

| Attribute | Value |
|-----------|-------|
| **Code** | E205 |
| **Name** | INVALID_STATE |
| **Description** | Invalid FSRS state transition |
| **Trigger** | State value outside 0-3 range |
| **Resolution** | Reset state to 0 |

---

## 5. Vault Errors (E300-E399)

### E301: Vault Path Inaccessible

| Attribute | Value |
|-----------|-------|
| **Code** | E301 |
| **Name** | VAULT_PATH_ERROR |
| **Description** | Cannot access Obsidian vault path |
| **Trigger** | Directory doesn't exist or no permissions |
| **User Message** | "Cannot access vault at '{path}'. Please check the directory exists and you have write permissions." |
| **Resolution** | Create directory or fix permissions |

### E302: Invalid Topic ID

| Attribute | Value |
|-----------|-------|
| **Code** | E302 |
| **Name** | INVALID_TOPIC_ID |
| **Description** | Topic ID contains invalid characters |
| **Trigger** | Topic ID with filesystem-unsafe characters |
| **User Message** | "Topic ID must use only letters, numbers, hyphens, and underscores." |
| **Resolution** | Use valid topic_id |

### E303: Note Write Failed

| Attribute | Value |
|-----------|-------|
| **Code** | E303 |
| **Name** | NOTE_WRITE_FAILED |
| **Description** | Failed to write note to vault |
| **Trigger** | Disk full, permissions, or I/O error |
| **User Message** | "Could not save note. Your progress is saved but note export failed." |
| **Graceful Handling** | Save to SQLite, retry later |

### E304: Dashboard Update Failed

| Attribute | Value |
|-----------|-------|
| **Code** | E304 |
| **Name** | DASHBOARD_UPDATE_FAILED |
| **Description** | Failed to update progress dashboard |
| **Trigger** | Write error or template issue |
| **User Message** | "Dashboard update failed. Your data is safe, but visual progress may be outdated." |
| **Graceful Handling** | Retry on next session |

### E305: Archive Failed

| Attribute | Value |
|-----------|-------|
| **Code** | E305 |
| **Name** | ARCHIVE_FAILED |
| **Description** | Failed to archive completed topic |
| **Trigger** | File move error |
| **Resolution** | Manually move file |

---

## 6. Export Errors (E400-E499)

### E401: Unsupported Export Format

| Attribute | Value |
|-----------|-------|
| **Code** | E401 |
| **Name** | EXPORT_FORMAT_UNSUPPORTED |
| **Description** | Export format not supported |
| **Trigger** | Requesting invalid export format |
| **User Message** | "Export format not supported. Use: markdown, anki, pdf" |
| **Resolution** | Use supported format |

### E402: Export Path Not Writable

| Attribute | Value |
|-----------|-------|
| **Code** | E402 |
| **Name** | EXPORT_PATH_ERROR |
| **Description** | Cannot write to export path |
| **Trigger** | No write permissions |
| **Resolution** | Choose different path |

### E403: Export Data Incomplete

| Attribute | Value |
|-----------|-------|
| **Code** | E403 |
| **Name** | EXPORT_INCOMPLETE |
| **Description** | Export data missing required fields |
| **Trigger** | Corrupted or incomplete topic data |
| **Graceful Handling** | Export available data, note missing |

---

## 7. Session Errors (E500-E599)

### E501: Session Not Found

| Attribute | Value |
|-----------|-------|
| **Code** | E501 |
| **Name** | SESSION_NOT_FOUND |
| **Description** | Referenced session doesn't exist |
| **Resolution** | Start new session |

### E502: Session Already Ended

| Attribute | Value |
|-----------|-------|
| **Code** | E502 |
| **Name** | SESSION_ENDED |
| **Description** | Cannot modify completed session |
| **Resolution** | Start new session |

### E503: Performance Not Recorded

| Attribute | Value |
|-----------|-------|
| **Code** | E503 |
| **Name** | PERFORMANCE_MISSING |
| **Description** | Session missing performance data |
| **Resolution** | Provide performance rating |

### E504: Session Timeout

| Attribute | Value |
|-----------|-------|
| **Code** | E504 |
| **Name** | SESSION_TIMEOUT |
| **Description** | Session exceeded maximum duration |
| **Trigger** | Inactive for >30 minutes |
| **User Message** | "Session timed out. Your progress has been saved." |
| **Resolution** | Resume or start new |

---

## 8. Research Errors (E600-E699)

### E600: No Sources Found

| Attribute | Value |
|-----------|-------|
| **Code** | E600 |
| **Name** | NO_SOURCES_FOUND |
| **Description** | No sources found for research topic |
| **Trigger** | WebSearch returns empty |
| **User Message** | "No sources found for '{topic}'. This topic may need manual research." |
| **Graceful Handling** | Mark as "needs manual research" |

### E601: Contradicting Sources

| Attribute | Value |
|-----------|-------|
| **Code** | E601 |
| **Name** | SOURCES_CONTRADICT |
| **Description** | Sources contradict each other |
| **Trigger** | Conflicting information from sources |
| **User Message** | "Sources disagree on '{claim}'. Both viewpoints are shown." |
| **Graceful Handling** | Present both positions |

### E602: Source Fetch Failed

| Attribute | Value |
|-----------|-------|
| **Code** | E602 |
| **Name** | SOURCE_FETCH_FAILED |
| **Description** | Failed to retrieve source content |
| **Trigger** | Network error, paywall, or removed content |
| **User Message** | "Could not retrieve source. Using available information." |
| **Graceful Handling** | Continue with other sources |

### E603: Claim Unverified

| Attribute | Value |
|-----------|-------|
| **Code** | E603 |
| **Name** | CLAIM_UNVERIFIED |
| **Description** | Claim lacks sufficient sources |
| **Trigger** | Less than 3 sources found |
| **User Message** | "⚠️ This claim needs more sources for verification." |
| **Display** | Mark with warning icon |

### E604: Research Timeout

| Attribute | Value |
|-----------|-------|
| **Code** | E604 |
| **Name** | RESEARCH_TIMEOUT |
| **Description** | Research exceeded time limit |
| **Trigger** | Research takes >120 seconds |
| **User Message** | "Research is taking longer than expected. Showing partial results." |
| **Graceful Handling** | Return partial results |

---

## 9. Memory Errors (E700-E799)

### E701: Database Locked

| Attribute | Value |
|-----------|-------|
| **Code** | E701 |
| **Name** | DATABASE_LOCKED |
| **Description** | SQLite database is locked |
| **Trigger** | Concurrent access conflict |
| **User Message** | "Database temporarily locked. Retrying..." |
| **Graceful Handling** | Exponential backoff retry |

```python
def retry_with_backoff(func, max_retries=5):
    for attempt in range(max_retries):
        try:
            return func()
        except sqlite3.OperationalError as e:
            if "locked" in str(e) and attempt < max_retries - 1:
                time.sleep(2 ** attempt * 0.1)
            else:
                raise
```

### E702: Vault Not Found

| Attribute | Value |
|-----------|-------|
| **Code** | E702 |
| **Name** | VAULT_NOT_FOUND |
| **Description** | Obsidian vault does not exist |
| **Trigger** | Vault path not found |
| **User Message** | "Obsidian vault not found. Database-only mode enabled." |
| **Graceful Handling** | SQLite-only fallback |

### E703: Disk Full

| Attribute | Value |
|-----------|-------|
| **Code** | E703 |
| **Name** | DISK_FULL |
| **Description** | No space to write data |
| **Trigger** | Disk at capacity |
| **User Message** | "Storage is full. Please free up space to continue." |
| **Resolution** | Free disk space |

### E704: Corruption Detected

| Attribute | Value |
|-----------|-------|
| **Code** | E704 |
| **Name** | DATA_CORRUPTION |
| **Description** | Database integrity check failed |
| **Trigger** | SQLite PRAGMA integrity_check failure |
| **User Message** | "Data corruption detected. Attempting automatic recovery from backup." |
| **Graceful Handling** | Restore from backup |

### E705: Permission Denied

| Attribute | Value |
|-----------|-------|
| **Code** | E705 |
| **Name** | PERMISSION_DENIED |
| **Description** | Cannot write to directory |
| **Trigger** | Insufficient permissions |
| **User Message** | "Cannot write to '{path}'. Please check folder permissions." |
| **Resolution** | Fix permissions |

---

## 10. Network Errors (E800-E899)

### E801: Network Unavailable

| Attribute | Value |
|-----------|-------|
| **Code** | E801 |
| **Name** | NETWORK_UNAVAILABLE |
| **Description** | No internet connection |
| **Trigger** | Network unreachable |
| **User Message** | "No internet connection. Research features unavailable. Offline mode active." |
| **Graceful Handling** | Offline mode |

### E802: Request Timeout

| Attribute | Value |
|-----------|-------|
| **Code** | E802 |
| **Name** | REQUEST_TIMEOUT |
| **Description** | Network request timed out |
| **Trigger** | Request >30 seconds |
| **User Message** | "Request timed out. Retrying..." |
| **Graceful Handling** | Retry with backoff |

### E803: Rate Limited

| Attribute | Value |
|-----------|-------|
| **Code** | E803 |
| **Name** | RATE_LIMITED |
| **Description** | Too many requests |
| **Trigger** | API rate limit exceeded |
| **User Message** | "Please wait before making more requests." |
| **Graceful Handling** | Queue and retry later |

---

## 11. System Errors (E900-E999)

### E901: Unsupported Python Version

| Attribute | Value |
|-----------|-------|
| **Code** | E901 |
| **Name** | PYTHON_VERSION |
| **Description** | Python version < 3.11 |
| **Resolution** | Upgrade Python |

### E902: Missing Dependency

| Attribute | Value |
|-----------|-------|
| **Code** | E902 |
| **Name** | MISSING_DEPENDENCY |
| **Description** | Required package not installed |
| **Resolution** | Install package |

### E903: Configuration Error

| Attribute | Value |
|-----------|-------|
| **Code** | E903 |
| **Name** | CONFIG_ERROR |
| **Description** | Invalid configuration |
| **Graceful Handling** | Use defaults |

### E904: Migration Required

| Attribute | Value |
|-----------|-------|
| **Code** | E904 |
| **Name** | MIGRATION_REQUIRED |
| **Description** | Database schema needs update |
| **Resolution** | Run migration |

### E905: Unknown Error

| Attribute | Value |
|-----------|-------|
| **Code** | E905 |
| **Name** | UNKNOWN_ERROR |
| **Description** | Unexpected error |
| **User Message** | "An unexpected error occurred. Please report this issue." |

---

## 12. Graceful Degradation

### 12.1 Fallback Matrix

| Error Type | Fallback | User Impact |
|------------|----------|-------------|
| FSRS calculation failed | Default 7-day interval | Slightly suboptimal scheduling |
| Vault write failed | SQLite-only mode | No visual dashboard |
| Research failed | Mark "needs manual research" | Incomplete notes |
| Database locked | Retry with backoff | Brief delay |
| Network unavailable | Use cache, offline mode | Limited research |

### 12.2 Recovery Procedures

```python
async def recover_from_error(error: Exception) -> RecoveryAction:
    """Determine recovery action for error."""
    
    if isinstance(error, (E201, E202, E203, E204)):
        return RecoveryAction(
            action='use_default',
            message='Using default scheduling parameters'
        )
    
    elif isinstance(error, (E301, E302, E303)):
        return RecoveryAction(
            action='sqlite_only',
            message='Running in database-only mode'
        )
    
    elif isinstance(error, (E600, E602, E604)):
        return RecoveryAction(
            action='partial_results',
            message='Returning partial research results'
        )
    
    else:
        return RecoveryAction(
            action='report',
            message='Please report this error'
        )
```

---

*Document generated: September 1, 2026*
*Total pages: 20+*
