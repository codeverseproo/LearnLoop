#!/usr/bin/env python3
"""SQLite database initialization for MIT Learning Skill.

Creates goal-specific database with all required tables,
indexes, and initial state for learning workflows.
"""

import sqlite3
from datetime import date
from pathlib import Path
from typing import Optional


def init_database(
    goal_id: str,
    goal_path: Path,
    goal_type: str = "topic"
) -> Path:
    """Initialize SQLite database for a learning goal.

    Args:
        goal_id: Unique identifier for the goal (e.g., 'upsc-prelims')
        goal_path: Path to goal directory
        goal_type: Type of goal (exam|skill|degree|topic)

    Returns:
        Path to the created database file

    Raises:
        OSError: If database cannot be created
    """
    db_path = goal_path / "memory.db"

    # Check if database already exists to prevent duplicate initialization
    if db_path.exists():
        raise FileExistsError(f"E001: Goal database already exists at {db_path}")

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Create topics table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS topics (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            topic_id TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            mastery REAL DEFAULT 0.0,
            status TEXT DEFAULT 'pending',
            next_review DATE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)

    # Create FSRS state table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS fsrs_state (
            topic_id INTEGER PRIMARY KEY,
            stability REAL DEFAULT 2.5,
            difficulty REAL DEFAULT 0.3,
            state INTEGER DEFAULT 0,
            last_review TIMESTAMP,
            next_review TIMESTAMP,
            reviews INTEGER DEFAULT 0,
            FOREIGN KEY (topic_id) REFERENCES topics(id)
        )
    """)

    # Create prerequisites table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS prerequisites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            topic_id INTEGER NOT NULL,
            prerequisite_id INTEGER NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (topic_id) REFERENCES topics(id),
            FOREIGN KEY (prerequisite_id) REFERENCES topics(id),
            UNIQUE(topic_id, prerequisite_id)
        )
    """)

    # Create sessions table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_type TEXT NOT NULL,
            topic_id INTEGER,
            started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            ended_at TIMESTAMP,
            performance REAL,
            notes TEXT,
            FOREIGN KEY (topic_id) REFERENCES topics(id)
        )
    """)

    # Create note registry table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS note_registry (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            topic_id INTEGER NOT NULL,
            note_path TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (topic_id) REFERENCES topics(id)
        )
    """)

    # Create goal metadata table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS goal_meta (
            goal_id TEXT PRIMARY KEY,
            goal_type TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            vault_path TEXT,
            total_topics INTEGER DEFAULT 0,
            mastered_topics INTEGER DEFAULT 0
        )
    """)

    # Create streak state table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS streak_state (
            goal_id TEXT PRIMARY KEY,
            current_streak INTEGER DEFAULT 0,
            longest_streak INTEGER DEFAULT 0,
            last_activity_date DATE,
            streak_freeze_available INTEGER DEFAULT 1,
            streak_freeze_used_date DATE,
            FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id)
        )
    """)

    # Create achievements table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS achievements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            goal_id TEXT NOT NULL,
            achievement_id TEXT NOT NULL,
            unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (goal_id) REFERENCES goal_meta(goal_id),
            UNIQUE(goal_id, achievement_id)
        )
    """)

    # Create indexes for performance
    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_topics_mastery
        ON topics(mastery)
    """)

    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_topics_next_review
        ON topics(next_review)
    """)

    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_fsrs_next_review
        ON fsrs_state(next_review)
    """)

    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_sessions_started
        ON sessions(started_at)
    """)

    # Populate initial metadata
    cursor.execute("""
        INSERT OR REPLACE INTO goal_meta (goal_id, goal_type)
        VALUES (?, ?)
    """, (goal_id, goal_type))

    # Initialize streak state
    cursor.execute("""
        INSERT OR REPLACE INTO streak_state (goal_id, current_streak, longest_streak, streak_freeze_available)
        VALUES (?, 0, 0, 1)
    """, (goal_id,))

    conn.commit()
    conn.close()

    return db_path


def get_database_path(goal_id: str) -> Path:
    """Get the database path for a goal.

    Args:
        goal_id: Unique identifier for the goal

    Returns:
        Path to the goal's database file
    """
    base_path = Path.home() / ".mit-learning" / "goals" / goal_id
    return base_path / "memory.db"


def get_connection(goal_id: str) -> sqlite3.Connection:
    """Get a database connection for a goal.

    Args:
        goal_id: Unique identifier for the goal

    Returns:
        SQLite connection object
    """
    db_path = get_database_path(goal_id)
    return sqlite3.connect(db_path)
