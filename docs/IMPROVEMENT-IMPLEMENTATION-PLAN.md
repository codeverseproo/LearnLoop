# MIT Learning Skill - Expert Panel Improvements Implementation

**Version:** 2.0.0
**Date:** 2026-09-03
**Status:** Ready for Implementation

---

## Executive Summary

Implementation of 7 expert panel improvements totaling approximately 15 schema changes, 10 new Python modules, and workflow modifications across 8 existing workflows.

**Improvements Implemented:**
1. ✅ Spaced Delivery Optimization (complexity + time detection)
2. ✅ Mastery Prediction Model (single-user behavioral signals)
3. ✅ Interleaved Topic Suggestion (plateau detection)
4. ✅ Collaborative Note Refinement (pre-generation structure)
5. ✅ Knowledge Decay Alerts (retrievability monitoring)
6. ✅ Multi-Modal Explanation Library (4 modes with detection)
7. ✅ Learning Outcome Analytics (time efficiency + retention scoring)

---

## Part 1: Database Schema Extensions

### 1.1 Topics Table Enhancements

```sql
-- Add to topics table in sqlite_init.py

-- Spaced Delivery: Complexity & Delivery Mode
ALTER TABLE topics ADD COLUMN complexity_score REAL DEFAULT 0.0;
ALTER TABLE topics ADD COLUMN delivery_mode TEXT DEFAULT 'hybrid';  -- streaming|batch|hybrid
ALTER TABLE topics ADD COLUMN estimated_duration_minutes INTEGER DEFAULT 30;

-- Mastery Prediction: Difficulty Classification Cache
-- Stored in separate table: topic_difficulty_classifications

-- Multi-Modal: Preferred Explanation Mode
ALTER TABLE topics ADD COLUMN preferred_mode TEXT;  -- visual|analytical|intuitive|kinesthetic|NULL
```

### 1.2 Sessions Table Enhancements

```sql
-- Add to sessions table in sqlite_init.py

-- Spaced Delivery: Time Context
ALTER TABLE sessions ADD COLUMN time_available_minutes INTEGER;
ALTER TABLE sessions ADD COLUMN session_duration_type TEXT;  -- quick|standard|deep

-- Learning Analytics: Timing & Performance
ALTER TABLE sessions ADD COLUMN duration_seconds INTEGER;
ALTER TABLE sessions ADD COLUMN mastery_before REAL;
ALTER TABLE sessions ADD COLUMN mastery_after REAL;

-- Collaborative Refinement: User Preferences
ALTER TABLE sessions ADD COLUMN preferences TEXT;  -- JSON blob

-- Learning Analytics: Breakthrough & Struggle Markers
ALTER TABLE sessions ADD COLUMN aha_moment INTEGER DEFAULT 0;  -- Boolean flag
ALTER TABLE sessions ADD COLUMN struggle_flags TEXT;  -- JSON array of struggle types
```

### 1.3 New Tables

```sql
-- ============================================
-- MASTERY PREDICTION TABLES
-- ============================================

-- Learning velocity history (for trend analysis)
CREATE TABLE IF NOT EXISTS velocity_snapshots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    snapshot_date DATE NOT NULL,
    mastery_per_session REAL,
    sessions_per_week REAL,
    avg_performance REAL,
    mastered_count INTEGER,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id),
    UNIQUE(goal_id, snapshot_date)
);

-- Topic difficulty classification cache
CREATE TABLE IF NOT EXISTS topic_difficulty_classifications (
    topic_id INTEGER PRIMARY KEY,
    classification TEXT NOT NULL,  -- easy/medium/hard
    effective_difficulty REAL,
    confidence REAL,
    classified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);

-- ============================================
-- LEARNING ANALYTICS TABLES
-- ============================================

-- Session-level events for granular tracking
CREATE TABLE IF NOT EXISTS session_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id INTEGER NOT NULL,
    event_type TEXT NOT NULL,  -- start|pause|resume|aha|struggle|complete
    event_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    event_data TEXT,  -- JSON blob
    FOREIGN KEY (session_id) REFERENCES sessions(id)
);

-- Aggregated time statistics per topic
CREATE TABLE IF NOT EXISTS topic_time_aggregates (
    topic_id INTEGER PRIMARY KEY,
    total_study_seconds INTEGER DEFAULT 0,
    session_count INTEGER DEFAULT 0,
    avg_session_seconds REAL,
    time_to_mastery_seconds INTEGER,  -- NULL until mastered
    mastery_achieved_at TIMESTAMP,
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);

-- Learning benchmarks for time efficiency calculation
CREATE TABLE IF NOT EXISTS learning_benchmarks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_domain TEXT NOT NULL,  -- e.g., 'programming', 'mathematics'
    difficulty_range TEXT NOT NULL,  -- e.g., '4-6'
    benchmark_sessions_to_mastery REAL,
    benchmark_hours_to_mastery REAL,
    sample_size INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(topic_domain, difficulty_range)
);

-- Retention check results
CREATE TABLE IF NOT EXISTS retention_checks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id INTEGER NOT NULL,
    check_date DATE NOT NULL,
    retrievability_at_check REAL,
    days_since_last_review INTEGER,
    retention_verified INTEGER,  -- Boolean: passed/failed
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);

-- ============================================
-- EXPLANATION MODE TABLES
-- ============================================

-- Mode usage history for detection algorithm
CREATE TABLE IF NOT EXISTS mode_usage_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id INTEGER NOT NULL,
    mode_used TEXT NOT NULL,  -- visual|analytical|intuitive|kinesthetic
    session_id INTEGER,
    effectiveness_rating REAL,  -- User rating 1-5 or performance score
    used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (topic_id) REFERENCES topics(id),
    FOREIGN KEY (session_id) REFERENCES sessions(id)
);

-- Mode effectiveness per user (aggregate)
CREATE TABLE IF NOT EXISTS mode_effectiveness (
    goal_id TEXT NOT NULL,
    mode TEXT NOT NULL,
    avg_performance REAL,
    usage_count INTEGER,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id),
    PRIMARY KEY (goal_id, mode)
);

-- ============================================
-- DECAY ALERT TABLES
-- ============================================

-- Decay risk scoring
CREATE TABLE IF NOT EXISTS decay_risk_scores (
    topic_id INTEGER PRIMARY KEY,
    risk_score REAL,  -- 0-1, higher = more urgent
    retrievability_current REAL,
    retrievability_projected_7d REAL,
    days_overdue INTEGER,
    last_calculated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);

-- Alert history
CREATE TABLE IF NOT EXISTS alert_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    alert_type TEXT NOT NULL,  -- decay|mastery_plateau|schedule_optimization
    topic_ids TEXT,  -- JSON array
    alert_message TEXT,
    triggered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    acknowledged INTEGER DEFAULT 0,
    acknowledged_at TIMESTAMP,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id)
);

-- ============================================
-- INTERLEAVING SUGGESTION TABLES
-- ============================================

-- Plateau detection history
CREATE TABLE IF NOT EXISTS plateau_detections (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id INTEGER NOT NULL,
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    performance_trend TEXT,  -- improving|stable|declining
    sessions_in_plateau INTEGER,
    suggested_action TEXT,
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);

-- Topic similarity graph (for interleaving suggestions)
CREATE TABLE IF NOT EXISTS topic_similarity (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id_a INTEGER NOT NULL,
    topic_id_b INTEGER NOT NULL,
    similarity_score REAL,  -- 0-1 based on prerequisite graph distance
    shared_prereqs_count INTEGER,
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (topic_id_a) REFERENCES topics(id),
    FOREIGN KEY (topic_id_b) REFERENCES topics(id),
    UNIQUE(topic_id_a, topic_id_b)
);
```

---

## Part 2: New Python Modules

### 2.1 Module Overview

| Module | Purpose | Lines (Est.) |
|--------|---------|--------------|
| `complexity_classifier.py` | Topic complexity scoring | ~100 |
| `time_detector.py` | Session time detection | ~150 |
| `delivery_adapter.py` | Content delivery mode selection | ~200 |
| `mastery_predictor.py` | Sessions/days to mastery prediction | ~400 |
| `difficulty_classifier.py` | Behavioral difficulty inference | ~250 |
| `learning_velocity.py` | Velocity trend calculation | ~300 |
| `explanation_mode_detector.py` | Multi-modal mode selection | ~200 |
| `decay_monitor.py` | Retrievability risk scoring | ~150 |
| `plateau_detector.py` | Learning plateau detection | ~180 |
| `learning_analytics.py` | Analytics calculations | ~300 |
| `time_aggregator.py` | Session time aggregation | ~150 |

**Total Estimated Lines:** ~2,380 lines across 11 modules

### 2.2 Key Module Signatures

```python
# scripts/complexity_classifier.py
class ComplexityClassifier:
    @classmethod
    def calculate_complexity(cls, factors: ComplexityFactors) -> float:
        """Returns 0-10 complexity score."""
    
    @classmethod
    def classify_delivery_mode(cls, complexity_score: float) -> str:
        """Returns 'streaming' | 'batch' | 'hybrid'."""

# scripts/time_detector.py
class TimeDetector:
    @classmethod
    def detect_time_available(
        cls,
        goal_id: str,
        explicit_time: Optional[int] = None,
        context_clues: Optional[dict] = None
    ) -> TimeContext:
        """Returns minutes_available, session_type, time_of_day."""

# scripts/mastery_predictor.py
class MasteryPredictor:
    @classmethod
    def predict_mastery(cls, conn: Connection, goal_id: str, topic_id: int) -> dict:
        """
        Returns:
        - current_mastery: float
        - sessions_remaining: int
        - estimated_days: int
        - confidence: float
        - prediction: str (human-readable)
        """

# scripts/difficulty_classifier.py
class TopicDifficultyClassifier:
    DIFFICULTY_SIGNALS = {
        'retention_rate': 0.35,
        'stability_growth_rate': 0.25,
        'time_to_first_success': 0.20,
        'relearning_events': 0.15,
        'performance_variance': 0.05
    }
    
    @classmethod
    def classify(cls, conn: Connection, topic_id: int) -> dict:
        """Returns classification, effective_difficulty, confidence."""

# scripts/explanation_mode_detector.py
class ExplanationModeDetector:
    MODE_CHARACTERISTICS = {
        'visual': ['diagrams', 'charts', 'spatial'],
        'analytical': ['formulas', 'step_by_step', 'logic'],
        'intuitive': ['analogies', 'examples', 'real_world'],
        'kinesthetic': ['exercises', 'practice', 'hands_on']
    }
    
    @classmethod
    def detect_preferred_mode(cls, conn: Connection, goal_id: str) -> str:
        """Returns detected mode or None."""

# scripts/decay_monitor.py
class DecayMonitor:
    DECAY_RISK_THRESHOLD = 0.7
    RETRIEVABILITY_WARNING_THRESHOLD = 0.85
    
    @classmethod
    def calculate_risk_scores(cls, conn: Connection, goal_id: str) -> List[dict]:
        """Returns topics sorted by decay risk."""

# scripts/plateau_detector.py
class PlateauDetector:
    PLATEAU_SESSION_THRESHOLD = 5
    PERFORMANCE_VARIANCE_THRESHOLD = 0.05
    
    @classmethod
    def detect_plateaus(cls, conn: Connection, goal_id: str) -> List[dict]:
        """Returns topics showing plateau patterns."""

# scripts/learning_analytics.py
class LearningAnalytics:
    @classmethod
    def calculate_time_efficiency(cls, conn: Connection, topic_id: int) -> float:
        """Returns efficiency score 0-1 (vs benchmark)."""
    
    @classmethod
    def calculate_retention_score(cls, conn: Connection, goal_id: str) -> float:
        """Returns 30-day retention percentage."""
    
    @classmethod
    def identify_struggle_patterns(cls, conn: Connection, goal_id: str) -> List[dict]:
        """Returns common struggle themes."""
```

---

## Part 3: Workflow Modifications

### 3.1 Modified Workflows Summary

| Workflow | Modifications |
|----------|--------------|
| `syllabus_generation` | Add Step 5a: Calculate topic complexity scores |
| `learning_session` | Add Step 0: Time detection; Step 2a: Delivery adaptation; Step 3a: Mode detection |
| `review_session` | Add Step 0: Time detection; Step 2a: Decay risk prioritization |
| `practice_session` | Add time-aware problem selection; struggle detection |
| `progress_dashboard` | Add analytics section: time efficiency, retention score, breakthroughs, struggles |
| `interleaved_practice` | Add Step 0: Plateau detection trigger; topic similarity scoring |

### 3.2 Detailed Workflow Changes

#### 3.2.1 syllabus_generation (Enhanced)

```markdown
#### 1. syllabus_generation (Enhanced)

| Aspect | Detail |
|--------|--------|
| **Triggers** | "I want to learn X", "Create a study plan for Y", "Syllabus for Z exam" |
| **Prerequisites** | Goal identified, timeline known (optional) |
| **Steps** | 1. Parse goal type (exam/skill/degree/topic) <br> 2. Identify topics from curriculum/body of knowledge <br> 3. Build prerequisite graph <br> 4. Estimate time per topic <br> **5a. Calculate complexity score per topic** (NEW) <br> **5b. Classify delivery mode per topic** (NEW) <br> 5. Create sequential learning path <br> 6. Initialize SQLite database <br> 7. Write syllabus to vault |
| **Outputs** | `memory.db` with topics table (includes complexity_score, delivery_mode), `00-Dashboard/Syllabus.md` in vault |
```

#### 3.2.2 learning_session (Enhanced)

```markdown
#### 4. learning_session (Enhanced)

| Aspect | Detail |
|--------|--------|
| **Triggers** | "Learn X", "Teach me Y", "I have N minutes to learn Z" (NEW) |
| **Prerequisites** | Topic exists in syllabus |
| **Steps** | **0. Detect time context** (NEW) - Parse explicit time or infer from context <br> 1. Load topic state (includes complexity_score, delivery_mode) <br> **2a. Adapt delivery** (NEW) - Select mode based on complexity + time <br> **2b. Detect explanation mode preference** (NEW) - Check history, infer from patterns <br> 3. Activate prior knowledge (related topics) <br> 4. Present concept with explanation (use preferred mode) <br> **4a. Present structure preview** (NEW) - Show outline, ask for preference emphasis <br> 5. Generate practice problems <br> 6. Assess understanding <br> **7a. Mark aha moments** (NEW) - Ask user if breakthrough occurred <br> **7b. Track struggle flags** (NEW) - Log hesitation patterns <br> 8. Update FSRS state <br> 9. Write/update vault note |
| **Outputs** | Updated `fsrs_state`, `sessions` with time_available_minutes, duration_seconds, aha_moment, struggle_flags; `session_events` log |
```

#### 3.2.3 review_session (Enhanced)

```markdown
#### 7. review_session (Enhanced)

| Aspect | Detail |
|--------|--------|
| **Triggers** | "Review", "I have N minutes for review", "What's due" |
| **Prerequisites** | Overdue topics exist |
| **Steps** | **0. Detect time** (NEW) - Get available minutes <br> 1. Query topics WHERE next_review <= today <br> **1a. Calculate decay risk scores** (NEW) - Prioritize by retrievability <br> 2. Calculate priority (retrievability - 0.9, adjusted by decay risk) <br> 3. Sort by priority (lowest = most urgent) <br> **3a. Adjust review count for time** (NEW) - Quick session = fewer items <br> 4. Present topic for review <br> 5. Collect performance rating <br> 6. Update FSRS state via scheduler <br> 7. Schedule next review |
| **Outputs** | Updated `fsrs_state`, `topics.next_review`, session record, `decay_risk_scores` |
```

#### 3.2.4 progress_dashboard (Enhanced)

```markdown
#### 11. progress_dashboard (Enhanced)

| Aspect | Detail |
|--------|--------|
| **Triggers** | "How am I doing", "Show progress", "Dashboard", "Analytics" (NEW) |
| **Prerequisites** | Active goal |
| **Steps** | 1. Query goal_meta for totals <br> 2. Count mastered/in_progress/pending <br> 3. Load streak_state <br> 4. Calculate percentages <br> **5. Calculate learning analytics** (NEW) <br> **5a. Time efficiency score** <br> **5b. 30-day retention score** <br> **5c. Breakthrough moments count** <br> **5d. Struggle pattern summary** <br> **5e. Mastery predictions for in-progress topics** <br> 6. Generate visual progress bar <br> 7. Write/update dashboard |
| **Outputs** | `00-Dashboard/Progress.md` with analytics section |
```

---

## Part 4: Collaborative Note Refinement Design

### 4.1 Pre-Generation Structure Preview

**Integration Point:** learning_session workflow, Step 4a (after presenting concept outline, before full explanation).

**Implementation:**

```python
# In learning_session workflow

def present_structure_preview(topic: Topic) -> dict:
    """
    Show structure preview before full generation.
    
    Returns user preferences for note emphasis.
    """
    structure = {
        "title": topic.name,
        "sections": [
            "Core Concepts",
            "Key Definitions",
            "Examples & Applications",
            "Common Pitfalls",
            "Practice Problems",
            "Connections to Related Topics"
        ],
        "estimated_length": "800-1200 words"
    }
    
    # Present preview
    print(f"\n📋 Structure Preview for '{topic.name}':\n")
    for i, section in enumerate(structure["sections"], 1):
        print(f"  {i}. {section}")
    print(f"\n  Estimated: {structure['estimated_length']}\n")
    
    # Collect preferences
    return collect_preferences(structure)

def collect_preferences(structure: dict) -> dict:
    """
    Interactive questionnaire for note customization.
    
    Timeout: 30 seconds (defaults to balanced).
    """
    print("🎯 Customize your learning note (30s timeout, press Enter for defaults):\n")
    
    questions = [
        {
            "q": "Which sections to emphasize more? (comma numbers, e.g., '2,4' or 'all')",
            "field": "emphasize_sections",
            "default": "all"
        },
        {
            "q": "Explanation style? (visual/analytical/intuitive/kinesthetic)",
            "field": "explanation_mode",
            "default": "intuitive"
        },
        {
            "q": "Depth level? (overview/standard/deep)",
            "field": "depth",
            "default": "standard"
        },
        {
            "q": "Include more practice problems? (yes/no)",
            "field": "extra_practice",
            "default": "no"
        }
    ]
    
    preferences = {}
    for q in questions:
        try:
            answer = input_timeout(q["q"] + " ", timeout=30)
            preferences[q["field"]] = parse_answer(answer, q["default"])
        except TimeoutError:
            preferences[q["field"]] = q["default"]
    
    return preferences

# Store in sessions table
# ALTER TABLE sessions ADD COLUMN preferences TEXT;  -- JSON blob
```

### 4.2 Preference Storage

```json
{
  "emphasize_sections": [2, 4],
  "explanation_mode": "visual",
  "depth": "standard",
  "extra_practice": false,
  "timestamp": "2026-09-03T03:00:00Z"
}
```

---

## Part 5: Learning Analytics Formulas

### 5.1 Time Efficiency

```python
def calculate_time_efficiency(conn: Connection, topic_id: int) -> float:
    """
    Calculate efficiency vs benchmark.
    
    Formula:
        efficiency = 1 - (actual_time / benchmark_time)
        
    Interpretation:
        +0.40 = 40% faster than average
        -0.20 = 20% slower than average
        0.00 = exactly average
    """
    # Get actual time from topic_time_aggregates
    actual_time = get_time_to_mastery(conn, topic_id)
    
    # Get benchmark from learning_benchmarks
    topic = get_topic(conn, topic_id)
    benchmark_time = get_benchmark_time(
        domain=topic.domain,
        difficulty_range=f"{topic.difficulty:.0f}-{topic.difficulty:.0f}"
    )
    
    if not benchmark_time or benchmark_time == 0:
        return 0.0  # No benchmark available
    
    efficiency = 1 - (actual_time / benchmark_time)
    return max(-1.0, min(1.0, efficiency))  # Clamp to [-1, 1]
```

### 5.2 Retention Score

```python
def calculate_retention_score(conn: Connection, goal_id: str) -> float:
    """
    Calculate 30-day retention percentage.
    
    Formula:
        retention = (retained_topics / tested_topics) * 100
        
    Where:
        retained_topics = topics with retrieval R > 0.9 after 30 days
        tested_topics = topics reviewed at least once 30+ days ago
    """
    cursor = conn.cursor()
    
    # Get topics reviewed 30+ days ago
    cursor.execute("""
        SELECT DISTINCT t.id, f.stability, f.last_review
        FROM topics t
        JOIN fsrs_state f ON t.id = f.topic_id
        WHERE f.last_review <= date('now', '-30 days')
          AND f.reviews >= 1
    """)
    
    tested_topics = cursor.fetchall()
    
    if not tested_topics:
        return 100.0  # No topics old enough to test
    
    retained_count = 0
    for topic_id, stability, last_review in tested_topics:
        # Calculate retrievability at day 30
        days_since = (datetime.now() - datetime.fromisoformat(last_review)).days
        retrievability = (1 + days_since / (9 * stability)) ** -1
        
        if retrievability >= 0.9:
            retained_count += 1
    
    retention_pct = (retained_count / len(tested_topics)) * 100
    return retention_pct
```

### 5.3 Breakthrough Moments

```python
def identify_breakthroughs(conn: Connection, goal_id: str) -> dict:
    """
    Identify 'aha moment' sessions.
    
    Criteria:
        - User marked 'aha_moment = 1'
        - OR performance jumped > 0.3 in single session
        - OR mastery increased > 0.2 in single session
    """
    cursor = conn.cursor()
    
    # Get explicit aha moments
    cursor.execute("""
        SELECT s.id, s.topic_id, s.started_at, t.name
        FROM sessions s
        JOIN topics t ON s.topic_id = t.id
        WHERE s.aha_moment = 1
        ORDER BY s.started_at DESC
        LIMIT 10
    """)
    
    explicit_ahas = cursor.fetchall()
    
    # Get implicit ahas (large performance jumps)
    cursor.execute("""
        SELECT s1.topic_id, s1.started_at,
               s2.performance - s1.performance as perf_delta,
               t.name
        FROM sessions s1
        JOIN sessions s2 ON s1.topic_id = s2.topic_id
                          AND s2.started_at > s1.started_at
        JOIN topics t ON s1.topic_id = t.id
        WHERE s2.performance - s1.performance > 0.3
        ORDER BY perf_delta DESC
        LIMIT 10
    """)
    
    implicit_ahas = cursor.fetchall()
    
    return {
        "explicit_count": len(explicit_ahas),
        "implicit_count": len(implicit_ahas),
        "total_breakthroughs": len(explicit_ahas) + len(implicit_ahas),
        "recent_breakthroughs": explicit_ahas[:3] if explicit_ahas else []
    }
```

### 5.4 Struggle Patterns

```python
def identify_struggle_patterns(conn: Connection, goal_id: str) -> List[dict]:
    """
    Identify common struggle patterns.
    
    Indicators:
        - Performance < 0.6 (failure threshold)
        - Stability < 3.0 days (rapid forgetting)
        - Multiple relearning events (fsrs_state.state = 3)
        -hints_used > 0 (if tracked)
        - struggle_flags not NULL
    """
    cursor = conn.cursor()
    
    # Get struggling topics
    cursor.execute("""
        SELECT t.id, t.name, t.mastery,
               f.stability, f.difficulty, f.state, f.reviews,
               COUNT(DISTINCT s.id) as session_count,
               AVG(s.performance) as avg_performance
        FROM topics t
        JOIN fsrs_state f ON t.id = f.topic_id
        LEFT JOIN sessions s ON t.id = s.topic_id
        WHERE f.stability < 3.0
           OR f.state = 3
           OR AVG(s.performance) < 0.6
        GROUP BY t.id
        HAVING session_count >= 3
        ORDER BY avg_performance ASC
    """)
    
    struggling = cursor.fetchall()
    
    # Classify struggle types
    patterns = []
    for row in struggling:
        topic_id, name, mastery, stability, difficulty, state, reviews, sessions, avg_perf = row
        
        struggle_type = classify_struggle_type(
            stability=stability,
            difficulty=difficulty,
            avg_performance=avg_perf,
            state=state
        )
        
        patterns.append({
            "topic": name,
            "struggle_type": struggle_type,
            "avg_performance": avg_perf,
            "sessions": sessions,
            "recommendation": get_struggle_recommendation(struggle_type)
        })
    
    return patterns

def classify_struggle_type(stability, difficulty, avg_performance, state):
    """Classify the type of struggle."""
    if stability < 2.0:
        return "rapid_forgetting"
    elif difficulty > 7.0:
        return "high_intrinsic_difficulty"
    elif state == 3:
        return "relearning_cycle"
    elif avg_performance < 0.4:
        return "concept_mismatch"
    else:
        return "inconsistent_performance"
```

---

## Part 6: Multi-Modal Explanation Modes

### 6.1 Mode Definitions

| Mode | Characteristics | Best For |
|------|-----------------|----------|
| **Visual** | Diagrams, charts, spatial relationships, mind maps | Spatial concepts, architecture, relationships |
| **Analytical** | Formulas, step-by-step logic, proofs, derivations | Math, algorithms, formal logic |
| **Intuitive** | Analogies, examples, real-world connections, stories | Abstract concepts, bridging knowledge |
| **Kinesthetic** | Exercises, practice problems, hands-on activities | Skills, procedures, muscle memory |

### 6.2 Mode Detection Algorithm

```python
class ExplanationModeDetector:
    """
    Detect preferred explanation mode from user behavior.
    
    Signals (weights):
        - Explicit preference (topic.preferred_mode): 1.0
        - Mode effectiveness history: 0.5
        - Topic type heuristics: 0.3
        - Session time available: 0.2
    """
    
    @classmethod
    def detect_preferred_mode(cls, conn: Connection, goal_id: str, topic_id: int = None) -> str:
        """Returns detected mode or defaults to 'intuitive'."""
        
        # 1. Check explicit preference
        if topic_id:
            topic = get_topic(conn, topic_id)
            if topic.preferred_mode:
                return topic.preferred_mode
        
        # 2. Check mode effectiveness history
        effectiveness = cls.get_mode_effectiveness(conn, goal_id)
        if effectiveness:
            best_mode = max(effectiveness, key=lambda m: effectiveness[m]['avg_performance'])
            if effectiveness[best_mode]['avg_performance'] > 0.7:
                return best_mode
        
        # 3. Topic type heuristics
        if topic_id:
            topic_type = classify_topic_type(conn, topic_id)
            type_mode_map = {
                'programming': 'kinesthetic',  # Hands-on practice
                'mathematics': 'analytical',    # Formulas
                'architecture': 'visual',      # Diagrams
                'history': 'intuitive'          # Stories, examples
            }
            if topic_type in type_mode_map:
                return type_mode_map[topic_type]
        
        # 4. Default
        return 'intuitive'
    
    @classmethod
    def get_mode_effectiveness(cls, conn: Connection, goal_id: str) -> dict:
        """Calculate effectiveness per mode from history."""
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT mode, AVG(effectiveness_rating) as avg_perf, COUNT(*) as uses
            FROM mode_effectiveness
            WHERE goal_id = ?
            GROUP BY mode
        """, (goal_id,))
        
        return {row[0]: {'avg_performance': row[1], 'usage_count': row[2]} 
                for row in cursor.fetchall()}
```

### 6.3 Explanation Generation Prompts

```markdown
## Visual Mode Prompt Template

Generate explanation using visual representations:
- Use ASCII diagrams where helpful
- Describe spatial relationships
- Include flowcharts for processes
- Use tables for comparisons
- Mention "imagine X as Y" analogies with spatial elements

## Analytical Mode Prompt Template

Generate explanation with analytical rigor:
- Start with definitions
- Present step-by-step derivations
- Include formulas with explanations
- Use numbered steps
- Show logical progression
- Highlight assumptions and constraints

## Intuitive Mode Prompt Template

Generate explanation for intuitive understanding:
- Start with a relatable analogy
- Use real-world examples
- Tell a story or narrative
- Connect to familiar concepts
- Use "think of it like..." phrasing
- Focus on "why" before "how"

## Kinesthetic Mode Prompt Template

Generate explanation with practice focus:
- Start with a quick exercise
- "Try this:" prompts
- Build from simple to complex
- Include practice checkpoints
- Suggest hands-on activities
- Use "do X, observe Y" patterns
```

---

## Part 7: Knowledge Decay Alerts

### 7.1 Decay Risk Formula

```python
class DecayMonitor:
    """
    Monitor knowledge decay risk from FSRS data.
    
    Risk Score Components:
        - Retrievability below threshold: 40%
        - Days overdue: 30%
        - Stability trend: 20%
        - Difficulty: 10%
    """
    
    RETRIEVABILITY_THRESHOLD = 0.9
    WARNING_THRESHOLD = 0.85
    
    @classmethod
    def calculate_risk_scores(cls, conn: Connection, goal_id: str) -> List[dict]:
        """Calculate decay risk for all topics."""
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT t.id, t.name, t.next_review,
                   f.stability, f.difficulty, f.last_review, f.state
            FROM topics t
            JOIN fsrs_state f ON t.id = f.topic_id
            WHERE t.status = 'in_progress' OR t.status = 'mastered'
        """)
        
        topics = cursor.fetchall()
        risk_scores = []
        
        for topic_id, name, next_review, stability, difficulty, last_review, state in topics:
            # Calculate retrievability
            days_since = (datetime.now() - datetime.fromisoformat(last_review)).days
            retrievability = (1 + days_since / (9 * stability)) ** -1
            
            # Calculate days overdue
            if next_review:
                next_review_dt = datetime.fromisoformat(next_review)
                days_overdue = max(0, (datetime.now() - next_review_dt).days)
            else:
                days_overdue = 0
            
            # Project retrievability in 7 days
            retrievability_7d = (1 + (days_since + 7) / (9 * stability)) ** -1
            
            # Calculate risk score
            risk_score = cls.calculate_risk_score(
                retrievability=retrievability,
                days_overdue=days_overdue,
                stability=stability,
                difficulty=difficulty
            )
            
            risk_scores.append({
                "topic_id": topic_id,
                "topic_name": name,
                "risk_score": risk_score,
                "retrievability_current": retrievability,
                "retrievability_projected_7d": retrievability_7d,
                "days_overdue": days_overdue,
                "stability": stability,
                "urgency": "high" if risk_score > 0.7 else "medium" if risk_score > 0.4 else "low"
            })
        
        return sorted(risk_scores, key=lambda x: x["risk_score"], reverse=True)
    
    @staticmethod
    def calculate_risk_score(retrievability, days_overdue, stability, difficulty) -> float:
        """
        Calculate composite decay risk score.
        
        Higher score = more urgent review needed.
        """
        # Retrievability component (inverse, lower R = higher risk)
        r_score = (1 - retrievability) * 0.4
        
        # Overdue component
        overdue_score = min(1.0, days_overdue / 30) * 0.3
        
        # Stability component (inverse, lower S = higher risk)
        s_score = min(1.0, (30 - stability) / 30) * 0.2
        
        # Difficulty component
        d_score = (difficulty / 10) * 0.1
        
        return r_score + overdue_score + s_score + d_score
```

### 7.2 Calendar Integration Options

**Option A: SQLite-Only Notifications**
- Store alert_preferences table
- Check on skill invocation
- Display in progress_dashboard
- No external calendar dependency

**Option B: .ics File Export**
- Generate .ics files for review sessions
- User imports to preferred calendar
- Manual sync required
- Platform-agnostic

**Option C: CalDAV/CardDAV Integration**
- Direct calendar server integration
- Real-time updates
- Requires CalDAV server (Nextcloud, Google, iCloud)
- More complex setup

**Recommendation:** Option A for MVP + Option B for power users.

```sql
-- Calendar integration preferences
CREATE TABLE IF NOT EXISTS calendar_preferences (
    goal_id TEXT PRIMARY KEY,
    notification_enabled INTEGER DEFAULT 1,
    notification_advance_days INTEGER DEFAULT 1,
    preferred_time TEXT DEFAULT '09:00',
    calendar_export_format TEXT DEFAULT 'ics',  -- ics|none
    last_export_at TIMESTAMP,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id)
);
```

---

## Part 8: Interleaved Topic Suggestion

### 8.1 Plateau Detection

```python
class PlateauDetector:
    """
    Detect learning plateaus from session history.
    
    Plateau Criteria:
        - Performance variance < 0.05 over last 5 sessions
        - No mastery improvement > 0.05 in 5 sessions
        - Performance trend = 'stable' or 'declining'
    """
    
    PLATEAU_SESSION_THRESHOLD = 5
    PERFORMANCE_VARIANCE_THRESHOLD = 0.05
    
    @classmethod
    def detect_plateaus(cls, conn: Connection, goal_id: str) -> List[dict]:
        """Detect topics showing plateau patterns."""
        cursor = conn.cursor()
        
        # Get in-progress topics with 5+ sessions
        cursor.execute("""
            SELECT t.id, t.name, t.mastery
            FROM topics t
            WHERE t.status = 'in_progress'
        """)
        
        topics = cursor.fetchall()
        plateaus = []
        
        for topic_id, name, current_mastery in topics:
            # Get last 5 sessions
            cursor.execute("""
                SELECT performance, mastery_before, mastery_after, started_at
                FROM sessions
                WHERE topic_id = ?
                ORDER BY started_at DESC
                LIMIT 5
            """, (topic_id,))
            
            sessions = cursor.fetchall()
            
            if len(sessions) < cls.PLATEAU_SESSION_THRESHOLD:
                continue  # Not enough data
            
            performances = [s[0] for s in sessions]
            mastery_gains = [s[2] - s[1] for s in sessions if s[1] and s[2]]
            
            # Check variance
            variance = cls.calculate_variance(performances)
            
            # Check mastery trend
            total_gain = sum(mastery_gains) if mastery_gains else 0
            
            if variance < cls.PERFORMANCE_VARIANCE_THRESHOLD and total_gain < 0.05:
                # Calculate trend
                trend = cls.calculate_trend(performances)
                
                plateaus.append({
                    "topic_id": topic_id,
                    "topic_name": name,
                    "current_mastery": current_mastery,
                    "sessions_in_plateau": len(sessions),
                    "performance_variance": variance,
                    "mastery_gain": total_gain,
                    "trend": trend,
                    "suggestion": cls.generate_suggestion(trend)
                })
        
        return plateaus
    
    @staticmethod
    def generate_suggestion(trend: str) -> str:
        """Generate interleaving suggestion."""
        if trend == 'declining':
            return "Consider mixing with an easier related topic to rebuild confidence."
        else:  # stable
            return "Try interleaving with a related topic to break through the plateau."
```

### 8.2 Topic Similarity Scoring

```python
def calculate_topic_similarity(conn: Connection) -> None:
    """
    Calculate similarity scores based on prerequisite graph.
    
    Similarity = weighted combination of:
        - Shared prerequisites (direct)
        - Prerequisite graph distance (BFS)
        - Same domain classification
    """
    cursor = conn.cursor()
    
    # Get all topic pairs with shared prerequisites
    cursor.execute("""
        SELECT p1.topic_id as topic_a, p2.topic_id as topic_b,
               COUNT(*) as shared_count
        FROM prerequisites p1
        JOIN prerequisites p2 ON p1.prerequisite_id = p2.prerequisite_id
                               AND p1.topic_id < p2.topic_id
        GROUP BY p1.topic_id, p2.topic_id
    """)
    
    shared_prereqs = cursor.fetchall()
    
    similarities = []
    
    for topic_a, topic_b, shared_count in shared_prereqs:
        # Normalize by total prerequisites of both topics
        total_a = get_prereq_count(conn, topic_a)
        total_b = get_prereq_count(conn, topic_b)
        
        similarity = (2 * shared_count) / (total_a + total_b) if (total_a + total_b) > 0 else 0
        
        similarities.append((topic_a, topic_b, similarity, shared_count))
    
    # Clear old similarities
    cursor.execute("DELETE FROM topic_similarity")
    
    # Insert new similarities
    cursor.executemany("""
        INSERT INTO topic_similarity (topic_id_a, topic_id_b, similarity_score, shared_prereqs_count)
        VALUES (?, ?, ?, ?)
    """, similarities)
    
    conn.commit()
```

---

## Part 9: Implementation Order

### Phase 1: Database Schema (Priority: High)
1. Add columns to `topics` table
2. Add columns to `sessions` table
3. Create new tables (11 tables)
4. Test schema migrations

### Phase 2: Core Modules (Priority: High)
5. Implement `complexity_classifier.py`
6. Implement `time_detector.py`
7. Implement `delivery_adapter.py`
8. Implement `difficulty_classifier.py`
9. Implement `learning_velocity.py`
10. Implement `mastery_predictor.py`

### Phase 3: Analytics Modules (Priority: Medium)
11. Implement `decay_monitor.py`
12. Implement `plateau_detector.py`
13. Implement `learning_analytics.py`
14. Implement `time_aggregator.py`
15. Implement `explanation_mode_detector.py`

### Phase 4: Workflow Integration (Priority: High)
16. Modify `syllabus_generation` workflow
17. Modify `learning_session` workflow
18. Modify `review_session` workflow
19. Modify `progress_dashboard` workflow
20. Modify `interleaved_practice` workflow

### Phase 5: Documentation (Priority: Medium)
21. Update SKILL.md with all enhancements
22. Create prompts for each micro-step
23. Document new triggers
24. Update error codes if needed

---

## Part 10: Estimated Effort

| Component | Effort (Days) | Priority |
|-----------|---------------|----------|
| Database schema changes | 1 | High |
| Core modules (10 modules) | 5 | High |
| Analytics modules (5 modules) | 3 | Medium |
| Workflow modifications (5 workflows) | 3 | High |
| Testing & validation | 2 | High |
| Documentation & prompts | 2 | Medium |
| **Total** | **16 days** | - |

---

## Appendix A: Modified Natural Language Triggers

### Time-Aware Triggers (NEW - 8 triggers)

| Trigger | Workflow |
|---------|-----------|
| "I have N minutes to learn X" | learning_session (time detection) |
| "Quick review" | review_session (quick mode) |
| "Weekend deep dive" | learning_session (deep mode) |
| "During commute" | review_session (quick mode) |
| "Before [event]" | learning_session (time inference) |
| "Lunch break session" | learning_session (standard mode) |
| "Fast session" | review_session (quick mode) |
| "I have all afternoon" | learning_session (deep mode) |

### Analytics Triggers (NEW - 5 triggers)

| Trigger | Workflow |
|---------|-----------|
| "Show my analytics" | progress_dashboard |
| "How efficient am I" | progress_dashboard (time efficiency) |
| "What's my retention score" | progress_dashboard (retention) |
| "Where am I struggling" | progress_dashboard (struggle patterns) |
| "My breakthroughs this week" | progress_dashboard (aha moments) |

### Prediction Triggers (NEW - 4 triggers)

| Trigger | Workflow |
|---------|-----------|
| "When will I master X" | progress_dashboard (mastery prediction) |
| "How many sessions left" | progress_dashboard (mastery prediction) |
| "Predict my progress" | progress_dashboard (mastery predictions) |
| "Am I on track" | progress_dashboard (velocity trend) |

---

## Appendix B: Error Codes (No New Codes Required)

All new functionality uses existing error codes. No modifications to error code registry needed.

---

**Document End**
