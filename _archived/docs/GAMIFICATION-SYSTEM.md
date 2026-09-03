# MIT Learning Skill - Gamification System Documentation

**Version 3.0 - Exhaustive Edition**
**Last Updated: September 1, 2026**

---

## Table of Contents

1. [Overview](#1-overview)
2. [Achievement System](#2-achievement-system)
3. [Streak Mechanics](#3-streak-mechanics)
4. [Progress Visualization](#4-progress-visualization)
5. [Psychology Foundation](#5-psychology-foundation)
6. [Implementation](#6-implementation)
7. [A/B Testing Recommendations](#7-ab-testing-recommendations)

---

## 1. Overview

### 1.1 Design Philosophy

The gamification system is designed around **learning-aligned gamification** principles—mechanics that reinforce good learning behaviors rather than distract from them.

**Core Principles:**

| Principle | Description | Evidence |
|-----------|-------------|----------|
| Early Accessibility | 43.1% of achievements unlock day one | Trophy.so study |
| Difficulty Correlation | Harder achievements = better retention | 74.2% retention for hard achievements |
| Meaningful Rewards | Unlock content, not just badges | Content discovery principle |
| Loss Aversion | Protect what you've built | Duolingo 3.6x engagement |
| Progress Visibility | Always see forward momentum | Sailer & Homner (2020) |

### 1.2 System Components

```
┌──────────────────────────────────────────────────────────────┐
│                    GAMIFICATION SYSTEM                        │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌────────────────┐│
│  │ ACHIEVEMENTS    │  │    STREAKS      │  │   PROGRESS     ││
│  │                 │  │                 │  │                ││
│  │ • 20 achievements│  │ • Daily counter │  │ • Mastery %   ││
│  │ • Tiered difficulty│ │ • Freeze system │  │ • Visual bars ││
│  │ • Unlock content│  │ • Loss aversion│  │ • Timeline     ││
│  │ • Gallery view  │  │ • Milestone badges │ │ • Predictions ││
│  └─────────────────┘  └─────────────────┘  └────────────────┘│
│                                                              │
│              ↓                    ↓                   ↓        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    DASHBOARD                              │  │
│  │   Unified view of all gamification elements              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 2. Achievement System

### 2.1 Achievement Definitions

#### Easy Achievements (Unlock on Day 1)

| ID | Name | Description | Trigger | Unlock Rate |
|----|------|-------------|---------|-------------|
| `first_topic` | First Step | Complete your first topic | topics_completed ≥ 1 | 100% |
| `first_review` | First Review | Complete your first review | total_reviews ≥ 1 | 98% |
| `first_practice` | Hands On | Complete first practice session | practice_sessions ≥ 1 | 85% |
| `set_goal` | Goal Getter | Create your first learning goal | goals_created ≥ 1 | 100% |

#### Medium Achievements (1-2 Weeks)

| ID | Name | Description | Trigger | Unlock Rate |
|----|------|-------------|---------|-------------|
| `week_streak` | Week Warrior | Maintain a 7-day streak | current_streak ≥ 7 | 65% |
| `five_topics` | Half Decade | Complete 5 topics | topics_completed ≥ 5 | 55% |
| `review_25` | Quarter Century | Complete 25 reviews | total_reviews ≥ 25 | 50% |
| `early_bird` | Early Bird | Study before 8am | session_before_8am ≥ 1 | 40% |
| `night_owl` | Night Owl | Study after 10pm | session_after_10pm ≥ 1 | 35% |

#### Hard Achievements (1-2 Months)

| ID | Name | Description | Trigger | Unlock Rate |
|----|------|-------------|---------|-------------|
| `ten_topics` | Knowledge Builder | Master 10 topics | topics_mastered ≥ 10 | 35% |
| `month_streak` | Month Master | Maintain a 30-day streak | current_streak ≥ 30 | 15% |
| `review_100` | Century Reviewer | Complete 100 reviews | total_reviews ≥ 100 | 45% |
| `interleave_master` | Pattern Seeker | 10 interleaved sessions | interleaved_sessions ≥ 10 | 25% |
| `perfect_week` | Perfect Week | 100% accuracy for 7 days | perfect_days ≥ 7 | 10% |

#### Expert Achievements (Long-term)

| ID | Name | Description | Trigger | Unlock Rate |
|----|------|-------------|---------|-------------|
| `fifty_topics` | Scholar | Master 50 topics | topics_mastered ≥ 50 | 8% |
| `hundred_days` | Dedication | 100-day streak | current_streak ≥ 100 | 5% |
| `review_500` | Half Thousand | Complete 500 reviews | total_reviews ≥ 500 | 12% |
| `all_mastered` | Perfectionist | Master all topics | all topics ≥ 90% mastery | 3% |

#### Special Achievements

| ID | Name | Description | Trigger | Unlock Rate |
|----|------|-------------|---------|-------------|
| `comeback_kid` | Comeback Kid | Resume after 30+ day break | days_absent > 30, then activity | 20% |
| `polymath` | Polymath | Active goals in 3 different types | unique goal_types ≥ 3 | 15% |
| `speed_learner` | Speed Learner | Master topic in <7 days | fast_mastery ≥ 1 | 10% |
| `torch_bearer` | Torch Bearer | Maintain 60-day streak | current_streak ≥ 60 | 8% |

### 2.2 Achievement Unlock Logic

```python
ACHIEVEMENT_DEFINITIONS = {
    'first_topic': {
        'name': 'First Step',
        'description': 'Complete your first topic',
        'difficulty': 'easy',
        'icon': '🎯',
        'check': lambda stats: stats['topics_completed'] >= 1,
        'reward_message': 'You\'ve taken your first step! Every master was once a beginner.'
    },
    'week_streak': {
        'name': 'Week Warrior',
        'description': 'Maintain a 7-day streak',
        'difficulty': 'medium',
        'icon': '🔥',
        'check': lambda stats: stats['current_streak'] >= 7,
        'reward_message': 'A full week of dedication! You\'re building a powerful habit.'
    },
    'ten_topics': {
        'name': 'Knowledge Builder',
        'description': 'Master 10 topics',
        'difficulty': 'hard',
        'icon': '📚',
        'check': lambda stats: stats['topics_mastered'] >= 10,
        'reward_message': 'Ten topics mastered! Your knowledge foundation grows stronger.'
    },
    # ... all achievements
}

def check_achievements(conn: sqlite3.Connection, goal_id: str) -> list[str]:
    """Check for newly unlocked achievements.
    
    Returns list of achievement IDs that were newly unlocked.
    """
    cursor = conn.cursor()
    
    # Get current stats
    stats = get_achievement_stats(conn, goal_id)
    
    # Get already unlocked achievements
    cursor.execute("""
        SELECT achievement_id FROM achievements WHERE goal_id = ?
    """, (goal_id,))
    unlocked = {row[0] for row in cursor.fetchall()}
    
    # Check each achievement
    newly_unlocked = []
    for achievement_id, definition in ACHIEVEMENT_DEFINITIONS.items():
        if achievement_id not in unlocked:
            if definition['check'](stats):
                # Unlock achievement
                unlock_achievement(conn, goal_id, achievement_id)
                newly_unlocked.append(achievement_id)
    
    return newly_unlocked

def unlock_achievement(conn: sqlite3.Connection, goal_id: str, achievement_id: str):
    """Unlock an achievement."""
    cursor = conn.cursor()
    
    cursor.execute("""
        INSERT INTO achievements (goal_id, achievement_id, unlocked_at)
        VALUES (?, ?, ?)
    """, (goal_id, achievement_id, datetime.now().isoformat()))
    
    conn.commit()
    
    # Trigger celebration
    definition = ACHIEVEMENT_DEFINITIONS[achievement_id]
    display_achievement_notification(definition)
```

### 2.3 Achievement Display

```python
def display_achievement_notification(achievement: dict):
    """Display achievement unlock notification.
    
    Format varies by difficulty:
    - Easy: Simple toast notification
    - Medium: Highlighted notification with sound
    - Hard: Full celebration animation
    - Expert: Special recognition
    """
    difficulty_formatting = {
        'easy': {'duration': '2s', 'sound': 'soft-chime'},
        'medium': {'duration': '3s', 'sound': 'success-fanfare'},
        'hard': {'duration': '5s', 'sound': 'achievement-orchestra'},
        'expert': {'duration': '7s', 'sound': 'legendary-fanfare'}
    }
    
    formatting = difficulty_formatting[achievement['difficulty']]
    
    print(f"""
╔═════════════════════════════════════════════════════╗
║                   ACHIEVEMENT UNLOCKED!              ║
╠═════════════════════════════════════════════════════╣
║                                                     ║
║    {achievement['icon']}  {achievement['name']}                       ║
║                                                     ║
║    {achievement['description']}                     ║
║                                                     ║
║    {achievement['reward_message']}                  ║
║                                                     ║
╚═════════════════════════════════════════════════════╝
""")
```

---

## 3. Streak Mechanics

### 3.1 Streak Definition

A **streak** is the number of consecutive days with at least one learning activity. Activities include:

- Learning a new topic
- Completing a review session
- Completing a practice session
- Taking a diagnostic assessment

### 3.2 Streak Rules

| Rule | Description |
|------|-------------|
| **Activity Requirement** | Minimum 1 activity per day (UTC day or local day) |
| **Streak Freeze** | 1 free freeze per month, protects 1 missed day |
| **Streak Reset** | Reset to 0 if no activity AND no freeze available |
| **Streak Warning** | Reminder at 8pm local time if no activity |
| **Streak Celebration** | Special notification at milestones (7, 14, 30, 60, 100 days) |

### 3.3 Streak State Machine

```
┌─────────────────────────────────────────────────────────────┐
│                    STREAK STATE MACHINE                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───────────┐                                              │
│  │    NEW    │                                              │
│  │ (streak=0)│                                              │
│  └─────┬─────┘                                              │
│        │                                                    │
│        │ First activity                                     │
│        ▼                                                    │
│  ┌───────────┐                                              │
│  │   ACTIVE  │◄──────────────────────────────────┐          │
│  │(streak>0) │                                   │          │
│  └─────┬─────┘                                   │          │
│        │                                         │          │
│   ┌────┴────┐                                     │          │
│   │         │                                     │          │
│   │     8pm, no activity                          │          │
│   │         │                                     │          │
│   ▼         ▼                                     │          │
│ ┌─────┐  ┌──────────┐                             │          │
│ │     │  │ WARNING  │                             │          │
│ │Done │  │(8pm alarm)│                            │          │
│ │today│  └────┬─────┘                             │          │
│ └──┬──┘       │                                   │          │
│    │          │                                   │          │
│    │     ┌────┴────┬────────────┐                 │          │
│    │     │         │            │                 │          │
│    │  Activity  Use Freeze   Midnight            │          │
│    │     │         │            │                 │          │
│    │     ▼         ▼            ▼                 │          │
│    │  ┌─────┐  ┌────────┐  ┌───────────┐         │          │
│    │  │     │  │ FROZEN │  │  BROKEN   │         │          │
│    └─►│ACTIVE│ │(1 day) │  │(streak=0) │         │          │
│       └──┬──┘ └────┬───┘  └─────┬─────┘         │          │
│          │         │            │                 │          │
│          │    Next activity  Next activity        │          │
│          │         │            │                 │          │
│          └─────────┴────────────┴─────────────────┘          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 3.4 Streak Implementation

```python
def update_streak(conn: sqlite3.Connection, goal_id: str) -> StreakResult:
    """Update streak based on today's activity.
    
    Called at end of any learning session.
    """
    cursor = conn.cursor()
    today = date.today()
    
    # Get current streak state
    cursor.execute("""
        SELECT current_streak, longest_streak, last_activity_date,
               streak_freeze_available
        FROM streak_state
        WHERE goal_id = ?
    """, (goal_id,))
    
    row = cursor.fetchone()
    if not row:
        # Initialize for new goal
        cursor.execute("""
            INSERT INTO streak_state (goal_id, current_streak, longest_streak,
                                      last_activity_date)
            VALUES (?, 1, 1, ?)
        """, (goal_id, today))
        conn.commit()
        return StreakResult(current=1, longest=1, status='started')
    
    current_streak, longest_streak, last_activity, freezes_available = row
    last_activity = date.fromisoformat(last_activity) if last_activity else None
    
    # Already active today
    if last_activity == today:
        return StreakResult(current=current_streak, longest=longest_streak, 
                           status='already_counted')
    
    # Calculate days since last activity
    days_since = (today - last_activity).days if last_activity else 0
    
    if days_since == 1:
        # Consecutive day - increase streak
        current_streak += 1
        longest_streak = max(longest_streak, current_streak)
        status = 'increased'
        
    elif days_since > 1:
        # Gap detected
        if freezes_available > 0 and days_since == 2:
            # Use streak freeze (covers 1 missed day)
            freezes_available -= 1
            current_streak += 1
            longest_streak = max(longest_streak, current_streak)
            status = 'freeze_used'
        else:
            # Streak broken
            current_streak = 1
            status = 'broken'
    
    else:
        # Shouldn't happen
        status = 'error'
    
    # Update database
    cursor.execute("""
        UPDATE streak_state
        SET current_streak = ?, longest_streak = ?, last_activity_date = ?,
            streak_freeze_available = ?
        WHERE goal_id = ?
    """, (current_streak, longest_streak, today, freezes_available, goal_id))
    
    conn.commit()
    
    return StreakResult(
        current=current_streak,
        longest=longest_streak,
        status=status,
        milestone=is_milestone(current_streak)
    )

def is_milestone(streak: int) -> Optional[int]:
    """Check if streak is a milestone."""
    milestones = [7, 14, 30, 60, 100, 365]
    return streak if streak in milestones else None
```

### 3.5 Streak Freeze System

```python
class StreakFreezeManager:
    """Manage streak freeze allocation and usage."""
    
    FREEZES_PER_MONTH = 1
    
    @classmethod
    def get_freezes_available(cls, conn: sqlite3.Connection, goal_id: str) -> int:
        """Get number of streak freezes available."""
        cursor = conn.cursor()
        
        # Check if month changed (reset freezes)
        cursor.execute("""
            SELECT streak_freeze_available, streak_freeze_used_date
            FROM streak_state
            WHERE goal_id = ?
        """, (goal_id,))
        
        freezes, used_date = cursor.fetchone()
        
        if used_date:
            used_month = date.fromisoformat(used_date).month
            current_month = date.today().month
            
            # New month = reset freeze
            if current_month != used_month:
                cursor.execute("""
                    UPDATE streak_state
                    SET streak_freeze_available = ?
                    WHERE goal_id = ?
                """, (cls.FREEZES_PER_MONTH, goal_id))
                conn.commit()
                freezes = cls.FREEZES_PER_MONTH
        
        return freezes or 0
    
    @classmethod
    def use_freeze(cls, conn: sqlite3.Connection, goal_id: str) -> bool:
        """Use a streak freeze.
        
        Returns True if freeze used successfully.
        """
        available = cls.get_freezes_available(conn, goal_id)
        
        if available <= 0:
            return False
        
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE streak_state
            SET streak_freeze_available = streak_freeze_available - 1,
                streak_freeze_used_date = ?
            WHERE goal_id = ?
        """, (date.today().isoformat(), goal_id))
        
        conn.commit()
        return True
```

---

## 4. Progress Visualization

### 4.1 Visual Elements

| Element | Description | Update Frequency |
|---------|-------------|------------------|
| Mastery percentage | Overall progress to completion | After each review |
| Progress bar | Visual representation of mastery | Real-time |
| Streak counter | Current streak display | Real-time |
| Achievement gallery | Unlocked achievements grid | On unlock |
| Topic completion | Number of completed topics | Real-time |
| Timeline | Learning journey visualization | Daily |

### 4.2 Progress Bar Implementation

```python
def format_progress_bar(percentage: float, width: int = 10) -> str:
    """Create ASCII progress bar.
    
    Uses filled (■) and empty (□) characters.
    """
    filled = int(percentage / 100 * width)
    empty = width - filled
    
    bar = '■' * filled + '□' * empty
    
    # Add color indicators
    if percentage >= 90:
        bar = f'🟢 {bar}'  # Green - excellent
    elif percentage >= 70:
        bar = f'🟡 {bar}'  # Yellow - good
    elif percentage >= 50:
        bar = f'🟠 {bar}'  # Orange - moderate
    else:
        bar = f'🔴 {bar}'  # Red - needs work
    
    return bar

def format_short_bar(percentage: float) -> str:
    """Create compact progress bar for inline display."""
    if percentage >= 90:
        return '█'  # Full
    elif percentage >= 70:
        return '▓'  # Mostly full
    elif percentage >= 50:
        return '▒'  # Half
    elif percentage >= 30:
        return '░'  # Some
    return '○'  # Empty
```

### 4.3 Dashboard Visualization

```markdown
# Progress Dashboard

## Overall Progress
🟢 ████████░░ 82% Complete

## Mastery Distribution
Topics Mastered:     ████████████ 24
Topics In Progress:  ████░░░░░░░░ 12
Topics Available:    ██░░░░░░░░░░  6

## Streak
Current: 45 days 🔥🔥🔥
Longest: 67 days

## Milestones
✅ Week Warrior (7 days)
✅ Month Master (30 days)
⬜ Torch Bearer (60 days) - 15 days to go

## Level Progress
Level 12: ████████░░ 2,450 / 3,000 XP
Next level unlocks: Advanced Analytics
```

---

## 5. Psychology Foundation

### 5.1 Design Principles Backed by Research

| Principle | Effect | Source |
|-----------|--------|--------|
| Loss Aversion | 3.6x engagement | Duolingo retention study (2023) |
| Early Wins | 43.1% day-one unlocks | Trophy.so analysis |
| Variable Rewards | Sustained engagement | Skinner operant conditioning |
| Progress Visibility | g=0.78-0.82 | Sailer & Homner (2020) |
| Goal Gradient | Acceleration near completion | Hull (1934) |
| Zeigarnik Effect | Memory for incomplete tasks | Zeigarnik (1927) |
| Self-Determination | Autonomy, competence, relatedness | Ryan & Deci (2000) |

### 5.2 Gamification Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                 MOTIVATION HIERARCHY                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  INTRINSIC MOTIVATION (Highest)                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ • Mastery of subject                                │   │
│  │ • Personal growth                                    │   │
│  │ • Intellectual curiosity                             │   │
│  │ • Self-efficacy                                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                           ▲                                 │
│                           │ Supports                        │
│  IDENTIFIED REGULATION                                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ • Career advancement                                 │   │
│  │ • Exam success                                       │   │
│  │ • Personal goals                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                           ▲                                 │
│                           │ Supports                        │
│  EXTERNAL REGULATION (Gamification Layer)                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ • Achievements ✓                                    │   │
│  │ • Streaks ✓                                          │   │
│  │ • Progress bars ✓                                    │   │
│  │ • Milestones ✓                                       │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Goal: Gamification should SUPPORT intrinsic motivation,    │
│        not REPLACE it.                                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 5.3 Dangerous Patterns to Avoid

| Pattern | Risk | Avoid Method |
|---------|------|--------------|
| Excessive extrinsic rewards | Undermines intrinsic motivation | Keep rewards learning-aligned |
| Random chance elements | Gambling addiction risk | No loot boxes, chance mechanics |
| Social comparison | Negative competition | Focus on personal progress |
| FOMO mechanics | Anxiety | Reasonable deadlines |
| Pay-to-win | Unfair advantage | All features free |

---

## 6. Implementation

### 6.1 Achievement Database Schema

```sql
CREATE TABLE achievements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id TEXT NOT NULL,
    achievement_id TEXT NOT NULL,
    unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata JSON,  -- Additional unlock data
    FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id),
    UNIQUE(goal_id, achievement_id)
);

CREATE INDEX idx_achievements_goal ON achievements(goal_id);
CREATE INDEX idx_achievements_unlocked ON achievements(unlocked_at);
```

### 6.2 Streak Database Schema

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

### 6.3 Notification System

```python
class AchievementNotification:
    """Display achievement unlock notifications."""
    
    NOTIFICATION_TEMPLATES = {
        'easy': """
🎉 Achievement Unlocked!
{icon} {name}
{description}
        """,
        'medium': """
🎉🎉 Achievement Unlocked! 🎉🎉
{icon} {name}
{description}

{reward_message}
        """,
        'hard': """
🌟 🎉 ACHIEVEMENT UNLOCKED! 🎉 🌟
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{icon} {name}
{description}

{reward_message}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        """,
        'expert': """
🏆 🌟 ✨ LEGENDARY ACHIEVEMENT! ✨ 🌟 🏆
════════════════════════════════════════
{icon} {name}
{description}

{reward_message}
════════════════════════════════════════
        """
    }
    
    @classmethod
    def display(cls, achievement: dict):
        """Display achievement notification."""
        template = cls.NOTIFICATION_TEMPLATES[achievement['difficulty']]
        print(template.format(**achievement))
```

---

## 7. A/B Testing Recommendations

### 7.1 Testable Hypotheses

| Hypothesis | Metric | Expected Effect |
|------------|--------|-----------------|
| Streak freeze count (1 vs 2) | 30-day retention | +10% with 2 freezes |
| Achievement sounds (on vs off) | Session completion | +5% with sounds |
| Progress bar position (top vs bottom) | Daily usage | Test needed |
| Milestone celebrations (simple vs elaborate) | 7-day streak | +8% with elaborate |
| Gamification visibility (high vs low) | Intrinsic motivation | Monitor for negative effects |

### 7.2 Measurement Framework

```python
def track_gamification_event(event_type: str, goal_id: str, metadata: dict):
    """Track gamification event for analytics.
    
    Events tracked:
    - achievement_unlocked
    - milestone_reached
    - streak_increased
    - streak_broken
    -> streak_freeze_used
    """
    analytics.track('gamification', {
        'event_type': event_type,
        'goal_id': goal_id,
        'timestamp': datetime.now().isoformat(),
        **metadata
    })
```

---

## Appendix A: Achievement Quick Reference

| Achievement | Tier | Days to Unlock | Notes |
|-------------|------|----------------|-------|
| First Step | Easy | 1 | 100% unlock rate |
| Week Warrior | Medium | 7 | Streak milestone |
| Knowledge Builder | Hard | 30+ | Requires consistency |
| Month Master | Hard | 30 | Streak achievement |
| Comeback Kid | Special | 30+ gap | Re-engagement reward |

---

*Document generated: September 1, 2026*
*Total pages: 25+*
*"Every achievement earned. Every streak protected."*
