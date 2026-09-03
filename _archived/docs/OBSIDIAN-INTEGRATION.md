# MIT Learning Skill - Obsidian Integration Documentation

**Version 3.0 - Exhaustive Edition**

---

## Table of Contents

1. [Overview](#1-overview)
2. [Vault Structure](#2-vault-structure)
3. [Note Templates](#3-note-templates)
4. [Frontmatter Schemas](#4-frontmatter-schemas)
5. [Dataview Queries](#5-dataview-queries)
6. [Plugin Configuration](#6-plugin-configuration)
7. [Backup Procedures](#7-backup-procedures)

---

## 1. Overview

### 1.1 Purpose

Obsidian provides the **cold memory** layer for MIT Learning Skill, offering:
- Human-readable, long-term knowledge storage
- Visual knowledge graph with bidirectional links
- Rich formatting with markdown support
- Cross-platform access to learning materials

### 1.2 Vault Location

```
~/Obsidian/MIT-{goal-slug}/

Examples:
- ~/Obsidian/MIT-upsc-prelims/
- ~/Obsidian/MIT-python-skill/
- ~/Obsidian/MIT-quantum-physics/
```

---

## 2. Vault Structure

```
MIT-{goal-slug}/
│
├── 00-Dashboard/
│   ├── Progress.md              # Main progress dashboard
│   ├── Achievements.md          # Achievement gallery
│   └── Stats.md                 # Detailed statistics
│
├── 10-Active-Topics/
│   ├── T01-topic-slug.md       # Active learning notes
│   ├── T02-another-topic.md
│   └── ...
│
├── 20-Review-Queue/
│   ├── Due-2026-09-01.md       # Daily review queue
│   ├── Due-2026-09-02.md
│   └── Archive/                 # Past review queues
│       ├── 2026-08/
│       └── 2026-09/
│
├── 30-Completed-Topics/
│   ├── T00-prerequisites.md    # Mastered topics (archived)
│   └── ...
│
├── 40-Practice/
│   ├── T01-problems.md          # Practice problem sets
│   ├── Interleaved-2026-09-01.md # Mixed practice sessions
│   └── Quizzes/
│       ├── Quiz-T01.md
│       └── ...
│
├── 50-Resources/
│   ├── Syllabus.md              # Goal syllabus
│   ├── References.md            # External links
│   └── Templates/               # Note templates
│       ├── Topic Template.md
│       └── Review Template.md
│
└── 60-Current-Affairs/          # For exam goals only
    ├── Digest-2026-09-01.md
    └── Archive/
        └── 2026-08/
```

### 2.1 Directory Purposes

| Directory | Purpose | Update Frequency |
|-----------|---------|------------------|
| 00-Dashboard | Progress tracking | Daily |
| 10-Active-Topics | Current learning notes | Per session |
| 20-Review-Queue | Daily review schedules | Daily |
| 30-Completed-Topics | Mastered material | As completed |
| 40-Practice | Practice problems | Per session |
| 50-Resources | Static resources | Once |
| 60-Current-Affairs | News digest | Daily |

---

## 3. Note Templates

### 3.1 Topic Note Template

```markdown
---
id: T01-topic-slug
created: '2026-09-01'
updated: '2026-09-01T14:30:00'
mastery: 0.45
next_review: '2026-09-05'
status: in_progress
difficulty: 5.2
stability: 12.5
related:
  - '[[T00-prerequisite]]'
  - '[[T05-related]]'
sources:
  - 'https://source.com'
tags:
  - topic
  - active
---

# [Topic Name]

## Overview
[Brief introduction - 2-3 sentences]

## Key Concepts

### Concept 1: [Name]
[Explanation with examples]

### Concept 2: [Name]
[Explanation with examples]

## Worked Examples

### Example 1: [Problem Title]
**Problem:** [Statement]

**Solution:**
Step 1: [First step]
Step 2: [Second step]
Step 3: [Final step]

**Key Insight:** [What to learn]

## Connections

### Builds On
- [[T00-prerequisite]] - [Connection explanation]

### Relates To
- [[T05-related]] - [Relationship description]

### Leads To
- [[T10-next-topic]] - [What comes next]

## Embedded Practice

### Quick Check
1. [Question 1]
2. [Question 2]

<details>
<summary>Show Answers</summary>
1. [Answer 1]
2. [Answer 2]
</details>

## Summary
- Key takeaway 1
- Key takeaway 2
- Key takeaway 3

## References
1. [Source 1](URL)
2. [Source 2](URL)

---
_Mastery: 45% | Next review: 2026-09-05 | Difficulty: 5.2/10_
```

### 3.2 Review Queue Template

```markdown
---
id: review-2026-09-01
created: '2026-09-01'
type: review-queue
topics_count: 5
---

# Review Queue - 2026-09-01

## Summary
- **Topics due:** 5
- **Estimated time:** 15 minutes
- **Priority order:** By retrievability (lowest first)

## Queue

### 1. [[T05-Constitutional-Amendments]] 🔴
- **Mastery:** 35.0%
- **Retrievability:** 45.2%
- **Last review:** 5 days ago
- **Reviews:** 3
- **Priority:** HIGH

### 2. [[T08-Medieval-History]] 🟡
- **Mastery:** 62.0%
- **Retrievability:** 71.5%
- **Last review:** 3 days ago
- **Reviews:** 7
- **Priority:** MEDIUM

### 3. [[T12-Ecology-Basics]] 🟢
- **Mastery:** 85.0%
- **Retrievability:** 89.2%
- **Last review:** 1 day ago
- **Reviews:** 12
- **Priority:** LOW

## Instructions
1. Start with highest priority (red)
2. Recall key concepts before revealing notes
3. Rate your performance: 1-4 (1=fail, 4=perfect)
4. System adjusts review schedule based on rating

## Completed
- [ ] T05-Constitutional-Amendments
- [ ] T08-Medieval-History
- [ ] T12-Ecology-Basics

## Session Log
| Topic | Rating | Notes |
|-------|--------|-------|
| | | |

---
_Generated: 2026-09-01 06:00 | Target retention: 90%_
```

### 3.3 Dashboard Template

```markdown
---
id: dashboard
created: '2026-09-01'
type: dashboard
---

# Progress Dashboard - UPSC Prelims

## Quick Stats

| Metric | Value |
|--------|-------|
| Total Topics | 100 |
| Mastered | 24 (24%) |
| In Progress | 56 |
| Not Started | 20 |
| Current Streak | 45 days 🔥 |
| Longest Streak | 67 days |

## Visual Progress

### Overall Mastery
🟢 ████████░░ 78% Complete

### Topic Status
```
Mastered:      ████████████████████████ 24
In Progress:   ████████████████████████████████████████████████████████ 56
Not Started:   ████████████████████ 20
```

## Mastery Distribution

```dataview
TABLE 
  mastery as "Mastery",
  status as "Status",
  next_review as "Next Review"
FROM "10-Active-Topics"
WHERE mastery > 0
SORT mastery DESC
LIMIT 10
```

## Reviews This Week

```dataview
TABLE 
  file.name as "Date",
  topics_count as "Topics"
FROM "20-Review-Queue"
WHERE file.ctime >= date(today) - dur(7 days)
SORT file.ctime DESC
```

## Achievements

```dataview
TABLE 
  achievement_id as "Achievement",
  unlocked_at as "Unlocked"
FROM "00-Dashboard/Achievements"
SORT unlocked_at DESC
```

### Unlocked
- ✅ First Step
- ✅ Week Warrior
- ✅ Month Master
- ✅ Knowledge Builder

### In Progress
- 🔲 Century Reviewer (72/100 reviews)
- 🔲 Torch Bearer (45/60 days)

## Next Actions

### Due Today
- [[Due-2026-09-01|Review Queue]] - 5 topics pending

### Recommended
- [[T15-Indian-Economy]] - Continue learning
- [[T05-Constitutional-Amendments]] - Needs review

### Strengthen Weak Areas
- [[T08-Medieval-History]] - Mastery at 62%
- [[T22-Environment]] - Mastery at 58%

## Weekly Goal Progress

| Goal | Target | Current | Progress |
|------|--------|---------|----------|
| New topics | 5 | 3 | 60% |
| Reviews | 35 | 28 | 80% |
| Practice sessions | 7 | 5 | 71% |

---
_Last updated: 2026-09-01 08:00_
```

---

## 4. Frontmatter Schemas

### 4.1 Topic Note Frontmatter

```yaml
---
id: T01-topic-slug          # Required - Unique identifier
created: '2026-09-01'        # Required - ISO date
updated: '2026-09-01T14:30:00'  # Required - ISO datetime
mastery: 0.45               # Required - Float 0.0-1.0
next_review: '2026-09-05'   # Required - ISO date
status: in_progress         # Required - pending|in_progress|mastered
difficulty: 5.2             # Optional - Float 1-10
stability: 12.5           # Optional - Days (integer)
related:                   # Optional - List of wikilinks
  - '[[T00-prerequisite]]'
  - '[[T05-related]]'
sources:                   # Optional - List of URLs
  - 'https://source.com'
tags:                      # Optional - List of strings
  - topic
  - active
---
```

### 4.2 Review Queue Frontmatter

```yaml
---
id: review-2026-09-01      # Required - Unique identifier
created: '2026-09-01'       # Required - ISO date
type: review-queue          # Required - Always "review-queue"
topics_count: 5            # Required - Number of topics
estimated_time: 15         # Optional - Minutes
priority_order: retrievability  # Optional - Ordering method
---
```

### 4.3 Achievement Frontmatter

```yaml
---
id: achievement-first-topic
achievement_id: first_topic
name: First Step
description: Complete your first topic
difficulty: easy
icon:🎯
unlocked_at: '2026-09-01T10:30:00'
---
```

---

## 5. Dataview Queries

### 5.1 Topic Queries

**All Active Topics Sorted by Mastery**
```dataview
TABLE 
  mastery as "Mastery",
  status as "Status",
  next_review as "Next Review"
FROM "10-Active-Topics"
WHERE mastery > 0
SORT mastery DESC
```

**Topics Due for Review**
```dataview
TABLE 
  file.name as "Topic",
  mastery as "Mastery",
  next_review as "Due"
FROM "10-Active-Topics"
WHERE next_review <= date(today)
SORT next_review ASC
```

**Weak Topics (Mastery < 50%)**
```dataview
LIST
FROM "10-Active-Topics"
WHERE mastery < 0.5
SORT mastery ASC
```

### 5.2 Progress Queries

**Topics Mastered This Month**
```dataview
TABLE 
  file.name as "Topic",
  file.mtime as "Mastered Date"
FROM "30-Completed-Topics"
WHERE file.mtime >= date(today) - dur(30 days)
SORT file.mtime DESC
```

**Learning Velocity**
```dataview
TABLE 
  length(rows) as "Topics Updated"
FROM "10-Active-Topics"
WHERE file.mtime >= date(today) - dur(7 days)
GROUP BY true
```

### 5.3 Review Queries

**Review Calendar**
```dataview
CALENDAR file.ctime
FROM "20-Review-Queue"
```

**Average Reviews Per Day**
```dataview
TABLE 
  length(rows) as "Days",
  length(filter(rows, (r) => true)) as "Reviews"
FROM "20-Review-Queue"
GROUP BY true
```

---

## 6. Plugin Configuration

### 6.1 Required Plugins

| Plugin | Purpose | Configuration |
|--------|---------|---------------|
| Dataview | Dynamic queries | Enable JavaScript queries |
| Graph Analysis | Knowledge graph | Default settings |
| Calendar | Review calendar | Show 20-Review-Queue |

### 6.2 Dataview Settings

```json
{
  "dataview": {
    "enableSql": false,
    "enableInlineQueries": true,
    "enableJavaScriptQueries": true,
    "refreshInterval": 2500,
    "defaultInheritance": {
      "query": "TABLE file.ctime"
    }
  }
}
```

### 6.3 Graph View Settings

```json
{
  "graph": {
    "group pull": true,
    "showAttachments": true,
    "showOrphans": false,
    "collapse": true,
    "colorGroups": [
      {
        "query": "path:10-Active-Topics",
        "color": "#4caf50"
      },
      {
        "query": "path:30-Completed-Topics",
        "color": "#2196f3"
      },
      {
        "query": "path:20-Review-Queue",
        "color": "#ff9800"
      }
    ]
  }
}
```

---

## 7. Backup Procedures

### 7.1 Automatic Backup

```python
def backup_vault(vault_path: Path) -> Path:
    """Create timestamped backup of vault."""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_dir = vault_path.parent / f"{vault_path.name}_backups"
    backup_dir.mkdir(exist_ok=True)
    
    backup_path = backup_dir / f"{vault_path.name}_{timestamp}"
    shutil.copytree(vault_path, backup_path)
    
    # Rotate: keep last 10 backups
    rotate_backups(backup_dir, keep=10)
    
    return backup_path
```

### 7.2 Manual Backup

```bash
# Create backup manually
cp -r ~/Obsidian/MIT-upsc-prelims ~/Obsidian/backups/MIT-upsc-prelims_$(date +%Y%m%d)

# Restore from backup
rm -rf ~/Obsidian/MIT-upsc-prelims
cp -r ~/Obsidian/backups/MIT-upsc-prelims_20260901 ~/Obsidian/MIT-upsc-prelims
```

---

*Document generated: September 1, 2026*
*Total pages: 25+*
