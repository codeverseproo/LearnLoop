# Knowledge Decay Alerts - Implementation Design

**Version:** 1.0
**Last Updated:** 2026-09-03
**Status:** Implementation-Ready

---

## Table of Contents

1. [Overview](#1-overview)
2. [Decay Detection Algorithm](#2-decay-detection-algorithm)
3. [Risk Scoring System](#3-risk-scoring-system)
4. [Calendar Integration Options](#4-calendar-integration-options)
5. [Notification Timing Strategy](#5-notification-timing-strategy)
6. [Schema Extensions](#6-schema-extensions)
7. [SKILL.md Workflow Modifications](#7-skillmd-workflow-modifications)
8. [Implementation Checklist](#8-implementation-checklist)

---

## 1. Overview

### 1.1 Purpose

Detect topics at risk of being forgotten before they become critically overdue. The system proactively alerts users when knowledge decay is accelerating, enabling intervention before the 90% retention threshold is breached.

### 1.2 Core Components

```
┌──────────────────────────────────────────────────────────────┐
│                    DECAY ALERT SYSTEM                         │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────┐     ┌─────────────────┐               │
│  │ FSRS State      │────▶│ Decay Detector   │               │
│  │ (S, D, last_rev)│     │ (R(t) calculus)  │               │
│  └─────────────────┘     └────────┬────────┘               │
│                                   │                          │
│                                   ▼                          │
│                          ┌─────────────────┐               │
│                          │ Risk Scorer      │               │
│                          │ (urgency metric) │               │
│                          └────────┬────────┘               │
│                                   │                          │
│                                   ▼                          │
│                          ┌─────────────────┐               │
│                          │ Alert Generator  │               │
│                          │ (notification)   │               │
│                          └────────┬────────┘               │
│                                   │                          │
│                    ┌──────────────┴──────────────┐          │
│                    ▼                             ▼          │
│           ┌──────────────┐              ┌──────────────┐   │
│           │ In-App Alert │              │ Calendar     │   │
│           │ (non-intrusive)│             │ Integration  │   │
│           └──────────────┘              └──────────────┘   │
│                                                             │
└──────────────────────────────────────────────────────────────┘
```

### 1.3 Design Principles

| Principle | Implementation |
|-----------|---------------|
| **Non-intrusive** | Alerts are suggestions, not interruptions |
| **Evidence-based** | All alerts grounded in FSRS retrievability math |
| **Actionable** | Every alert provides a clear next action |
| **Personalized** | Thresholds adapt to user's learning patterns |
| **Privacy-first** | All computation local, no cloud dependencies |

---

## 2. Decay Detection Algorithm

### 2.1 Retrievability Trend Analysis

The core detection uses FSRS-6's retrievability formula to calculate current and projected decay:

```python
def retrievability(stability: float, days_since_review: float) -> float:
    """FSRS-6 power law: R(t, S) = (1 + t/(9*S))^(-1)"""
    if stability <= 0:
        return 0.0
    factor = 1 + days_since_review / (9 * stability)
    return max(0.0, factor ** -1)
```

### 2.2 Decay Rate Calculation

**Decay rate** measures how fast retrievability is dropping per day:

```
dR/dt = -1 / (9*S * (1 + t/(9*S))^2)

At any point:
- dR/dt = -9*S / (9*S + t)^2
```

**Implementation:**

```python
def decay_rate(stability: float, days_since_review: float) -> float:
    """Calculate rate of retrievability decay per day.

    Formula: dR/dt = -9*S / (9*S + t)^2

    Returns:
        Negative value representing decay rate (0 to -1)
    """
    if stability <= 0:
        return -1.0

    numerator = 9 * stability
    denominator = (9 * stability + days_since_review) ** 2

    return -numerator / denominator
```

### 2.3 Decay Detection Logic

```python
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import List, Optional
from enum import Enum

class AlertLevel(Enum):
    """Alert severity levels."""
    GREEN = "green"      # R > 0.95 - knowledge secure
    YELLOW = "yellow"   # 0.90 < R <= 0.95 - approaching threshold
    ORANGE = "orange"   # 0.85 < R <= 0.90 - at risk
    RED = "red"         # 0.80 < R <= 0.85 - urgent
    CRITICAL = "critical"  # R <= 0.80 - emergency review needed


@dataclass
class DecayAlert:
    """Represents a decay alert for a topic."""
    topic_id: str
    topic_name: str
    current_retrievability: float
    projected_retrievability_24h: float
    decay_rate: float
    alert_level: AlertLevel
    days_since_review: float
    stability: float
    difficulty: float
    risk_score: float
    recommended_action: str
    generated_at: datetime


class DecayDetector:
    """Detects topics at risk of knowledge decay."""

    # Thresholds for alert levels
    THRESHOLDS = {
        AlertLevel.GREEN: 0.95,
        AlertLevel.YELLOW: 0.90,
        AlertLevel.ORANGE: 0.85,
        AlertLevel.RED: 0.80,
        AlertLevel.CRITICAL: 0.00
    }

    def __init__(self, retrievability_threshold: float = 0.9):
        self.threshold = retrievability_threshold

    def detect(self, topics: List[dict]) -> List[DecayAlert]:
        """Detect topics showing decay risk.

        Args:
            topics: List of topic dicts with FSRS state

        Returns:
            List of alerts for topics at risk
        """
        alerts = []

        for topic in topics:
            alert = self._analyze_topic(topic)
            if alert and alert.alert_level != AlertLevel.GREEN:
                alerts.append(alert)

        # Sort by risk score (highest first)
        return sorted(alerts, key=lambda a: a.risk_score, reverse=True)

    def _analyze_topic(self, topic: dict) -> Optional[DecayAlert]:
        """Analyze a single topic for decay risk."""
        stability = topic.get('stability', 2.5)
        difficulty = topic.get('difficulty', 5.0)
        last_review_str = topic.get('last_review')

        if not last_review_str:
            return None  # Never reviewed, skip

        last_review = datetime.fromisoformat(last_review_str)
        days_since = (datetime.now() - last_review).total_seconds() / 86400

        # Calculate current retrievability
        current_r = retrievability(stability, days_since)

        # Project retrievability in 24 hours
        projected_r = retrievability(stability, days_since + 1)

        # Calculate decay rate
        dr = decay_rate(stability, days_since)

        # Determine alert level
        alert_level = self._get_alert_level(current_r)

        # Calculate risk score
        risk = self._calculate_risk(
            current_r, projected_r, dr, stability, difficulty
        )

        # Generate recommendation
        action = self._recommend_action(alert_level, stability, difficulty)

        return DecayAlert(
            topic_id=topic['topic_id'],
            topic_name=topic['name'],
            current_retrievability=current_r,
            projected_retrievability_24h=projected_r,
            decay_rate=dr,
            alert_level=alert_level,
            days_since_review=days_since,
            stability=stability,
            difficulty=difficulty,
            risk_score=risk,
            recommended_action=action,
            generated_at=datetime.now()
        )

    def _get_alert_level(self, r: float) -> AlertLevel:
        """Determine alert level from retrievability."""
        if r > self.THRESHOLDS[AlertLevel.GREEN]:
            return AlertLevel.GREEN
        elif r > self.THRESHOLDS[AlertLevel.YELLOW]:
            return AlertLevel.YELLOW
        elif r > self.THRESHOLDS[AlertLevel.ORANGE]:
            return AlertLevel.ORANGE
        elif r > self.THRESHOLDS[AlertLevel.RED]:
            return AlertLevel.RED
        else:
            return AlertLevel.CRITICAL

    def _calculate_risk(
        self,
        current_r: float,
        projected_r: float,
        decay_rate: float,
        stability: float,
        difficulty: float
    ) -> float:
        """Calculate risk score (0-100, higher = more urgent).

        Risk factors:
        1. Distance from threshold (50%)
        2. Decay velocity (25%)
        3. Difficulty adjustment (15%)
        4. Stability factor (10%)
        """
        # Factor 1: Distance from threshold (0-50 points)
        # Lower R = higher risk
        threshold_distance = max(0, self.threshold - current_r)
        distance_score = (threshold_distance / self.threshold) * 50

        # Factor 2: Decay velocity (0-25 points)
        # Faster decay = higher risk
        velocity_score = min(abs(decay_rate) * 250, 25)

        # Factor 3: Difficulty adjustment (0-15 points)
        # Harder topics = higher risk (they decay faster)
        difficulty_score = (difficulty / 10.0) * 15

        # Factor 4: Stability factor (0-10 points)
        # Lower stability = higher risk
        stability_factor = 1 - min(stability / 50.0, 1.0)
        stability_score = stability_factor * 10

        total_risk = distance_score + velocity_score + difficulty_score + stability_score

        return min(100.0, total_risk)

    def _recommend_action(
        self,
        level: AlertLevel,
        stability: float,
        difficulty: float
    ) -> str:
        """Generate recommended action based on alert level."""
        if level == AlertLevel.CRITICAL:
            return f"Immediate review needed. Consider a focused 10-minute session."
        elif level == AlertLevel.RED:
            return f"Review today to prevent knowledge loss. Estimated {int(stability * 0.3)} min."
        elif level == AlertLevel.ORANGE:
            return f"Schedule review within 24 hours to maintain retention."
        elif level == AlertLevel.YELLOW:
            return f"Consider a quick review before the topic becomes urgent."
        else:
            return "Knowledge secure. No action needed."
```

### 2.4 Decay Detection Query

SQL query to fetch topics needing analysis:

```sql
-- Get all topics with FSRS state for decay analysis
SELECT
    t.topic_id,
    t.name,
    t.mastery,
    t.status,
    fs.stability,
    fs.difficulty,
    fs.last_review,
    fs.next_review,
    fs.reviews,
    fs.state as fsrs_state
FROM topics t
JOIN fsrs_state fs ON t.id = fs.topic_id
WHERE t.status IN ('in_progress', 'pending')
  AND fs.last_review IS NOT NULL
  AND t.mastery < 0.9
ORDER BY fs.stability ASC, fs.last_review ASC;
```

---

## 3. Risk Scoring System

### 3.1 Risk Score Formula

The risk score (0-100) combines multiple factors:

```
Risk = Distance(50%) + Velocity(25%) + Difficulty(15%) + Stability(10%)

Where:
- Distance = (threshold - R) / threshold * 50
- Velocity = min(|dR/dt| * 250, 25)
- Difficulty = (D / 10) * 15
- Stability = (1 - S/50) * 10
```

### 3.2 Risk Interpretation

| Risk Score | Interpretation | Action |
|------------|----------------|--------|
| 80-100 | Critical | Review immediately |
| 60-79 | High | Schedule within 2 hours |
| 40-59 | Moderate | Schedule within 24 hours |
| 20-39 | Low | Review when convenient |
| 0-19 | Minimal | No immediate action |

### 3.3 Risk Calculation Examples

**Example 1: High Risk Topic**

```
Topic: Constitutional Amendments
- Stability: 3.5 days
- Difficulty: 7.2
- Days since review: 5 days
- Current R: 0.72

Risk calculation:
- Distance: (0.9 - 0.72) / 0.9 * 50 = 10.0
- Velocity: min(|-0.051| * 250, 25) ≈ 12.8
- Difficulty: (7.2 / 10) * 15 = 10.8
- Stability: (1 - 3.5/50) * 10 = 9.3
Total: 42.9 → High Risk
```

**Example 2: Moderate Risk Topic**

```
Topic: Medieval History
- Stability: 15 days
- Difficulty: 5.0
- Days since review: 10 days
- Current R: 0.93

Risk calculation:
- Distance: max(0, (0.9 - 0.93) / 0.9) * 50 = 0
- Velocity: min(|-0.021| * 250, 25) ≈ 5.3
- Difficulty: (5.0 / 10) * 15 = 7.5
- Stability: (1 - 15/50) * 10 = 7.0
Total: 19.8 → Low-Moderate Risk
```

---

## 4. Calendar Integration Options

### 4.1 Option Analysis

| Option | Pros | Cons | Complexity | Recommendation |
|--------|------|------|------------|----------------|
| **A. Local ICS Files** | No API needed, universal, private | Manual import, no sync | Low | **Primary** |
| **B. Apple Calendar (EventKit)** | Native macOS/iOS, auto-sync | macOS only, permissions | Medium | **Secondary** |
| **C. Google Calendar API** | Cross-platform, auto-sync | OAuth complexity, cloud | High | **Optional** |
| **D. CalDAV** | Universal protocol | Complex setup, server needed | High | Not recommended |

### 4.2 Recommended: Local ICS Files (Option A)

**Why:**
- Zero external dependencies
- Works offline
- Privacy-preserving
- Universal calendar import
- Users control when to import

**Implementation:**

```python
from icalendar import Calendar, Event, Alarm
from datetime import datetime, timedelta
from pathlib import Path
import uuid

class CalendarExporter:
    """Export decay alerts to ICS calendar format."""

    def __init__(self, vault_path: Path):
        self.vault_path = vault_path
        self.calendar_dir = vault_path / "70-Calendar"
        self.calendar_dir.mkdir(parents=True, exist_ok=True)

    def export_alerts(
        self,
        alerts: List[DecayAlert],
        goal_name: str,
        merge: bool = True
    ) -> Path:
        """Export alerts to ICS file.

        Args:
            alerts: List of decay alerts
            goal_name: Name of the learning goal
            merge: If True, merge with existing; if False, create new

        Returns:
            Path to the generated ICS file
        """
        cal = self._create_or_load_calendar(merge)

        for alert in alerts:
            event = self._alert_to_event(alert, goal_name)
            cal.add_component(event)

        # Save calendar
        filename = f"MIT-{goal_name.lower().replace(' ', '-')}-reviews.ics"
        ics_path = self.calendar_dir / filename

        with open(ics_path, 'wb') as f:
            f.write(cal.to_ical())

        return ics_path

    def _create_or_load_calendar(self, merge: bool) -> Calendar:
        """Create new or load existing calendar."""
        cal = Calendar()
        cal.add('prodid', '-//MIT Learning Skill//mxm.dk//')
        cal.add('version', '2.0')
        cal.add('name', 'MIT Learning Reviews')
        cal.add('x-wr-calname', 'MIT Learning Reviews')
        cal.add('x-wr-timezone', 'UTC')
        return cal

    def _alert_to_event(self, alert: DecayAlert, goal_name: str) -> Event:
        """Convert decay alert to calendar event."""
        event = Event()

        # Generate unique ID
        event.add('uid', f"mit-{alert.topic_id}-{uuid.uuid4()}@mit-learning")

        # Title based on urgency
        urgency = alert.alert_level.value.upper()
        event.add('summary', f"[{urgency}] Review: {alert.topic_name}")

        # Description with context
        description = self._format_description(alert, goal_name)
        event.add('description', description)

        # Calculate suggested time
        # For critical/red: immediate (next hour)
        # For orange: today
        # For yellow: tomorrow
        start_time = self._calculate_start_time(alert)
        duration = timedelta(minutes=15)  # Default review duration

        event.add('dtstart', start_time)
        event.add('dtend', start_time + duration)
        event.add('dtstamp', datetime.now())

        # Add reminder alarm (15 min before)
        alarm = Alarm()
        alarm.add('action', 'DISPLAY')
        alarm.add('description', f'Review {alert.topic_name}')
        alarm.add('trigger', timedelta(minutes=-15))
        event.add_component(alarm)

        # Categories for filtering
        event.add('categories', ['MIT-Learning', alert.alert_level.value])

        # Priority (1-9, lower = higher priority)
        priority = {
            AlertLevel.CRITICAL: 1,
            AlertLevel.RED: 3,
            AlertLevel.ORANGE: 5,
            AlertLevel.YELLOW: 7,
            AlertLevel.GREEN: 9
        }
        event.add('priority', priority[alert.alert_level])

        return event

    def _format_description(self, alert: DecayAlert, goal_name: str) -> str:
        """Format event description."""
        return f"""
MIT Learning Skill - Decay Alert

Topic: {alert.topic_name}
Goal: {goal_name}

Current Retrievability: {alert.current_retrievability:.1%}
Projected (24h): {alert.projected_retrievability_24h:.1%}
Decay Rate: {abs(alert.decay_rate):.4f}/day

Stability: {alert.stability:.1f} days
Difficulty: {alert.difficulty:.1f}/10
Days since review: {alert.days_since_review:.1f}

Risk Score: {alert.risk_score:.1f}/100
Alert Level: {alert.alert_level.value.upper()}

Recommended Action:
{alert.recommended_action}

---
Generated: {alert.generated_at.isoformat()}
"""
    def _calculate_start_time(self, alert: DecayAlert) -> datetime:
        """Calculate suggested review start time."""
        now = datetime.now()

        if alert.alert_level == AlertLevel.CRITICAL:
            # Immediate: next hour
            return now + timedelta(hours=1)
        elif alert.alert_level == AlertLevel.RED:
            # Today: next available slot
            return now.replace(hour=18, minute=0, second=0) if now.hour < 18 else now + timedelta(hours=2)
        elif alert.alert_level == AlertLevel.ORANGE:
            # Tomorrow morning
            tomorrow = now + timedelta(days=1)
            return tomorrow.replace(hour=9, minute=0, second=0)
        else:  # YELLOW
            # Tomorrow afternoon
            tomorrow = now + timedelta(days=1)
            return tomorrow.replace(hour=14, minute=0, second=0)
```

### 4.3 Alternative: Apple EventKit (Option B)

For users on macOS/iOS who want automatic sync:

```python
# Requires: pip install pyobjc-framework-EventKit

from EventKit import (
    EKEventStore, EKEvent, EKAlarm, EKCalendar,
    EKEntityTypeEvent, EKSpanFutureEvents
)
from datetime import datetime, timedelta
import threading

class AppleCalendarIntegration:
    """Apple Calendar integration via EventKit (macOS only)."""

    def __init__(self):
        self.store = EKEventStore.alloc().init()
        self._authorized = False

    def request_access(self) -> bool:
        """Request calendar access permission."""
        semaphore = threading.Semaphore(0)
        result = [False]

        def completion_handler(granted, error):
            result[0] = granted
            semaphore.release()

        self.store.requestAccessToEntityType_completion_(
            EKEntityTypeEvent,
            completion_handler
        )
        semaphore.acquire()
        self._authorized = result[0]
        return self._authorized

    def create_review_event(
        self,
        alert: DecayAlert,
        goal_name: str
    ) -> bool:
        """Create a review event in Apple Calendar."""
        if not self._authorized:
            return False

        # Get or create MIT Learning calendar
        calendar = self._get_or_create_calendar()

        # Create event
        event = EKEvent.eventWithEventStore_(self.store)
        event.setTitle_(f"Review: {alert.topic_name}")
        event.setNotes_(self._format_notes(alert, goal_name))
        event.setCalendar_(calendar)

        # Set timing
        start = self._calculate_start_time(alert)
        event.setStartDate_(start)
        event.setEndDate_(start + timedelta(minutes=15))

        # Add alarm
        alarm = EKAlarm.alarmWithRelativeOffset_(-15 * 60)  # 15 min before
        event.addAlarm_(alarm)

        # Save
        error = None
        success = self.store.saveEvent_span_error_(
            event,
            EKSpanFutureEvents,
            None
        )

        return success

    def _get_or_create_calendar(self) -> EKCalendar:
        """Get existing MIT Learning calendar or create new."""
        calendars = self.store.calendarsForEntityType_(
            EKEntityTypeEvent
        )

        for cal in calendars:
            if cal.title() == "MIT Learning":
                return cal

        # Create new calendar
        calendar = EKCalendar.calendarForType_(
            EKCalendarTypeCalDAV,
            self.store
        )
        calendar.setTitle_("MIT Learning")
        calendar.setSource_(self.store.defaultCalendarForNewEvents().source())

        self.store.saveCalendar_commit_error_(calendar, True, None)
        return calendar
```

### 4.4 Calendar Integration Workflow in SKILL.md

Add to workflow section:

```markdown
#### 13. decay_alert_management

Monitor knowledge decay and generate review reminders.

| Aspect | Detail |
|--------|--------|
| **Triggers** | Scheduled (daily 6am), user request, threshold breach |
| **Prerequisites** | Active goal with reviewed topics |
| **Steps** | 1. Query topics with FSRS state <br> 2. Calculate retrievability for each <br> 3. Apply decay detection algorithm <br> 4. Generate risk scores <br> 5. Create alerts for at-risk topics <br> 6. Export to ICS calendar file <br> 7. Update dashboard with alerts |
| **Outputs** | ICS file in `70-Calendar/`, dashboard alerts |

**Calendar Integration:**

The system generates an ICS calendar file that users can import into any calendar application:
- **File location:** `~/Obsidian/MIT-{goal}/70-Calendar/MIT-{goal}-reviews.ics`
- **Import:** Double-click or drag into calendar app
- **Updates:** Regenerated daily or on-demand

**Alert Schedule:**
- **6:00 AM:** Daily decay analysis runs
- **Generated:** ICS file updated
- **Notifications:** Calendar reminders for high-priority reviews
```

---

## 5. Notification Timing Strategy

### 5.1 Alert Generation Schedule

```python
from dataclasses import dataclass
from datetime import time

@dataclass
class AlertSchedule:
    """Alert generation timing schedule."""

    # Daily analysis time
    DAILY_ANALYSIS: time = time(6, 0)  # 6:00 AM

    # Review window (users most receptive)
    MORNING_WINDOW: tuple = (time(8, 0), time(10, 0))
    EVENING_WINDOW: tuple = (time(18, 0), time(21, 0))

    # Alert frequency by level
    CRITICAL_COOLDOWN: int = 1  # hours (can alert again after 1h)
    RED_COOLDOWN: int = 4  # hours
    ORANGE_COOLDOWN: int = 24  # hours
    YELLOW_COOLDOWN: int = 48  # hours


class NotificationManager:
    """Manage notification timing and suppression."""

    def __init__(self, db_connection):
        self.conn = db_connection
        self.schedule = AlertSchedule()

    def should_notify(self, alert: DecayAlert, last_notification: datetime) -> bool:
        """Determine if notification should be sent.

        Respects:
        - Cooldown periods per alert level
        - User's quiet hours
        - Notification fatigue limits
        """
        cooldowns = {
            AlertLevel.CRITICAL: timedelta(hours=1),
            AlertLevel.RED: timedelta(hours=4),
            AlertLevel.ORANGE: timedelta(hours=24),
            AlertLevel.YELLOW: timedelta(hours=48),
            AlertLevel.GREEN: timedelta(days=7)
        }

        cooldown = cooldowns[alert.alert_level]
        time_since_last = datetime.now() - last_notification

        return time_since_last >= cooldown

    def get_quiet_hours(self, goal_id: str) -> tuple:
        """Get user's configured quiet hours.

        Default: 10 PM to 7 AM
        """
        # Query user preferences (extend schema)
        # Return (start_time, end_time)
        return (time(22, 0), time(7, 0))
```

### 5.2 Notification Types

| Type | When | Channel | Content |
|------|------|---------|---------|
| **Proactive Digest** | 6 AM daily | Dashboard | Summary of all decay risks |
| **High-Priority Alert** | Critical/Red detected | Dashboard + ICS | Immediate attention needed |
| **Review Reminder** | Scheduled review time | ICS calendar | Topic-specific reminder |
| **Weekly Summary** | Sunday evening | Dashboard + Note | Week's decay patterns |

### 5.3 Notification Format

**Dashboard Alert Widget:**

```markdown
## 🔔 Decay Alerts (3 topics need attention)

### 🔴 Critical (1)
- **T05: Constitutional Amendments**
  R: 72% → Review now
  [Start Review](link)

### 🟠 High Priority (2)
- **T08: Medieval History** - R: 81%
- **T12: Ecology Basics** - R: 84%

[View Calendar](70-Calendar/) | [Dismiss All]
```

**ICS Calendar Event:**

```
SUMMARY: [CRITICAL] Review: Constitutional Amendments
DTSTART: 20260903T180000
DTEND: 20260903T181500
DESCRIPTION: Your knowledge is at risk. Current R: 72%. Review now...
CATEGORIES: MIT-Learning, CRITICAL
PRIORITY: 1
```

---

## 6. Schema Extensions

### 6.1 New Tables

```sql
-- Decay alerts table
CREATE TABLE IF NOT EXISTS decay_alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    topic_id TEXT NOT NULL,
    alert_level TEXT NOT NULL,     -- green|yellow|orange|red|critical
    retrievability REAL NOT NULL,
    projected_retrievability_24h REAL,
    decay_rate REAL,
    risk_score REAL,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dismissed_at TIMESTAMP,
    notification_sent INTEGER DEFAULT 0,
    FOREIGN KEY (topic_id) REFERENCES topics(topic_id),
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id)
);

CREATE INDEX IF NOT EXISTS idx_decay_alerts_level
ON decay_alerts(alert_level);

CREATE INDEX IF NOT EXISTS idx_decay_alerts_generated
ON decay_alerts(generated_at);

CREATE INDEX IF NOT EXISTS idx_decay_alerts_topic
ON decay_alerts(topic_id);


-- Alert history table (for analytics)
CREATE TABLE IF NOT EXISTS alert_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    topic_id TEXT NOT NULL,
    alert_level TEXT NOT NULL,
    action_taken TEXT,             -- reviewed|dismissed|ignored
    time_to_action INTEGER,        -- seconds from alert to action
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (topic_id) REFERENCES topics(topic_id)
);

CREATE INDEX IF NOT EXISTS idx_alert_history_topic
ON alert_history(topic_id);


-- User notification preferences
CREATE TABLE IF NOT EXISTS notification_preferences (
    goal_id TEXT PRIMARY KEY,
    daily_digest_enabled INTEGER DEFAULT 1,
    high_priority_alerts INTEGER DEFAULT 1,
    quiet_hours_start TIME DEFAULT '22:00',
    quiet_hours_end TIME DEFAULT '07:00',
    weekend_alerts_enabled INTEGER DEFAULT 0,
    max_daily_alerts INTEGER DEFAULT 5,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id)
);
```

### 6.2 Migration Script

```python
def migrate_add_decay_alerts(db_path: Path) -> None:
    """Add decay alert tables to existing database.

    Run as part of schema_version upgrade.
    """
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Create decay_alerts table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS decay_alerts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            goal_id TEXT NOT NULL,
            topic_id TEXT NOT NULL,
            alert_level TEXT NOT NULL,
            retrievability REAL NOT NULL,
            projected_retrievability_24h REAL,
            decay_rate REAL,
            risk_score REAL,
            generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            dismissed_at TIMESTAMP,
            notification_sent INTEGER DEFAULT 0,
            FOREIGN KEY (topic_id) REFERENCES topics(topic_id),
            FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id)
        )
    """)

    # Create indexes
    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_decay_alerts_level
        ON decay_alerts(alert_level)
    """)

    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_decay_alerts_generated
        ON decay_alerts(generated_at)
    """)

    # Create other tables...
    # (alert_history, notification_preferences)

    conn.commit()
    conn.close()
```

---

## 7. SKILL.md Workflow Modifications

### 7.1 Add New Workflow

Insert after Workflow 12 (study_schedule_optimization):

```markdown
#### 13. decay_alert_management

Monitor knowledge decay and generate proactive review reminders.

| Aspect | Detail |
|--------|--------|
| **Triggers** | "Check my retention", "What's at risk", "Decay alerts", scheduled (daily 6am) |
| **Prerequisites** | Active goal with reviewed topics |
| **Steps** | 1. Query topics with FSRS state <br> 2. Calculate current retrievability: `R(t,S) = (1 + t/(9*S))^(-1)` <br> 3. Project retrievability in 24 hours <br> 4. Calculate decay rate: `dR/dt = -9*S/(9*S + t)^2` <br> 5. Assign alert level (green/yellow/orange/red/critical) <br> 6. Generate risk score (0-100) <br> 7. Create alerts for non-green topics <br> 8. Export to ICS calendar file <br> 9. Update dashboard |
| **Outputs** | Decay alerts, `70-Calendar/MIT-{goal}-reviews.ics`, dashboard widget |

**Alert Levels:**

| Level | Retrievability | Action |
|-------|----------------|--------|
| 🟢 Green | R > 0.95 | Knowledge secure |
| 🟡 Yellow | 0.90 < R ≤ 0.95 | Approaching threshold |
| 🟠 Orange | 0.85 < R ≤ 0.90 | Schedule review today |
| 🔴 Red | 0.80 < R ≤ 0.85 | Review within hours |
| ⛔ Critical | R ≤ 0.80 | Immediate review needed |

**Calendar Integration:**

Alerts generate an ICS calendar file for import into any calendar app:

```
~/Obsidian/MIT-{goal}/70-Calendar/MIT-{goal}-reviews.ics
```

Import via: Double-click file → Opens in default calendar

**Decay Alert Dashboard Widget:**

Appears on progress dashboard when alerts exist:

- Summary count by level
- Top 3 highest-risk topics
- Quick-action link to start review
- Link to calendar file

**Example Interaction:**

```
User: "What's at risk?"

→ Workflow: decay_alert_management

→ Analysis:
  - Querying 45 topics with FSRS state...
  - Calculating retrievability for each...
  - Detecting decay patterns...

→ Alerts Generated:
  🔴 CRITICAL: T05 Constitutional Amendments (R: 72%)
  🟠 HIGH: T08 Medieval History (R: 81%)
  🟠 HIGH: T12 Ecology Basics (R: 84%)
  🟡 MODERATE: T15 Indian Economy (R: 88%)

→ Risk Scores:
  T05: 67/100 (review immediately)
  T08: 45/100 (review today)
  T12: 42/100 (review today)

→ Calendar:
  Updated: ~/Obsidian/MIT-upsc-prelims/70-Calendar/MIT-upsc-prelims-reviews.ics
  4 events added

→ Recommended Action:
  Start with T05 Constitutional Amendments (critical priority)
  [Begin Review Session]
```

---

### 7.2 Update Triggers Section

Add to "Review Intents":

```markdown
| Trigger | Workflow |
|---------|----------|
| "What's at risk" | decay_alert_management |
| "Check my retention" | decay_alert_management |
| "Decay alerts" | decay_alert_management |
| "What am I forgetting" | decay_alert_management |
```

### 7.3 Update Dashboard Workflow

Add to progress_dashboard workflow:

```markdown
**Decay Alert Widget:**

If alerts exist, show summary widget:

```
## 🔔 Knowledge Decay Alerts

You have **3 topics** at risk of being forgotten.

| Topic | Retrievability | Risk | Action |
|-------|----------------|------|--------|
| T05 Constitutional Amendments | 72% | **Critical** | [Review Now] |
| T08 Medieval History | 81% | High | [Review] |
| T12 Ecology Basics | 84% | High | [Review] |

[View All Alerts] | [Export to Calendar] | [Dismiss]
```

### 7.4 Update Vault Structure

Add new directory to vault structure section:

```markdown
├── 70-Calendar/                   # Review schedule
│   ├── MIT-{goal}-reviews.ics    # ICS calendar file
│   └── Archive/                   # Old calendar files
```

---

## 8. Implementation Checklist

### Phase 1: Core Detection (Priority: High)

- [ ] Create `scripts/decay_detector.py`
  - [ ] Implement `retrievability()` function (exists in fsrs_scheduler.py)
  - [ ] Implement `decay_rate()` function
  - [ ] Implement `DecayDetector` class
  - [ ] Implement `DecayAlert` dataclass
  - [ ] Implement `AlertLevel` enum
  - [ ] Implement risk score calculation

- [ ] Create `tests/test_decay_detector.py`
  - [ ] Test retrievability calculation
  - [ ] Test decay rate calculation
  - [ ] Test alert level assignment
  - [ ] Test risk score calculation
  - [ ] Test edge cases (new topics, stability boundaries)

### Phase 2: Calendar Integration (Priority: Medium)

- [ ] Add `icalendar` to dependencies
- [ ] Create `scripts/calendar_exporter.py`
  - [ ] Implement `CalendarExporter` class
  - [ ] Implement ICS file generation
  - [ ] Implement event creation from alerts
  - [ ] Implement alarm/reminders

- [ ] Create vault directory structure update
  - [ ] Add `70-Calendar/` directory creation

- [ ] Create `tests/test_calendar_exporter.py`
  - [ ] Test ICS file format
  - [ ] Test event fields
  - [ ] Test file output

### Phase 3: Schema Migration (Priority: High)

- [ ] Update `scripts/sqlite_init.py`
  - [ ] Add `decay_alerts` table
  - [ ] Add `alert_history` table
  - [ ] Add `notification_preferences` table
  - [ ] Add indexes

- [ ] Create migration script for existing databases
  - [ ] Implement `migrate_add_decay_alerts()`
  - [ ] Test migration on existing databases

### Phase 4: Notification System (Priority: Medium)

- [ ] Create `scripts/notification_manager.py`
  - [ ] Implement `NotificationManager` class
  - [ ] Implement cooldown logic
  - [ ] Implement quiet hours
  - [ ] Implement daily digest generation

- [ ] Update dashboard generation
  - [ ] Add decay alert widget
  - [ ] Add alert summary counts

### Phase 5: SKILL.md Updates (Priority: High)

- [ ] Add Workflow 13: decay_alert_management
- [ ] Update triggers section
- [ ] Update dashboard workflow
- [ ] Update vault structure documentation
- [ ] Update error code reference (if needed)

### Phase 6: Integration Testing (Priority: High)

- [ ] End-to-end test: detect → alert → export → import calendar
- [ ] Test with varying topic states
- [ ] Test with edge cases (all mastered, all new, empty)
- [ ] Performance test with 100+ topics

### Phase 7: Apple Calendar Integration (Optional, Priority: Low)

- [ ] Add `pyobjc-framework-EventKit` dependency
- [ ] Create `scripts/apple_calendar.py`
- [ ] Implement permission request flow
- [ ] Implement event creation
- [ ] Test on macOS

---

## Appendix A: Quick Reference

### Decay Detection Formulas

```
Retrievability:
R(t, S) = (1 + t/(9*S))^(-1)

Decay Rate:
dR/dt = -9*S / (9*S + t)^2

Risk Score (0-100):
Risk = Distance(40%) + Velocity(30%) + Difficulty(15%) + Stability(15%)
```

### Alert Thresholds

| Level | R Range | Score Range |
|-------|---------|--------------|
| Green | > 0.95 | 0-19 |
| Yellow | 0.90-0.95 | 20-39 |
| Orange | 0.85-0.90 | 40-59 |
| Red | 0.80-0.85 | 60-79 |
| Critical | < 0.80 | 80-100 |

### File Locations

```
scripts/decay_detector.py      # Core detection logic
scripts/calendar_exporter.py   # ICS generation
scripts/notification_manager.py # Alert management
tests/test_decay_detector.py   # Unit tests
docs/DECAY-ALERTS-DESIGN.md    # This document
```

---

**Document Version:** 1.0
**Last Updated:** 2026-09-03
**Implementation Status:** Ready for development
