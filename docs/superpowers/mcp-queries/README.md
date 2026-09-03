# SQLite MCP Query Templates

Query templates for MIT Learning Skill data operations via SQLite MCP.

## Organization

| File | Purpose |
|------|---------|
| schema.sql | Database initialization, table creation |
| fsrs.sql | FSRS-6 scheduling calculations |
| learning.sql | Learning session operations |
| review.sql | Review queue and session management |
| practice.sql | Practice session operations |
| research.sql | Research workflow storage |
| streak.sql | Streak tracking and achievements |
| backup.sql | Backup and restore operations |

## Usage

Each .sql file contains parameterized queries designed for SQLite MCP execution.

Parameters use `:param` syntax:
- `:goal_id` — Learning goal identifier
- `:topic_id` — Topic identifier  
- `:performance` — User performance rating (0.0-1.0)
- `:created_at` — Timestamp

Execute via Claude Code MCP tools:
```
mcp__sqlite__query({ database: "path/to/memory.db", query: "<SQL>" })
```

## Testing

Run verification queries after any change:
```bash
sqlite3 ~/.mit-learning/goals/test/memory.db < schema.sql
```
