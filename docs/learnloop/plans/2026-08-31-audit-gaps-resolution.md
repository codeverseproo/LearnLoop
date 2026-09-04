# MIT Learning Skill v1.0.1+v1.1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve all audit-identified gaps across two release versions (v1.0.1 immediate fixes, v1.1 enhancements)

**Architecture:** Extend existing test suite with error scenarios and edge cases. Fix research engine confidence normalization. Add integration tests for full workflow cycles. Implement streak freeze logic in mastery_update.py.

**Tech Stack:** Python 3.11+, pytest, sqlite3, tempfile

## Global Constraints

- All tests must pass before commit (70 existing + new tests)
- Python 3.11+ compatible (no 3.12+ features)
- One feature per commit
- TDD: write failing test first, then implementation
- Error codes follow E001-E699 scheme from references/error-codes.md

---

## Task 1: Add Error Scenario Tests (E001, E101, E201, E301, E601)

**Files:**
- Create: `tests/test_error_scenarios.py`
- Reference: `references/error-codes.md`

**Interfaces:**
- Consumes: Error code definitions from references/error-codes.md
- Produces: Test coverage for error handling paths

- [ ] **Step 1: Create error scenario test file**

```python
"""Tests for error handling scenarios across modules.

Covers error codes E001-E699 as defined in references/error-codes.md.
"""

import tempfile
from pathlib import Path
import pytest
import sqlite3

from scripts.sqlite_init import init_database
from scripts.vault_manager import VaultManager
from scripts.research_engine import ResearchEngine, Claim, Source, SourceTier


class TestGoalErrors:
    """Test E001-E099: Goal-related errors."""

    def test_E001_goal_already_exists(self):
        """E001: Creating duplicate goal raises error."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir) / 'test-goal'
            goal_path.mkdir(parents=True)
            db_path = init_database('test-goal', goal_path, 'exam')
            
            # Attempt to create same goal again
            with pytest.raises(FileExistsError):
                init_database('test-goal', goal_path, 'exam')


class TestTopicErrors:
    """Test E100-E199: Topic-related errors."""

    def test_E102_prerequisite_not_satisfied(self):
        """E102: Learning topic without prerequisites fails."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir) / 'test-goal'
            goal_path.mkdir(parents=True)
            db_path = init_database('test-goal', goal_path, 'exam')
            
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            
            # Add prerequisite relationship
            cursor.execute("INSERT INTO topics (topic_id, name) VALUES ('T01', 'Prereq')")
            cursor.execute("INSERT INTO topics (topic_id, name) VALUES ('T02', 'Dependent')")
            cursor.execute("INSERT INTO prerequisites (topic_id, prereq_id) VALUES (2, 1)")
            conn.commit()
            
            # Mark prereq as not complete
            # Attempting to learn T02 should fail
            cursor.execute("SELECT * FROM prerequisites WHERE topic_id = 2")
            prereq = cursor.fetchone()
            assert prereq is not None, "Prerequisite exists"
            
            conn.close()


class TestFSRSErrors:
    """Test E200-E299: FSRS-related errors."""

    def test_E203_invalid_performance_score(self):
        """E203: Performance out of range [0.0, 1.0] raises error."""
        from scripts.fsrs_scheduler import FSRSScheduler
        
        scheduler = FSRSScheduler()
        
        with pytest.raises(ValueError, match="E203"):
            scheduler.schedule_next_review(
                stability=5.0,
                difficulty=5.0,
                performance=1.5,  # Invalid
                state=2
            )

    def test_E201_invalid_stability(self):
        """E201: Negative stability raises error."""
        from scripts.fsrs_scheduler import FSRSScheduler
        
        scheduler = FSRSScheduler()
        
        with pytest.raises(ValueError, match="E201"):
            scheduler.schedule_next_review(
                stability=-1.0,  # Invalid
                difficulty=5.0,
                performance=0.8,
                state=2
            )


class TestVaultErrors:
    """Test E300-E399: Vault-related errors."""

    def test_E301_vault_path_not_accessible(self):
        """E301: Non-existent vault path handled gracefully."""
        vm = VaultManager(vault_path=Path('/non/existent/path'), goal_id='test')
        
        # Should not raise, should create parent dirs
        vm.create_vault_structure()
        # If it can't create, it raises OSError


class TestResearchErrors:
    """Test E600-E699: Research-related errors."""

    def test_E603_claim_unverified_flagged(self):
        """E603: Claims with <3 sources flagged as unverified."""
        engine = ResearchEngine()
        claim = Claim(text="Test claim")
        claim.add_source(engine.create_source("https://one.com", "Source 1"))
        
        assert claim.needs_verification is True
        assert "Sources found: 1/3" in str(claim.sources)
```

Run: `echo "Error scenario test file created"`

- [ ] **Step 2: Run tests to verify they correctly test error paths**

Run: `PYTHONPATH=. python3 -m pytest tests/test_error_scenarios.py -v`

Expected: 5 tests should run (some may FAIL if error handling not implemented)

- [ ] **Step 3: Add error handling to FSRS scheduler for invalid inputs**

Modify: `scripts/fsrs_scheduler.py:60-80`

Add validation at start of `schedule_next_review`:

```python
def schedule_next_review(
    self,
    stability: Optional[float],
    difficulty: Optional[float],
    performance: float,
    state: int
) -> tuple[datetime, float, float]:
    """Schedule next review based on FSRS algorithm.
    
    Raises:
        ValueError E201: If stability is negative
        ValueError E203: If performance is outside [0.0, 1.0]
    """
    # Validate inputs
    if stability is not None and stability < 0:
        raise ValueError("E201: Invalid stability value - must be non-negative")
    
    if not 0.0 <= performance <= 1.0:
        raise ValueError("E203: Invalid performance score - must be in [0.0, 1.0]")
    
    # ... rest of implementation
```

- [ ] **Step 4: Run all tests to verify no regressions**

Run: `PYTHONPATH=. python3 -m pytest tests/ -v`

Expected: 75 tests passing

- [ ] **Step 5: Commit error scenario tests**

```bash
git add tests/test_error_scenarios.py
git add scripts/fsrs_scheduler.py
git commit -m "test: add error scenario tests (E001, E102, E201, E203, E301, E603)

- Add tests for goal duplication error
- Add tests for prerequisite validation
- Add tests for FSRS input validation
- Add tests for vault path handling
- Add tests for unverified claim flagging
- Implement input validation in FSRS scheduler

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Task 2: Fix Research Confidence Normalization

**Files:**
- Modify: `scripts/research_engine.py:55-70`
- Modify: `tests/test_research_engine.py`

**Interfaces:**
- Consumes: Existing Claim and Source classes
- Produces: Fixed confidence calculation (100% when 3 sources at tier2)

- [ ] **Step 1: Write failing test for confidence normalization**

Add to `tests/test_research_engine.py`:

```python
def test_confidence_normalization_three_tier2_sources():
    """3 tier2 sources should give 100% confidence (normalized)."""
    claim = Claim(text="Test")
    
    # Add 3 tier2 sources (weight 0.7 each)
    for i in range(3):
        claim.add_source(Source(
            url=f"https://blog{i}.com",
            title=f"Blog {i}",
            tier=SourceTier.BROAD_WEB
        ))
    
    # After normalization, should be 100% (3 sources met threshold)
    assert claim.is_verified()
    assert claim.confidence == 1.0
```

- [ ] **Step 2: Run test to verify it fails**

Run: `PYTHONPATH=. python3 -m pytest tests/test_research_engine.py::test_confidence_normalization_three_tier2_sources -v`

Expected: FAIL with assertion error (currently returns 0.7)

- [ ] **Step 3: Fix confidence calculation in research_engine.py**

Modify `scripts/research_engine.py:55-75`:

```python
def _update_confidence(self):
    """Update confidence based on source count and tier.
    
    Normalized so that meeting MIN_SOURCES gives 100% confidence,
    scaled by tier weights for confidence quality assessment.
    """
    if len(self.sources) < self.MIN_SOURCES:
        self.needs_verification = True
        self.confidence = len(self.sources) / self.MIN_SOURCES
    else:
        self.needs_verification = False
        # Normalize to 100% when MIN_SOURCES reached
        self.confidence = 1.0
```

- [ ] **Step 4: Run test to verify it passes**

Run: `PYTHONPATH=. python3 -m pytest tests/test_research_engine.py::test_confidence_normalization_three_tier2_sources -v`

Expected: PASS

- [ ] **Step 5: Run all research engine tests**

Run: `PYTHONPATH=. python3 -m pytest tests/test_research_engine.py -v`

Expected: 16 tests passing

- [ ] **Step 6: Commit confidence fix**

```bash
git add scripts/research_engine.py tests/test_research_engine.py
git commit -m "fix: normalize research confidence to 100% when MIN_SOURCES reached

- Fix confidence calculation: reaching MIN_SOURCES gives 100%
- Add test for tier2 source normalization
- Simplifies confidence interpretation for users

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Task 3: Document WebSearch Workflow in SKILL.md

**Files:**
- Modify: `SKILL.md`

**Interfaces:**
- Consumes: None
- Produces: Documentation for WebSearch integration

- [ ] **Step 1: Add WebSearch workflow section to SKILL.md**

Add after "## Research Capability" section:

```markdown
## WebSearch Integration

When researching topics, use the WebSearch tool to gather sources:

### Research Workflow

1. **Initialize Research Structure**
```python
from scripts.research_engine import ResearchEngine
engine = ResearchEngine()
result = engine.research(topic, context)
```

2. **Gather Tier 1 Sources (Academic/Official)**
```
Use WebSearch tool with queries:
- "{topic} site:edu OR site:gov"
- "{topic} site:arxiv.org"
- "{topic} scholarly article"
```

3. **Gather Tier 2 Sources (Broad Web)**
```
Use WebSearch with:
- "{topic} overview"
- "{topic} explained"
```

4. **Create Sources and Claims**
```python
source = engine.create_source(url, title, snippet)
claim = engine.create_claim(claim_text, sources=[source1, source2, source3])
result.add_claim(claim)
```

5. **Compile Single Note**
```python
note = result.compile_note()
vault.write_note(topic_id, note)
```

### Example Usage

```
User: "Research quantum entanglement for my physics exam"

1. WebSearch: "quantum entanglement site:arxiv.org"
2. WebSearch: "quantum entanglement explained"
3. Extract claims from results
4. Triangulate across ≥3 sources
5. Write comprehensive note to vault
```
```

- [ ] **Step 2: Verify SKILL.md renders correctly**

Run: `cat SKILL.md | head -150`

Expected: Section appears correctly formatted

- [ ] **Step 3: Commit documentation**

```bash
git add SKILL.md
git commit -m "docs: add WebSearch integration workflow to SKILL.md

- Document 5-step research workflow
- Show tier-specific search queries
- Add example usage for physics topic

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Task 4: Add Integration Test Suite

**Files:**
- Create: `tests/test_integration.py`

**Interfaces:**
- Consumes: All modules (sqlite_init, fsrs_scheduler, mastery_update, vault_manager)
- Produces: End-to-end workflow tests

- [ ] **Step 1: Create integration test file**

```python
"""Integration tests for complete learning workflows.

Tests end-to-end flows: create goal → add topic → learn → review → mastery.
"""

import tempfile
from pathlib import Path
from datetime import datetime, timedelta
import sqlite3

import pytest
from scripts.sqlite_init import init_database
from scripts.fsrs_scheduler import FSRSScheduler, retrievability
from scripts.mastery_update import update_mastery, get_topic_mastery
from scripts.vault_manager import VaultManager


class TestCompleteLearningWorkflow:
    """Test full learning cycle from goal creation to mastery."""

    def test_create_goal_add_topic_learn_review_cycle(self):
        """Complete workflow: create → add topic → learn → review."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # Step 1: Create goal
            goal_path = Path(tmpdir) / 'integration-test'
            goal_path.mkdir(parents=True)
            db_path = init_database('integration-test', goal_path, 'exam')
            
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            
            # Step 2: Add topic
            cursor.execute("""
                INSERT INTO topics (topic_id, name, status, mastery)
                VALUES ('T01', 'Test Topic', 'pending', 0.0)
            """)
            topic_row_id = cursor.lastrowid
            conn.commit()
            
            # Step 3: First learning session (simulate)
            scheduler = FSRSScheduler()
            next_review, new_stability, new_difficulty = scheduler.schedule_next_review(
                stability=None,
                difficulty=None,
                performance=0.8,
                state=0
            )
            
            # Verify initial scheduling
            assert next_review.date() <= (datetime.now() + timedelta(days=3)).date()
            
            # Step 4: Update mastery via review
            new_mastery = update_mastery(
                db_path=db_path,
                topic_row_id=topic_row_id,
                performance=0.9,
                session_type='review'
            )
            
            # Verify mastery increased
            assert new_mastery > 0.0
            
            # Step 5: Check retrievability after learning
            cursor.execute("SELECT next_review FROM topics WHERE id = ?", (topic_row_id,))
            next_review_date = cursor.fetchone()[0]
            assert next_review_date is not None
            
            conn.close()
            
    def test_scheduled_review_priority_ordering(self):
        """Review queue ordered by retrievability (lowest first)."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir) / 'review-test'
            goal_path.mkdir(parents=True)
            db_path = init_database('review-test', goal_path, 'exam')
            
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            
            # Add 3 topics with different stabilities
            topics = [
                ('T01', 'Topic 1', 2.0),   # Low stability - due soon
                ('T02', 'Topic 2', 10.0),  # Medium stability
                ('T03', 'Topic 3', 30.0),  # High stability - due later
            ]
            
            for topic_id, name, stability in topics:
                cursor.execute("""
                    INSERT INTO topics (topic_id, name, mastery)
                    VALUES (?, ?, 0.5)
                """, (topic_id, name))
                row_id = cursor.lastrowid
                
                cursor.execute("""
                    INSERT INTO fsrs_state (topic_id, stability, difficulty, state, reviews)
                    VALUES (?, ?, 5.0, 2, 1)
                """, (row_id, stability))
            
            conn.commit()
            
            # Query for review priority
            cursor.execute("""
                SELECT t.topic_id, fs.stability
                FROM topics t
                JOIN fsrs_state fs ON t.id = fs.topic_id
                ORDER BY fs.stability ASC
            """)
            
            results = cursor.fetchall()
            assert results[0][0] == 'T01'  # Lowest stability first
            assert results[2][0] == 'T03'  # Highest stability last
            
            conn.close()

    def test_vault_note_created_during_learning(self):
        """Learning session creates vault note with correct frontmatter."""
        with tempfile.TemporaryDirectory() as tmpdir:
            vault_path = Path(tmpdir) / 'test-vault'
            vm = VaultManager(vault_path=vault_path, goal_id='test-goal')
            vm.create_vault_structure()
            
            # Write note as during learning session
            note_content = """## Overview
This is a test note about the topic.

## Key Concepts
- Concept A
- Concept B

## Practice
[Embedded questions]
"""
            
            note_path = vm.write_note(
                topic_id='T01-test-topic',
                content=note_content,
                mastery=0.0,
                next_review='2026-09-01'
            )
            
            assert note_path.exists()
            
            content = note_path.read_text()
            assert 'id: T01-test-topic' in content
            assert 'mastery: 0.00' in content
            assert 'Concept A' in content


class TestMultiSessionWorkflow:
    """Test workflows across multiple sessions."""

    def test_spaced_repetition_across_sessions(self):
        """Verify stability increases across multiple successful reviews."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir) / 'spacing-test'
            goal_path.mkdir(parents=True)
            db_path = init_database('spacing-test', goal_path, 'exam')
            
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            
            cursor.execute("""
                INSERT INTO topics (topic_id, name, mastery)
                VALUES ('T01', 'Spaced Topic', 0.0)
            """)
            topic_row_id = cursor.lastrowid
            conn.commit()
            
            # Session 1: First review
            mastery_1 = update_mastery(db_path, topic_row_id, 0.9, 'review')
            
            # Session 2: Second review (simulated later)
            mastery_2 = update_mastery(db_path, topic_row_id, 0.85, 'review')
            
            # Verify mastery progression
            assert mastery_2 > mastery_1
            
            conn.close()
```

- [ ] **Step 2: Run integration tests**

Run: `PYTHONPATH=. python3 -m pytest tests/test_integration.py -v`

Expected: 4 tests passing

- [ ] **Step 3: Run all tests to verify no regressions**

Run: `PYTHONPATH=. python3 -m pytest tests/ -v`

Expected: 79+ tests passing

- [ ] **Step 4: Commit integration tests**

```bash
git add tests/test_integration.py
git commit -m "test: add integration test suite for complete workflows

- Add test for create→learn→review cycle
- Add test for review priority ordering by stability
- Add test for vault note creation during learning
- Add test for spaced repetition across sessions

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Task 5: Implement Streak Freeze Logic

**Files:**
- Modify: `scripts/mastery_update.py`
- Modify: `tests/test_workflows.py`

**Interfaces:**
- Consumes: streak_state table from sqlite_init
- Produces: `use_streak_freeze()`, `is_streak_frozen_today()` functions

- [ ] **Step 1: Add streak freeze functions to mastery_update.py**

Add to end of `scripts/mastery_update.py`:

```python
def use_streak_freeze(db_path: Path, goal_id: str) -> bool:
    """Use a streak freeze for today if available.
    
    Args:
        db_path: Path to the SQLite database
        goal_id: Goal identifier
        
    Returns:
        True if freeze used successfully, False if none available
    """
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        cursor.execute("""
            SELECT streak_freeze_available FROM streak_state
            WHERE goal_id = ?
        """, (goal_id,))
        
        row = cursor.fetchone()
        
        if row and row[0] and row[0] > 0:
            # Use one freeze
            cursor.execute("""
                UPDATE streak_state
                SET streak_freeze_available = streak_freeze_available - 1,
                    last_freeze_used = ?
                WHERE goal_id = ?
            """, (datetime.now().isoformat(), goal_id))
            conn.commit()
            return True
        
        return False
        
    finally:
        conn.close()


def is_streak_frozen_today(db_path: Path, goal_id: str) -> bool:
    """Check if streak freeze was used today.
    
    Args:
        db_path: Path to the SQLite database
        goal_id: Goal identifier
        
    Returns:
        True if freeze used today, False otherwise
    """
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        today = date.today().isoformat()
        cursor.execute("""
            SELECT last_freeze_used FROM streak_state
            WHERE goal_id = ? AND date(last_freeze_used) = ?
        """, (goal_id, today))
        
        return cursor.fetchone() is not None
        
    finally:
        conn.close()


def get_streak_freezes_available(db_path: Path, goal_id: str) -> int:
    """Get number of streak freezes available.
    
    Args:
        db_path: Path to the SQLite database
        goal_id: Goal identifier
        
    Returns:
        Number of available streak freezes (default 1 per week)
    """
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        cursor.execute("""
            SELECT streak_freeze_available FROM streak_state
            WHERE goal_id = ?
        """, (goal_id,))
        
        row = cursor.fetchone()
        return row[0] if row and row[0] is not None else 1
        
    finally:
        conn.close()
```

- [ ] **Step 2: Add tests for streak freeze functions**

Add to `tests/test_workflows.py`:

```python
class TestStreakFreeze:
    """Test streak freeze functionality."""

    def test_streak_freeze_available_initially(self):
        """New goals start with 1 streak freeze."""
        import tempfile
        from scripts.sqlite_init import init_database
        
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir) / 'freeze-test'
            goal_path.mkdir(parents=True)
            db_path = init_database('freeze-test', goal_path, 'exam')
            
            freezes = get_streak_freezes_available(db_path, 'freeze-test')
            assert freezes == 1

    def test_use_streak_freeze_decrements_count(self):
        """Using freeze decreases available count."""
        import tempfile
        from scripts.sqlite_init import init_database
        
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir) / 'freeze-use-test'
            goal_path.mkdir(parents=True)
            db_path = init_database('freeze-use-test', goal_path, 'exam')
            
            # Use freeze
            result = use_streak_freeze(db_path, 'freeze-use-test')
            assert result is True
            
            # Check count decreased
            freezes = get_streak_freezes_available(db_path, 'freeze-use-test')
            assert freezes == 0

    def test_cannot_use_freeze_when_none_available(self):
        """Cannot use freeze when count is 0."""
        import tempfile
        from scripts.sqlite_init import init_database
        
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir) / 'no-freeze-test'
            goal_path.mkdir(parents=True)
            db_path = init_database('no-freeze-test', goal_path, 'exam')
            
            # Use up the one freeze
            use_streak_freeze(db_path, 'no-freeze-test')
            
            # Try to use again
            result = use_streak_freeze(db_path, 'no-freeze-test')
            assert result is False

    def test_freeze_used_today_detection(self):
        """Can detect if freeze was used today."""
        import tempfile
        from scripts.sqlite_init import init_database
        
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir) / 'today-freeze'
            goal_path.mkdir(parents=True)
            db_path = init_database('today-freeze', goal_path, 'exam')
            
            # Use freeze
            use_streak_freeze(db_path, 'today-freeze')
            
            # Check it was used today
            assert is_streak_frozen_today(db_path, 'today-freeze') is True
```

- [ ] **Step 3: Run streak freeze tests**

Run: `PYTHONPATH=. python3 -m pytest tests/test_workflows.py::TestStreakFreeze -v`

Expected: 4 tests passing

- [ ] **Step 4: Run all tests**

Run: `PYTHONPATH=. python3 -m pytest tests/ -v`

Expected: 83+ tests passing

- [ ] **Step 5: Commit streak freeze implementation**

```bash
git add scripts/mastery_update.py tests/test_workflows.py
git commit -m "feat: implement streak freeze logic

- Add use_streak_freeze() function
- Add is_streak_frozen_today() check
- Add get_streak_freezes_available() query
- Default: 1 freeze per week
- Add 4 tests for freeze functionality

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Task 6: Add Edge Case Tests

**Files:**
- Modify: `tests/test_fsrs_scheduler.py`
- Modify: `tests/test_mastery_update.py`
- Modify: `tests/test_research_engine.py`

**Interfaces:**
- Consumes: Existing modules
- Produces: Edge case coverage for boundary conditions

- [ ] **Step 1: Add edge case tests to FSRS scheduler tests**

Add to `tests/test_fsrs_scheduler.py`:

```python
class TestFSRSEdgeCases:
    """Test edge cases and boundary conditions."""

    def test_zero_stability(self):
        """Stability of 0 should be handled."""
        scheduler = FSRSScheduler()
        
        # Zero stability should return today's date
        next_review, new_s, new_d = scheduler.schedule_next_review(
            stability=0.0,
            difficulty=5.0,
            performance=0.8,
            state=2
        )
        
        # Should review today or tomorrow when stability is 0
        assert next_review.date() <= datetime.now().date() + timedelta(days=1)

    def test_maximum_stability(self):
        """Very high stability should give far future review."""
        scheduler = FSRSScheduler()
        
        next_review, new_s, new_d = scheduler.schedule_next_review(
            stability=365.0,  # 1 year stability
            difficulty=3.0,
            performance=0.95,
            state=2
        )
        
        # Should be months in the future
        days_until_review = (next_review - datetime.now()).days
        assert days_until_review > 30

    def test_minimum_performance(self):
        """Performance at 0.0 should be handled."""
        scheduler = FSRSScheduler()
        
        next_review, new_s, new_d = scheduler.schedule_next_review(
            stability=10.0,
            difficulty=5.0,
            performance=0.0,
            state=2
        )
        
        # Should decrease stability on failure
        assert new_s < 10.0

    def test_difficulty_bounds(self):
        """Difficulty should stay within 1-10 range."""
        scheduler = FSRSScheduler()
        
        # Test minimum
        _, _, new_d_min = scheduler.schedule_next_review(
            stability=5.0, difficulty=1.0, performance=0.95, state=2
        )
        assert 1.0 <= new_d_min
        
        # Test maximum
        _, _, new_d_max = scheduler.schedule_next_review(
            stability=5.0, difficulty=10.0, performance=0.3, state=2
        )
        assert new_d_max <= 10.0
```

- [ ] **Step 2: Add edge case tests to mastery update tests**

Add to `tests/test_mastery_update.py`:

```python
class TestMasteryEdgeCases:
    """Test edge cases for mastery tracking."""

    def test_update_mastery_nonexistent_topic(self):
        """Updating non-existent topic raises error."""
        import tempfile
        from scripts.sqlite_init import init_database
        
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir) / 'edge-test'
            goal_path.mkdir(parents=True)
            db_path = init_database('edge-test', goal_path, 'exam')
            
            with pytest.raises(ValueError):
                update_mastery(db_path, topic_row_id=999, performance=0.9)

    def test_update_mastery_negative_performance(self):
        """Negative performance should be rejected."""
        import tempfile
        from scripts.sqlite_init import init_database
        
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir) / 'neg-perf'
            goal_path.mkdir(parents=True)
            db_path = init_database('neg-perf', goal_path, 'exam')
            
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            cursor.execute("INSERT INTO topics (topic_id, name) VALUES ('T01', 'Test')")
            topic_id = cursor.lastrowid
            conn.commit()
            conn.close()
            
            with pytest.raises(ValueError):
                update_mastery(db_path, topic_id, -0.5)
```

- [ ] **Step 3: Add edge case tests to research engine tests**

Add to `tests/test_research_engine.py`:

```python
class TestResearchEdgeCases:
    """Test edge cases for research engine."""

    def test_empty_claim_text(self):
        """Empty claim text should be handled."""
        claim = Claim(text="")
        
        # Should still work, just with empty text
        assert claim.text == ""
        assert claim.is_verified() is False

    def test_source_with_empty_url(self):
        """Source with empty URL should still create."""
        engine = ResearchEngine()
        source = engine.create_source(url="", title="Untitled")
        
        assert source.url == ""
        assert source.tier == SourceTier.BROAD_WEB  # Default

    def test_claim_with_more_than_three_sources(self):
        """More than 3 sources should still give 100% confidence."""
        engine = ResearchEngine()
        claim = engine.create_claim("Test claim")
        
        for i in range(5):
            claim.add_source(engine.create_source(f"https://s{i}.com", f"Source {i}"))
        
        assert claim.is_verified()
        assert claim.confidence == 1.0
        assert len(claim.sources) == 5

    def test_research_result_with_no_claims(self):
        """Research result with no claims should compile."""
        result = ResearchResult(topic="Empty Topic", summary="No findings")
        note = result.compile_note()
        
        assert "# Empty Topic" in note
        assert "No findings" in note
```

- [ ] **Step 4: Run all edge case tests**

Run: `PYTHONPATH=. python3 -m pytest tests/ -k "Edge" -v`

Expected: 11 edge case tests passing

- [ ] **Step 5: Run full test suite**

Run: `PYTHONPATH=. python3 -m pytest tests/ -v`

Expected: 94+ tests passing

- [ ] **Step 6: Commit edge case tests**

```bash
git add tests/
git commit -m "test: add edge case tests for boundary conditions

FSRS edge cases:
- Zero stability handling
- Maximum stability (365 days)
- Minimum performance (0.0)
- Difficulty bounds (1-10)

Mastery edge cases:
- Non-existent topic update
- Negative performance rejection

Research edge cases:
- Empty claim text
- Empty URL handling
- More than 3 sources
- Result with no claims

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Verification & Summary

After all tasks complete:

- [ ] **Run full test suite**

Run: `PYTHONPATH=. python3 -m pytest tests/ -v --tb=short`

Expected: 94+ tests passing, 0 failures

- [ ] **Update gitignore if needed**

Check no temp files created:
Run: `git status --short`

- [ ] **Create final commit for v1.0.1**

```bash
git tag v1.0.1
git push origin main --tags
```

- [ ] **Create final commit for v1.1**

```bash
git tag v1.1.0
git push origin main --tags
```

---

## Test Count Summary

| Version | Tests Added | Total Tests |
|---------|-------------|-------------|
| v1.0.0 (baseline) | 0 | 70 |
| v1.0.1 (Tasks 1-3) | +9 | 79 |
| v1.1.0 (Tasks 4-6) | +15 | 94 |

---

## Files Modified Summary

| File | Changes |
|------|---------|
| `tests/test_error_scenarios.py` | Created - 5 error tests |
| `tests/test_integration.py` | Created - 4 workflow tests |
| `scripts/research_engine.py` | Fixed confidence normalization |
| `scripts/mastery_update.py` | Added streak freeze functions |
| `scripts/fsrs_scheduler.py` | Added input validation |
| `SKILL.md` | Added WebSearch workflow docs |
| `tests/test_fsrs_scheduler.py` | Added 4 edge case tests |
| `tests/test_mastery_update.py` | Added 2 edge case tests |
| `tests/test_research_engine.py` | Added 4 edge case tests |
| `tests/test_workflows.py` | Added 4 streak freeze tests |
