# MIT Learning Skill Architecture

## 1. Three-Tier Memory Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        MEMORY TIERS                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────────────┐    │
│  │     HOT      │   │     WARM     │   │        COLD           │    │
│  │   Session    │ → │    SQLite    │ → │      Obsidian        │    │
│  │   Context    │   │  memory.db   │   │       Vault          │    │
│  └──────────────┘   └──────────────┘   └──────────────────────┘    │
│                                                                      │
│  Latency: 0ms           Latency: 1-5ms       Latency: 10-50ms      │
│  Duration: Session      Duration: Permanent   Duration: Permanent    │
│  Storage: RAM          Storage: Disk         Storage: Markdown     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Tier Characteristics

| Tier | Storage | Latency | Persistence | Use Case |
|------|---------|---------|-------------|----------|
| **HOT** | In-memory (session context) | 0ms | Session lifetime | Active learning session state, temporary calculations |
| **WARM** | SQLite (`~/.mit-learning/goals/{goal_id}/memory.db`) | 1-5ms | Permanent | FSRS state, mastery tracking, session history |
| **COLD** | Obsidian vault (`~/Obsidian/MIT-{goal-slug}/`) | 10-50ms | Permanent | Comprehensive notes, knowledge graph, reviewed content |

### Data Flow Between Tiers

```mermaid
flowchart LR
    subgraph HOT_TIER [HOT - Session]
        A[Session Context]
        B[Active Topic State]
        C[Temp Calculations]
    end

    subgraph WARM_TIER [WARM - SQLite]
        D[FSRS State]
        E[Mastery Scores]
        F[Session Log]
        G[Streak State]
    end

    subgraph COLD_TIER [COLD - Obsidian]
        H[Topic Notes]
        I[Review Queue]
        J[Dashboard]
        K[Archived Topics]
    end

    A -->|Update Mastery| D
    B -->|Schedule Review| E
    A -->|Record Session| F
    D -->|Write Note| H
    E -->|Update Dashboard| J
    F -->|Populate Queue| I
    B -->|Archive| K
```

---

## 2. Module Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         MODULE LAYOUT                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│                    ┌──────────────────┐                             │
│                    │  workflow_router  │                             │
│                    │   (Entry Point)   │                             │
│                    └────────┬─────────┘                             │
│                             │                                        │
│          ┌──────────────────┼──────────────────┐                    │
│          ▼                  ▼                  ▼                    │
│   ┌────────────┐    ┌────────────┐    ┌────────────┐               │
│   │  learning  │    │   review   │    │  practice  │               │
│   │  workflow  │    │  workflow  │    │  workflow  │               │
│   └─────┬──────┘    └─────┬──────┘    └─────┬──────┘               │
│         │                 │                 │                        │
│         └─────────────────┼─────────────────┘                        │
│                           ▼                                          │
│    ┌────────────────────────────────────────────────────┐           │
│    │                  CORE MODULES                       │           │
│    ├────────────────────────────────────────────────────┤           │
│    │                                                    │           │
│    │  ┌─────────────┐  ┌──────────────┐  ┌───────────┐ │           │
│    │  │sqlite_init  │  │fsrs_scheduler│  │validation │ │           │
│    │  │             │  │              │  │           │ │           │
│    │  │ - DB create │  │ - FSRS-6    │  │ - Path    │ │           │
│    │  │ - Schema    │  │ - Schedule  │  │   check   │ │           │
│    │  │ - Indexes   │  │ - Mastery   │  │ - Bounds  │ │           │
│    │  └─────────────┘  └──────────────┘  └───────────┘ │           │
│    │                                                    │           │
│    │  ┌─────────────┐  ┌──────────────┐  ┌───────────┐ │           │
│    │  │mastery_     │  │vault_manager │  │research_  │ │           │
│    │  │update       │  │              │  │engine     │ │           │
│    │  │             │  │ - Notes      │  │           │ │           │
│    │  │ - Progress  │  │ - Dashboard  │  │ - Tiered  │ │           │
│    │  │ - Streak    │  │ - Archive    │  │ - Claims  │ │           │
│    │  │ - Freeze    │  │ - Queue      │  │ - Sources │ │           │
│    │  └─────────────┘  └──────────────┘  └───────────┘ │           │
│    │                                                    │           │
│    └────────────────────────────────────────────────────┘           │
│                                                                      │
│    ┌────────────────────────────────────────────────────┐           │
│    │               achievement_engine                   │           │
│    │   (Future: Unlock logic, badge system)             │           │
│    └────────────────────────────────────────────────────┘           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Module Responsibilities

| Module | File | Responsibility |
|--------|------|----------------|
| **workflow_router** | `scripts/workflow_router.py` | Intent analysis, workflow dispatch |
| **sqlite_init** | `scripts/sqlite_init.py` | Database creation, schema initialization |
| **fsrs_scheduler** | `scripts/fsrs_scheduler.py` | FSRS-6 scheduling, mastery calculation |
| **mastery_update** | `scripts/mastery_update.py` | Progress tracking, streak management |
| **vault_manager** | `scripts/vault_manager.py` | Obsidian vault operations, note writing |
| **research_engine** | `scripts/research_engine.py` | Tiered research, claim triangulation |
| **validation** | `scripts/validation.py` | Input sanitization, path traversal prevention |
| **achievement_engine** | `scripts/achievement_engine.py` | Achievement unlock logic (future) |

---

## 3. Database Schema

### Entity Relationship Diagram

```mermaid
erDiagram
    goal_meta ||--o{ topics : "has"
    topics ||--o{ fsrs_state : "tracks"
    topics ||--o{ sessions : "records"
    topics ||--o{ note_registry : "has"
    topics }o--o{ topics : "prerequisites"
    goal_meta ||--|| streak_state : "tracks"
    goal_meta ||--o{ achievements : "unlocks"

    goal_meta {
        TEXT goal_id PK
        TEXT goal_type
        TIMESTAMP created_at
        TEXT vault_path
        INTEGER total_topics
        INTEGER mastered_topics
    }

    topics {
        INTEGER id PK
        TEXT topic_id UK
        TEXT name
        REAL mastery
        TEXT status
        DATE next_review
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    fsrs_state {
        INTEGER topic_id PK, FK
        REAL stability
        REAL difficulty
        INTEGER state
        TIMESTAMP last_review
        TIMESTAMP next_review
        INTEGER reviews
    }

    sessions {
        INTEGER id PK
        TEXT session_type
        INTEGER topic_id FK
        TIMESTAMP started_at
        TIMESTAMP ended_at
        REAL performance
        TEXT notes
    }

    prerequisites {
        INTEGER id PK
        INTEGER topic_id FK
        INTEGER prerequisite_id FK
        TIMESTAMP created_at
    }

    note_registry {
        INTEGER id PK
        INTEGER topic_id FK
        TEXT note_path
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    streak_state {
        TEXT goal_id PK, FK
        INTEGER current_streak
        INTEGER longest_streak
        DATE last_activity_date
        INTEGER streak_freeze_available
        DATE streak_freeze_used_date
    }

    achievements {
        INTEGER id PK
        TEXT goal_id FK
        TEXT achievement_id
        TIMESTAMP unlocked_at
    }
```

### Complete Table Definitions

#### `goal_meta`
```sql
CREATE TABLE goal_meta (
    goal_id TEXT PRIMARY KEY,
    goal_type TEXT NOT NULL,           -- exam|skill|degree|topic
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    vault_path TEXT,                   -- Path to Obsidian vault
    total_topics INTEGER DEFAULT 0,
    mastered_topics INTEGER DEFAULT 0
);
```

#### `topics`
```sql
CREATE TABLE topics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id TEXT UNIQUE NOT NULL,     -- e.g., 'T01-intro-python'
    name TEXT NOT NULL,                -- Display name
    mastery REAL DEFAULT 0.0,         -- 0.0 to 1.0
    status TEXT DEFAULT 'pending',     -- pending|in_progress|mastered
    next_review DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### `fsrs_state`
```sql
CREATE TABLE fsrs_state (
    topic_id INTEGER PRIMARY KEY,
    stability REAL DEFAULT 2.5,        -- Days until 90% retention
    difficulty REAL DEFAULT 5.0,       -- 1-10 scale
    state INTEGER DEFAULT 0,           -- 0=New, 1=Learning, 2=Review, 3=Relearning
    last_review TIMESTAMP,
    next_review TIMESTAMP,
    reviews INTEGER DEFAULT 0,
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);
```

#### `sessions`
```sql
CREATE TABLE sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_type TEXT NOT NULL,        -- review|practice|assessment
    topic_id INTEGER,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP,
    performance REAL,                  -- 0.0 to 1.0
    notes TEXT,
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);
```

#### `prerequisites`
```sql
CREATE TABLE prerequisites (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id INTEGER NOT NULL,
    prerequisite_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (topic_id) REFERENCES topics(id),
    FOREIGN KEY (prerequisite_id) REFERENCES topics(id),
    UNIQUE(topic_id, prerequisite_id)
);
```

#### `note_registry`
```sql
CREATE TABLE note_registry (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id INTEGER NOT NULL,
    note_path TEXT NOT NULL,           -- Path to .md file in vault
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);
```

#### `streak_state`
```sql
CREATE TABLE streak_state (
    goal_id TEXT PRIMARY KEY,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_activity_date DATE,
    streak_freeze_available INTEGER DEFAULT 1,
    streak_freeze_used_date DATE,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id)
);
```

#### `achievements`
```sql
CREATE TABLE achievements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    achievement_id TEXT NOT NULL,      -- e.g., 'first-session', '7-day-streak'
    unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id),
    UNIQUE(goal_id, achievement_id)
);
```

---

## 4. Data Flow Diagrams

### Learning Session Flow

```mermaid
sequenceDiagram
    participant U as User
    participant WR as workflow_router
    participant MU as mastery_update
    participant FS as fsrs_scheduler
    participant DB as SQLite (WARM)
    participant VM as vault_manager
    participant OV as Obsidian (COLD)

    U->>WR: "Learn [topic]"
    WR->>DB: Get topic state
    DB-->>WR: Return fsrs_state
    
    alt New Topic
        WR->>FS: Initialize FSRS state
        FS-->>WR: stability=2.5, difficulty=5.0
    end
    
    WR->>U: Present concept
    
    U->>WR: Complete session (performance)
    WR->>FS: schedule_next_review(performance)
    FS-->>WR: next_review, new_stability
    
    WR->>MU: update_mastery(topic_id, performance)
    MU->>DB: Update fsrs_state
    MU->>DB: Update topics.mastery
    MU->>DB: Insert session record
    
    WR->>VM: write_note(topic_id, content)
    VM->>OV: Create/Update .md file
    
    WR-->>U: Session complete, next review date
```

### Review Session Flow

```mermaid
sequenceDiagram
    participant U as User
    participant WR as workflow_router
    participant DB as SQLite (WARM)
    participant FS as fsrs_scheduler
    participant VM as vault_manager

    U->>WR: "What's due for review?"
    WR->>DB: Query topics WHERE next_review <= today
    DB-->>WR: Return due topics
    
    WR->>FS: calculate_review_priority() for each
    FS-->>WR: Priority scores (retrievability - 0.9)
    
    WR->>VM: write_review_queue(sorted_topics)
    VM-->>U: Display review queue
    
    loop For each topic
        U->>WR: Review topic, rate performance
        WR->>FS: schedule_next_review(performance)
        FS-->>WR: new interval, stability
        WR->>DB: Update fsrs_state
    end
    
    WR-->>U: Review session complete
```

### Research Flow

```mermaid
flowchart TD
    A[User: Research topic] --> B[workflow_router]
    B --> C[research_engine]
    C --> D{Gather Sources}
    
    D -->|Tier 1| E[Academic/Official]
    D -->|Tier 2| F[Broad Web]
    D -->|Tier 3| G[Curated]
    
    E --> H[WebSearch: site:edu OR site:gov]
    F --> I[WebSearch: topic overview]
    G --> J[User-specified feeds]
    
    H --> K[Create Sources]
    I --> K
    J --> K
    
    K --> L[Triangulate Claims]
    L --> M{>= 3 sources?}
    
    M -->|Yes| N[Verified Claim]
    M -->|No| O[Needs Verification Flag]
    
    N --> P[Compile Single Note]
    O --> P
    
    P --> Q[vault_manager.write_note]
    Q --> S[Obsidian: Comprehensive Note]
```

---

## 5. Security Considerations

### Threat Model

```mermaid
flowchart TB
    subgraph ATTACK_SURFACE [Attack Surface]
        A1[goal_id input]
        A2[topic_id input]
        A3[performance input]
        A4[vault paths]
    end
    
    subgraph DEFENSES [Defense Layers]
        D1[Input Validation]
        D2[Parameterized SQL]
        D3[Path Sanitization]
        D4[Bounds Checking]
    end
    
    subgraph IMPACT [Protected Assets]
        I1[SQLite Database]
        I2[Filesystem]
        I3[Obsidian Vault]
    end
    
    A1 --> D1
    A2 --> D1
    A3 --> D1
    A4 --> D3
    
    D1 --> D2
    D1 --> D4
    D2 --> I1
    D3 --> I2
    D3 --> I3
```

### Path Traversal Prevention

**Threat:** User-supplied `goal_id` or `topic_id` containing `../` could access files outside intended directories.

**Defense:** Safe identifier pattern validation.

```python
# scripts/validation.py
SAFE_ID_PATTERN = re.compile(r'^[a-zA-Z0-9-_]+$')

def validate_goal_id(goal_id: str) -> str:
    if not goal_id:
        raise ValidationError("E004", "goal_id cannot be empty")
    
    if not SAFE_ID_PATTERN.match(goal_id):
        raise ValidationError("E004", f"Invalid goal_id format: {goal_id!r}")
    
    if len(goal_id) > 64:
        raise ValidationError("E004", f"goal_id too long: {len(goal_id)} chars")
    
    return goal_id
```

**Blocked patterns:**
- `../` (directory traversal)
- `/` (absolute path)
- `\` (Windows path)
- `.` (hidden files)
- Special characters: `< > : " | ? *`
- Null bytes, control characters

### SQL Injection Prevention

**Threat:** Malicious input in identifiers could execute arbitrary SQL.

**Defense:** Parameterized queries throughout.

```python
# CORRECT: Parameterized query
cursor.execute("""
    SELECT * FROM topics WHERE topic_id = ?
""", (topic_id,))

# WRONG: String interpolation (vulnerable)
cursor.execute(f"SELECT * FROM topics WHERE topic_id = '{topic_id}'")
```

**All database operations use parameterized queries:**
- `sqlite_init.py`: Table creation, inserts
- `mastery_update.py`: Updates, selects
- `vault_manager.py`: None (filesystem only)

### Input Validation Matrix

| Input | Validation | Error Code | File |
|-------|------------|------------|------|
| `goal_id` | SAFE_ID_PATTERN, length ≤64 | E004 | validation.py |
| `goal_type` | Enum: exam/skill/degree/topic | E005 | validation.py |
| `topic_id` | SAFE_ID_PATTERN, length ≤128 | E302 | validation.py |
| `performance` | Numeric, 0.0 ≤ x ≤ 1.0 | E203 | validation.py |
| `stability` | Non-negative if provided | E201 | validation.py |

### Bounds Checking

**FSRS Parameter Bounds:**

```python
# scripts/fsrs_scheduler.py
MAX_STABILITY = 365.0   # 1 year maximum
MAX_INTERVAL = 365      # Cap review interval

def schedule_next_review(...):
    # Cap stability
    stability = min(stability, MAX_STABILITY)
    
    # Clamp interval
    interval_days = max(1, min(MAX_INTERVAL, interval_days))
```

**Prevents:**
- Integer overflow from extreme values
- Unreasonable review intervals (decades)
- Memory exhaustion from large calculations

### Graceful Degradation

```mermaid
flowchart TD
    A[Operation Attempted] --> B{Success?}
    
    B -->|Yes| C[Return Result]
    
    B -->|No - FSRS Failure| D[Default 7-day interval]
    B -->|No - Vault Failure| E[SQLite-only fallback]
    B -->|No - Research Failure| F[Mark 'needs manual research']
    
    D --> G[Log Warning]
    E --> G
    F --> G
    
    G --> H[Continue Operation]
    H --> C
```

| Failure Mode | Fallback | User Impact |
|--------------|----------|-------------|
| FSRS calculation error | Default 7-day review interval | Learning continues, suboptimal scheduling |
| Vault write failure | SQLite-only storage | Notes not in Obsidian, DB intact |
| Research source unavailable | Flag claim as unverified | User knows to verify manually |
| Database locked | Retry with exponential backoff (3x) | Brief delay, then operation proceeds |

### Error Code Summary

| Range | Category | Example |
|-------|----------|---------|
| E001-E099 | Input Errors | E004: Invalid goal_id |
| E101-E199 | State Errors | E102: Goal count limit exceeded |
| E201-E299 | Calculation Errors | E203: Invalid performance |
| E301-E399 | Vault Errors | E302: Invalid topic_id |
| E501-E599 | System Errors | E601: Research contradiction detected |

---

**Document Version:** 1.0.0
**Last Updated:** 2026-09-01
**Related:** [FSRS-6 Algorithm](FSRS-6-ALGORITHM.md) | [Error Handling](ERROR-HANDLING.md)
