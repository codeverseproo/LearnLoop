# Obsidian Vault Setup Guide

## Default Vault Location

```
~/Obsidian/MIT-{goal-slug}/
```

## Directory Structure

```
MIT-{goal-slug}/
├── 00-Dashboard/
│   ├── Progress.md
│   └── Streak.md
├── 10-Active-Topics/
│   ├── T01-topic.md
│   └── T02-topic.md
├── 20-Review-Queue/
│   └── Due-2026-08-31.md
├── 30-Completed-Topics/
├── 40-Practice/
└── 50-Resources/
```

## Required Plugins

| Plugin | Purpose |
|--------|---------|
| Dataview | Dashboard visualizations |
| Spaced Repetition | Optional SRS integration |

## Note Format

All notes use this frontmatter:

```yaml
---
id: T01-topic-slug
created: '2026-08-31'
updated: '2026-08-31T12:00:00'
mastery: 0.72
next_review: '2026-09-07'
related:
  - '[[T00-prerequisite]]'
sources:
  - 'Source Name'
---
```

## Bidirectional Links

Use `[[topic-id]]` syntax for links:

```markdown
## Connections
- Builds on [[T00-prerequisite]] by adding...
- Relates to [[T05-related]] because...
```

## Creating a New Vault

1. Create directory: `mkdir -p ~/Obsidian/MIT-{goal-slug}`
2. Open in Obsidian
3. Install Dataview plugin (optional)
4. Run sqlite_init.py to create database
