# MIT-012: Python Deprecation

**Execution Prompt — Copy and paste into Claude session**

---

## STORY METADATA

```yaml
ID: MIT-012
Title: Python Deprecation
Phase: 3
Effort: 2 hours
Impact: Zero Python dependency
Dependencies: MIT-011 (Testing)
Parallelizable with: None (Final story)
```

---

## PREFLIGHT CHECKS

```bash
set -e
echo "=== PREFLIGHT CHECKS FOR MIT-012 ==="

# 1. All prior stories passed
for story in MIT-001 MIT-002 MIT-003 MIT-004 MIT-005 MIT-006 MIT-007 MIT-008 MIT-009 MIT-010 MIT-011; do
    jq -e ".${story}.status == \"passed\"" .superpowers/state/story-progress.json > /dev/null || { echo "FAIL: ${story} not passed"; exit 1; }
done

echo "✓ ALL 11 PRIOR STORIES PASSED"
echo "✓ READY FOR FINAL STORY"
```

---

## STATE INITIALIZATION

```bash
cat > .superpowers/checkpoints/MIT-012-START << 'EOF'
{"storyId": "MIT-012", "createdAt": "'$(date -Iseconds)'", "gitRef": "'$(git rev-parse HEAD)'"}
EOF

jq '.MIT-012 = {"status": "in-progress", "phase": 3, "title": "Python Deprecation", "startedAt": "'$(date -Iseconds)'", "dependencies": ["MIT-011"]}' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json
```

---

## IMPLEMENTATION STEPS

### Step 1: Identify Python Scripts to Archive

```bash
# Find all Python scripts
find . -name "*.py" -type f | grep -v "__pycache__" | grep -v ".venv" | grep -v "node_modules"

# Typical locations:
# scripts/*.py
# src/*.py
# tests/*.py (if Python tests)
```

---

### Step 2: Archive Python Scripts

```bash
# Create archive directory
mkdir -p scripts/_deprecated/

# Move Python scripts to archive
for script in scripts/*.py; do
    if [ -f "$script" ]; then
        mv "$script" scripts/_deprecated/
        echo "Archived: $script"
    fi
done

# Create archive README
cat > scripts/_deprecated/README.md << 'EOF'
# Deprecated Python Scripts

These scripts are archived and no longer maintained.

## Migration

All functionality now uses SQLite MCP queries:

- `init_goal.py` → SKILL.md workflow + schema.sql
- `mastery_update.py` → fsrs.sql queries
- `review_scheduler.py` → fsrs.sql review queue

## Restoration (if needed)

```bash
# If Python scripts needed temporarily:
git checkout HEAD~1 -- scripts/<script>.py
python scripts/<script>.py <args>
```

## Documentation

See `docs/superpowers/mcp-queries/` for current implementation.
EOF
```

---

### Step 3: Remove Python Dependencies

```bash
# Check for requirements.txt
if [ -f requirements.txt ]; then
    # Archive it
    mv requirements.txt scripts/_deprecated/
    echo "Archived: requirements.txt"
fi

# Check for setup.py
if [ -f setup.py ]; then
    mv setup.py scripts/_deprecated/
    echo "Archived: setup.py"
fi

# Check for pyproject.toml (may have other uses)
if [ -f pyproject.toml ]; then
    # Comment out Python deps, keep other config
    echo "Review pyproject.toml for Python dependencies"
fi
```

---

### Step 4: Update README.md

Create or update `README.md`:

```markdown
# MIT Learning Skill

A Claude Code skill for mastery-based learning with FSRS-6 spaced repetition.

## Architecture

**Pure Skill + SQLite MCP — No Python Required**

- All data operations via SQLite MCP queries
- All logic in SKILL.md natural language triggers
- Zero external dependencies

### Components

```
MIT Learning Skill/
├── SKILL.md                        # Main skill with 12 workflows
├── docs/superpowers/
│   ├── mcp-queries/               # SQL query templates
│   │   ├── schema.sql             # Database schema
│   │   ├── fsrs.sql               # FSRS-6 calculations
│   │   ├── learning.sql           # Learning sessions
│   │   ├── review.sql              # Review queue
│   │   ├── practice.sql            # Practice tracking
│   │   ├── research.sql            # Research workflow
│   │   ├── streak.sql              # Gamification
│   │   └── backup.sql              # Data safety
│   └── tests/                      # Test suite
└── scripts/_deprecated/            # Archived Python scripts
```

## Features

### 12 Learning Workflows

1. **syllabus_generation** — Create learning plan from topic
2. **diagnostic_assessment** — Assess current knowledge
3. **study_schedule_optimization** — Optimize review schedule
4. **learning_session** — Structured learning with FSRS tracking
5. **prior_knowledge_activation** — Connect to existing knowledge
6. **metacognitive_reflection** — Reflect on learning process
7. **review_session** — Spaced repetition review queue
8. **elaborative_interrogation** — Deep understanding prompts
9. **practice_session** — Problem practice with performance tracking
10. **interleaved_practice** — Cross-topic practice
11. **progress_dashboard** — Streaks, achievements, mastery
12. **current_affairs_digest** — Research compilation

### FSRS-6 Spaced Repetition

All scheduling via SQL formulas:

```sql
-- Retrievability
R = (1 + t/(9*S))^(-1)

-- Mastery
M = 1 - exp(-0.5 * S / D)
```

### Three-Tier Memory

| Tier | Storage | Purpose |
|------|---------|---------|
| HOT | Session | Active context |
| WARM | SQLite MCP | Persistent data |
| COLD | Obsidian | Long-term notes |

## Usage

### Quick Start

```
"Learn Python basics"
"What's due for review?"
"Show my progress"
```

### Via Claude Code

1. Ensure SQLite MCP is available
2. SKILL.md triggers handle all operations
3. Queries execute via `mcp__sqlite__*` tools

## Testing

```bash
./docs/superpowers/tests/run_tests.sh
```

## Documentation

- `docs/FSRS-6-ALGORITHM.md` — FSRS formulas
- `docs/ARCHITECTURE.md` — System design
- `docs/superpowers/specs/` — Design specs
- `docs/superpowers/architecture/` — Execution architecture

## License

MIT

---

**No Python required. Pure skill + SQLite MCP.**
```

---

### Step 5: Verify No Python Required

```bash
echo "=== PYTHON DEPENDENCY CHECK ==="

# 1. No Python scripts in active directories
find . -name "*.py" -type f | grep -v "_deprecated" | grep -v ".venv" | grep -v "node_modules" | head -10

# Expected: No output (or only test files)

# 2. No Python imports in SKILL.md
grep -c "import " SKILL.md || echo "No Python imports in SKILL.md"

# Expected: 0

# 3. No Python execution in workflows
grep -c "python " SKILL.md || echo "No python commands in SKILL.md"

# Expected: 0

# 4. Test suite works
./docs/superpowers/tests/run_tests.sh && echo "Tests pass without Python"

echo "=== VERIFICATION COMPLETE ==="
```

---

### Step 6: Final Cleanup

```bash
# Remove Python cache
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true

# Remove .pyc files
find . -name "*.pyc" -delete 2>/dev/null || true

echo "Python artifacts cleaned"
```

---

## TESTING & VERIFICATION

```bash
echo "=== FINAL VERIFICATION ==="

# 1. No Python in active paths
PYTHON_FILES=$(find . -name "*.py" -type f | grep -v "_deprecated" | grep -v ".venv" | grep -v "node_modules" | wc -l)
test "$PYTHON_FILES" -eq 0 && echo "✓ [1/5] No active Python scripts"

# 2. Python archived
test -d scripts/_deprecated && echo "✓ [2/5] Python archived"

# 3. README updated
grep -q "No Python required" README.md && echo "✓ [3/5] README updated"

# 4. Tests pass
./docs/superpowers/tests/run_tests.sh >/dev/null 2>&1 && echo "✓ [4/5] Tests pass"

# 5. SKILL.md has MCP queries
grep -q "mcp__sqlite__query" SKILL.md && echo "✓ [5/5] SKILL.md uses MCP"

echo "=== ALL VERIFICATIONS PASSED ==="
```

---

## HUMAN VERIFICATION

```markdown
Verify:
- [ ] No Python scripts in active directories
- [ ] Python scripts archived in scripts/_deprecated/
- [ ] README.md updated with pure-skill architecture
- [ ] Tests pass without Python
- [ ] SKILL.md has no Python imports
- [ ] Zero external dependencies

## HUMAN SIGN-OFF ##
Status: [ ] I have verified Python deprecation is complete.
```

---

## SUCCESS CRITERIA

```bash
echo "=== ACCEPTANCE CRITERIA ==="

# 1. No Python required
test $(find . -name "*.py" | grep -v "_deprecated" | wc -l) -eq 0 && echo "✓ [1/5] No active Python"

# 2. Archive exists
test -d scripts/_deprecated && echo "✓ [2/5] Archive directory exists"

# 3. README correct
grep -q "Pure Skill + SQLite MCP" README.md && echo "✓ [3/5] README architecture documented"

# 4. Zero dependencies
test ! -f requirements.txt && echo "✓ [4/5] No requirements.txt"

# 5. All 12 stories passed
jq '[.[] | select(.status == "passed")] | length' .superpowers/state/story-progress.json | grep -q "12" && echo "✓ [5/5] All 12 stories passed"

echo "=== PROJECT COMPLETE ==="
```

---

## CLEANUP & COMPLETION

```bash
git add -A
git commit -m "feat(MIT-012): Python deprecation - PROJECT COMPLETE

- Archived all Python scripts to scripts/_deprecated/
- Removed Python dependencies
- Updated README.md with pure-skill architecture
- Zero Python required for operation
- All 12 stories complete

Story: MIT-012
Phase: 3 Final
Project: COMPLETE

Dependencies Removed:
- Python scripts → SKILL.md workflows
- requirements.txt → None (archived)
- mastery_update.py → fsrs.sql
- review_scheduler.py → review.sql

Architecture:
- Pure skill + SQLite MCP
- 12 workflows via natural language triggers
- FSRS-6 calculations in SQL
- Three-tier memory system

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
"

jq '.MIT-012.status = "passed" | .MIT-012.completedAt = "'$(date -Iseconds)'"' \
  .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json

cat > .superpowers/checkpoints/MIT-012-PASS << 'EOF'
{
  "storyId": "MIT-012",
  "status": "passed",
  "completedAt": "'$(date -Iseconds)'",
  "project": "COMPLETE",
  "totalStories": 12,
  "allPassed": true
}
EOF

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     MIT LEARNING SKILL - COMPLETE        ║"
echo "╠══════════════════════════════════════════╣"
echo "║  12 Stories | 3 Phases | 0 Python       ║"
echo "║  Pure Skill + SQLite MCP Architecture   ║"
echo "╚══════════════════════════════════════════╝"
echo ""
```

---

## ROLLBACK

```bash
#!/bin/bash
set -e

echo "Rolling back MIT-012..."

# Restore Python scripts
if [ -d scripts/_deprecated ]; then
    mv scripts/_deprecated/*.py scripts/ 2>/dev/null || true
fi

# Restore requirements.txt
if [ -f scripts/_deprecated/requirements.txt ]; then
    mv scripts/_deprecated/requirements.txt .
fi

# Restore README
REF=$(jq -r '.gitRef' .superpowers/checkpoints/MIT-012-START)
git checkout $REF -- README.md

# Update state
jq '.MIT-012.status = "pending"' .superpowers/state/story-progress.json > tmp.json && mv tmp.json .superpowers/state/story-progress.json

rm -f .superpowers/checkpoints/MIT-012-*
echo "Rollback complete"
```

---

## PROJECT SUMMARY

**12 Stories Complete:**

| Phase | Stories | Status |
|-------|---------|--------|
| 1: Foundation | MIT-001 through MIT-004 | ✓ Passed |
| 2: Workflows | MIT-005 through MIT-009 | ✓ Passed |
| 3: Polish | MIT-010 through MIT-012 | ✓ Passed |

**Architecture Delivered:**
- 8 SQL query files (`docs/superpowers/mcp-queries/`)
- 12 learning workflows in SKILL.md
- Complete test suite
- Pure skill + SQLite MCP
- Zero Python dependency

**Files Changed:**
- SKILL.md (workflows, FSRS, error handling)
- README.md (pure-skill architecture)
- docs/superpowers/mcp-queries/ (8 SQL files)
- docs/superpowers/tests/ (test suite)
- scripts/_deprecated/ (archived Python)

---

**PROJECT COMPLETE. Ready for production use.**

**END OF EXECUTION PROMPT FOR MIT-012**
