# MIT/tests/test_mastery_update.py
"""Tests for mastery update functionality."""

import sqlite3
import tempfile
from pathlib import Path
import pytest
from scripts.sqlite_init import init_database
from scripts.mastery_update import update_mastery, get_topic_mastery


class TestMasteryUpdate:
    """Test mastery update functionality."""

    @pytest.fixture
    def temp_db(self):
        """Create a temporary database for testing."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir)
            db_path = init_database(
                goal_id="test-goal",
                goal_path=goal_path,
                goal_type="exam"
            )

            # Add a test topic
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO topics (topic_id, name, mastery, status)
                VALUES ('T01', 'Test Topic', 0.0, 'available')
            """)
            cursor.execute("""
                INSERT INTO fsrs_state (topic_id, stability, difficulty, state)
                VALUES (1, 2.5, 5.0, 0)
            """)
            conn.commit()
            conn.close()

            yield db_path

    def test_update_mastery_increases_on_success(self, temp_db):
        """Test mastery increases on successful performance."""
        update_mastery(
            db_path=temp_db,
            topic_row_id=1,
            performance=1.0
        )

        mastery = get_topic_mastery(temp_db, topic_row_id=1)
        assert mastery > 0.0

    def test_update_mastery_decreases_on_failure(self, temp_db):
        """Test mastery decreases on failed performance."""
        # First update to set some mastery
        update_mastery(db_path=temp_db, topic_row_id=1, performance=1.0)
        initial_mastery = get_topic_mastery(temp_db, topic_row_id=1)

        # Then fail
        update_mastery(db_path=temp_db, topic_row_id=1, performance=0.0)
        new_mastery = get_topic_mastery(temp_db, topic_row_id=1)

        assert new_mastery < initial_mastery

    def test_update_mastery_updates_fsrs_state(self, temp_db):
        """Test that FSRS state is updated."""
        conn = sqlite3.connect(temp_db)
        cursor = conn.cursor()

        # Get initial state
        cursor.execute("SELECT stability, difficulty, reviews FROM fsrs_state WHERE topic_id = 1")
        initial_state = cursor.fetchone()
        conn.close()

        # Update mastery
        update_mastery(db_path=temp_db, topic_row_id=1, performance=1.0)

        # Check updated state
        conn = sqlite3.connect(temp_db)
        cursor = conn.cursor()
        cursor.execute("SELECT stability, difficulty, reviews FROM fsrs_state WHERE topic_id = 1")
        new_state = cursor.fetchone()
        conn.close()

        # Stability should increase, reviews should increment
        assert new_state[0] > initial_state[0]  # stability
        assert new_state[2] > initial_state[2]  # reviews

    def test_update_mastery_records_session(self, temp_db):
        """Test that a session record is created."""
        update_mastery(db_path=temp_db, topic_row_id=1, performance=0.8)

        conn = sqlite3.connect(temp_db)
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM sessions WHERE topic_id = 1")
        count = cursor.fetchone()[0]
        conn.close()

        assert count >= 1

    def test_update_mastery_bounded(self, temp_db):
        """Test mastery stays within 0-1 bounds."""
        for performance in [0.0, 0.5, 1.0]:
            update_mastery(db_path=temp_db, topic_row_id=1, performance=performance)
            mastery = get_topic_mastery(temp_db, topic_row_id=1)
            assert 0.0 <= mastery <= 1.0

    def test_get_topic_mastery_returns_zero_for_missing(self, temp_db):
        """Test get_topic_mastery returns 0 for non-existent topic."""
        mastery = get_topic_mastery(temp_db, topic_row_id=999)
        assert mastery == 0.0

    def test_update_mastery_updates_next_review(self, temp_db):
        """Test that next_review is set."""
        update_mastery(db_path=temp_db, topic_row_id=1, performance=1.0)

        conn = sqlite3.connect(temp_db)
        cursor = conn.cursor()
        cursor.execute("SELECT next_review FROM fsrs_state WHERE topic_id = 1")
        next_review = cursor.fetchone()[0]
        conn.close()

        assert next_review is not None

    def test_update_mastery_high_performance_high_mastery(self, temp_db):
        """Test that repeated success leads to high mastery."""
        for _ in range(10):
            update_mastery(db_path=temp_db, topic_row_id=1, performance=1.0)

        mastery = get_topic_mastery(temp_db, topic_row_id=1)
        # After 10 perfect reviews, mastery should be significant
        assert mastery > 0.3
