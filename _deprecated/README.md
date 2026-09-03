# Deprecated Files

Archived Python scripts and tests. SQLite MCP replaces all functionality.

## Migration Map

| Deprecated | Replacement |
|------------|-------------|
| scripts/sqlite_init.py | docs/superpowers/mcp-queries/schema.sql |
| scripts/mastery_update.py | docs/superpowers/mcp-queries/fsrs.sql |
| scripts/fsrs_scheduler.py | SKILL.md review workflow |
| scripts/vault_manager.py | SKILL.md obsidian workflow |
| scripts/research_engine.py | docs/superpowers/mcp-queries/research.sql |
| scripts/validation.py | SKILL.md error handling |
| tests/*.py | docs/superpowers/tests/ |

## Restore (if needed)

```bash
git checkout HEAD~1 -- scripts/ tests/
```
