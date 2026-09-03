# MIT/tests/test_sqlite_init.py
"""Tests for SQLite database initialization."""

import sqlite3
import tempfile
from pathlib import Path
import pytest
from scripts.sqlite_init import init_database


class TestDatabaseInit:
    """Test database initialization."""

    def test_init_database_creates_file(self):
        """Test that init_database creates the database file."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir)
            db_path = init_database(
                goal_id="test-goal",
                goal_path=goal_path,
                goal_type="exam"
            )
            assert db_path.exists()
            assert db_path.name == "memory.db"

    def test_init_database_creates_tables(self):
        """Test that all required tables are created."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir)
            db_path = init_database(
                goal_id="test-goal",
                goal_path=goal_path,
                goal_type="exam"
            )

            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()

            # Check topics table exists
            cursor.execute(
                "SELECT name FROM sqlite_master WHERE type='table' AND name='topics'"
            )
            assert cursor.fetchone() is not None

            # Check fsrs_state table exists
            cursor.execute(
                "SELECT name FROM sqlite_master WHERE type='table' AND name='fsrs_state'"
            )
            assert cursor.fetchone() is not None

            conn.close()

    def test_init_database_creates_all_eight_tables(self):
        """Test that exactly 8 tables are created."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir)
            db_path = init_database(
                goal_id="test-goal",
                goal_path=goal_path,
                goal_type="exam"
            )

            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()

            cursor.execute(
                "SELECT name FROM sqlite_master WHERE type='table'"
            )
            tables = [row[0] for row in cursor.fetchall()]

            expected_tables = [
                'topics', 'fsrs_state', 'prerequisites',
                'sessions', 'note_registry', 'goal_meta',
                'streak_state', 'achievements'
            ]

            for table in expected_tables:
                assert table in tables, f"Missing table: {table}"

            conn.close()

    def test_init_database_topics_schema(self):
        """Test topics table has correct schema."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir)
            db_path = init_database(
                goal_id="test-goal",
                goal_path=goal_path,
                goal_type="exam"
            )

            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()

            cursor.execute("PRAGMA table_info(topics)")
            columns = {row[1]: row[2] for row in cursor.fetchall()}

            assert 'id' in columns
            assert 'topic_id' in columns
            assert 'name' in columns
            assert 'mastery' in columns
            assert 'status' in columns
            assert 'next_review' in columns

            conn.close()

    def test_init_database_streak_state_schema(self):
        """Test streak_state table has correct schema."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir)
            db_path = init_database(
                goal_id="test-goal",
                goal_path=goal_path,
                goal_type="exam"
            )

            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()

            cursor.execute("PRAGMA table_info(streak_state)")
            columns = {row[1]: row[2] for row in cursor.fetchall()}

            assert 'goal_id' in columns
            assert 'current_streak' in columns
            assert 'longest_streak' in columns
            assert 'last_activity_date' in columns
            assert 'streak_freeze_available' in columns

            conn.close()

    def test_init_database_creates_indexes(self):
        """Test that performance indexes are created."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir)
            db_path = init_database(
                goal_id="test-goal",
                goal_path=goal_path,
                goal_type="exam"
            )

            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()

            cursor.execute(
                "SELECT name FROM sqlite_master WHERE type='index'"
            )
            indexes = [row[0] for row in cursor.fetchall()]

            assert 'idx_topics_mastery' in indexes
            assert 'idx_topics_next_review' in indexes
            assert 'idx_fsrs_next_review' in indexes

            conn.close()

    def test_init_database_populates_goal_meta(self):
        """Test that goal_meta is populated with initial values."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir)
            db_path = init_database(
                goal_id="test-goal",
                goal_path=goal_path,
                goal_type="exam"
            )

            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()

            cursor.execute("SELECT goal_id, goal_type FROM goal_meta")
            row = cursor.fetchone()

            assert row[0] == "test-goal"
            assert row[1] == "exam"

            conn.close()

    def test_init_database_streak_defaults(self):
        """Test that streak_state is initialized with defaults."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir)
            db_path = init_database(
                goal_id="test-goal",
                goal_path=goal_path,
                goal_type="exam"
            )

            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()

            cursor.execute("SELECT current_streak, streak_freeze_available FROM streak_state")
            row = cursor.fetchone()

            assert row[0] == 0  # current_streak
            assert row[1] == 1  # streak_freeze_available

            conn.close()
