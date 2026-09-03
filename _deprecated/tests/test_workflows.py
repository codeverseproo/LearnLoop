"""Integration tests for MIT Learning Skill workflows.

Tests complete workflows including review sessions, streak tracking,
and dashboard updates.
"""

import sqlite3
import tempfile
from pathlib import Path
import pytest
from scripts.sqlite_init import init_database
from scripts.mastery_update import (
    update_mastery, get_topic_mastery,
    use_streak_freeze, is_streak_frozen_today, get_streak_freezes_available
)
from scripts.vault_manager import VaultManager


class TestLearningSessionWorkflow:
    """Test learning session workflow."""

    @pytest.fixture
    def setup_goal(self):
        """Set up a goal with database and vault."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir) / "goals" / "learn-goal"
            goal_path.mkdir(parents=True)

            vault_path = goal_path / "vault"
            vault_path.mkdir(parents=True)

            db_path = init_database(
                goal_id="learn-goal",
                goal_path=goal_path,
                goal_type="exam"
            )

            # Add a topic for learning
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO topics (topic_id, name, mastery, status)
                VALUES ('T01', 'Introduction', 0.0, 'available')
            """)
            cursor.execute("""
                INSERT INTO fsrs_state (topic_id, stability, difficulty, state)
                VALUES (1, 2.5, 5.0, 0)
            """)
            conn.commit()
            conn.close()

            yield {"db_path": db_path, "vault_path": vault_path}

    def test_learning_session_updates_mastery(self, setup_goal):
        """Test that learning a topic updates mastery."""
        db_path = setup_goal["db_path"]

        # Simulate successful learning
        new_mastery = update_mastery(
            db_path=db_path,
            topic_row_id=1,
            performance=1.0
        )

        assert new_mastery > 0.0

        # Verify persistence
        mastery = get_topic_mastery(db_path, topic_row_id=1)
        assert mastery == new_mastery

    def test_learning_session_writes_note(self, setup_goal):
        """Test that learning creates a note in vault."""
        vault_path = setup_goal["vault_path"]

        manager = VaultManager(vault_path=vault_path, goal_id="learn-goal")
        manager.create_vault_structure()

        note_path = manager.write_note(
            topic_id="T01-introduction",
            content="# Introduction\n\nThis is the intro.",
            directory="10-Active-Topics"
        )

        assert note_path.exists()


class TestReviewSessionWorkflow:
    """Test review session workflow."""

    @pytest.fixture
    def setup_reviewables(self):
        """Set up topics for review."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir) / "goals" / "review-goal"
            goal_path.mkdir(parents=True)

            db_path = init_database(
                goal_id="review-goal",
                goal_path=goal_path,
                goal_type="exam"
            )

            # Add topic with some mastery
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()

            cursor.execute("""
                INSERT INTO topics (topic_id, name, mastery, status, next_review)
                VALUES ('T01', 'Review Topic', 0.5, 'in_progress', DATE('now'))
            """)
            cursor.execute("""
                INSERT INTO fsrs_state (topic_id, stability, difficulty, state, reviews)
                VALUES (1, 7.0, 5.0, 2, 3)
            """)
            conn.commit()
            conn.close()

            yield db_path

    def test_review_increases_stability_on_success(self, setup_reviewables):
        """Test that successful review increases stability."""
        db_path = setup_reviewables

        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT stability FROM fsrs_state WHERE topic_id = 1")
        old_stability = cursor.fetchone()[0]
        conn.close()

        update_mastery(db_path=db_path, topic_row_id=1, performance=1.0)

        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT stability FROM fsrs_state WHERE topic_id = 1")
        new_stability = cursor.fetchone()[0]
        conn.close()

        assert new_stability > old_stability

    def test_review_decreases_stability_on_failure(self, setup_reviewables):
        """Test that failed review decreases stability."""
        db_path = setup_reviewables

        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT stability FROM fsrs_state WHERE topic_id = 1")
        old_stability = cursor.fetchone()[0]
        conn.close()

        update_mastery(db_path=db_path, topic_row_id=1, performance=0.0)

        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT stability FROM fsrs_state WHERE topic_id = 1")
        new_stability = cursor.fetchone()[0]
        conn.close()

        assert new_stability < old_stability


class TestStreakSystem:
    """Test streak tracking."""

    def test_streak_table_structure(self):
        """Test that streak table has required columns."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir)
            db_path = init_database(goal_id="streak-test", goal_path=goal_path)

            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()

            # Check table exists with correct structure
            cursor.execute("PRAGMA table_info(streak_state)")
            columns = [row[1] for row in cursor.fetchall()]
            conn.close()

            assert 'current_streak' in columns
            assert 'streak_freeze_available' in columns
            assert 'longest_streak' in columns
            assert 'last_activity_date' in columns

    def test_streak_initializes_to_zero(self):
        """Test that new goals start with zero streak."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir)
            db_path = init_database(goal_id="streak-init-test", goal_path=goal_path)

            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()

            cursor.execute("""
                SELECT current_streak, longest_streak, streak_freeze_available
                FROM streak_state WHERE goal_id = 'streak-init-test'
            """)
            row = cursor.fetchone()
            conn.close()

            assert row[0] == 0  # current_streak
            assert row[1] == 0  # longest_streak
            assert row[2] == 1  # streak_freeze_available


class TestDashboardWorkflow:
    """Test dashboard generation."""

    def test_dashboard_updates_correctly(self):
        """Test that dashboard reflects current state."""
        with tempfile.TemporaryDirectory() as tmpdir:
            vault_path = Path(tmpdir) / "test-vault"
            vault_path.mkdir(parents=True)

            manager = VaultManager(vault_path=vault_path, goal_id="dashboard-test")
            manager.create_vault_structure()

            dashboard_data = {
                "total_topics": 20,
                "mastered": 5,
                "in_progress": 10,
                "current_streak": 7,
                "longest_streak": 14
            }

            manager.update_dashboard(dashboard_data)

            dashboard_path = vault_path / "00-Dashboard" / "Progress.md"
            content = dashboard_path.read_text()

            assert "20" in content  # total
            assert "7" in content  # streak

    def test_dashboard_shows_progress_percentages(self):
        """Test that dashboard shows mastery percentage."""
        with tempfile.TemporaryDirectory() as tmpdir:
            vault_path = Path(tmpdir) / "test-vault"
            vault_path.mkdir(parents=True)

            manager = VaultManager(vault_path=vault_path, goal_id="pct-test")
            manager.create_vault_structure()

            # 50% mastered
            manager.update_dashboard({
                "total_topics": 10,
                "mastered": 5,
                "in_progress": 3,
                "current_streak": 1,
                "longest_streak": 1
            })

            dashboard_path = vault_path / "00-Dashboard" / "Progress.md"
            content = dashboard_path.read_text()

            assert "50.0%" in content


class TestCompleteWorkflow:
    """Test end-to-end workflows."""

    @pytest.fixture
    def full_setup(self):
        """Set up complete learning environment."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir) / "goals" / "complete-goal"
            goal_path.mkdir(parents=True)

            vault_path = goal_path / "vault"
            vault_path.mkdir(parents=True)

            db_path = init_database(
                goal_id="complete-goal",
                goal_path=goal_path,
                goal_type="exam"
            )

            # Add multiple topics
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()

            topics = [
                ("T01", "Topic One", 0.0, "available"),
                ("T02", "Topic Two", 0.0, "available"),
                ("T03", "Topic Three", 0.0, "available"),
            ]

            for topic_id, name, mastery, status in topics:
                cursor.execute("""
                    INSERT INTO topics (topic_id, name, mastery, status)
                    VALUES (?, ?, ?, ?)
                """, (topic_id, name, mastery, status))

                # Add FSRS state for each
                row_id = cursor.lastrowid
                cursor.execute("""
                    INSERT INTO fsrs_state (topic_id, stability, difficulty, state)
                    VALUES (?, 2.5, 5.0, 0)
                """, (row_id,))

            conn.commit()
            conn.close()

            yield {"db_path": db_path, "vault_path": vault_path}

    def test_complete_learning_workflow(self, full_setup):
        """Test learning multiple topics updates all records."""
        db_path = full_setup["db_path"]
        vault_path = full_setup["vault_path"]

        manager = VaultManager(vault_path=vault_path, goal_id="complete-goal")
        manager.create_vault_structure()

        # Learn all three topics
        for i, performance in enumerate([1.0, 0.8, 0.6]):
            new_mastery = update_mastery(
                db_path=db_path,
                topic_row_id=i + 1,
                performance=performance
            )

            assert new_mastery > 0.0

            # Write note for each
            note_path = manager.write_note(
                topic_id=f"T0{i+1}-topic",
                content=f"# Topic {i+1}\n\nLearned content.",
                directory="10-Active-Topics"
            )

            assert note_path.exists()

        # Verify sessions recorded
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM sessions")
        session_count = cursor.fetchone()[0]
        conn.close()

        assert session_count == 3


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

            result = use_streak_freeze(db_path, 'freeze-use-test')
            assert result is True

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

            use_streak_freeze(db_path, 'no-freeze-test')
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

            use_streak_freeze(db_path, 'today-freeze')
            assert is_streak_frozen_today(db_path, 'today-freeze') is True
