#!/usr/bin/env python3
"""Mastery update functionality for MIT Learning Skill.

Updates topic mastery based on assessment performance,
recording sessions and updating FSRS state.
"""

import sqlite3
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional

from scripts.fsrs_scheduler import FSRSScheduler


def update_mastery(
    db_path: Path,
    topic_row_id: int,
    performance: float,
    session_type: str = "review"
) -> float:
    """Update mastery for a topic based on performance.

    Args:
        db_path: Path to the SQLite database
        topic_row_id: Row ID of the topic in the topics table
        performance: Performance score (0.0-1.0)
        session_type: Type of session (review|practice|assessment)

    Returns:
        New mastery value

    Raises:
        ValueError: If topic_row_id doesn't exist
    """
    scheduler = FSRSScheduler()

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    try:
        # Get current FSRS state
        cursor.execute("""
            SELECT fs.stability, fs.difficulty, fs.state, fs.reviews
            FROM fsrs_state fs
            WHERE fs.topic_id = ?
        """, (topic_row_id,))

        fsrs_row = cursor.fetchone()

        if fsrs_row is None:
            # Initialize FSRS state if missing
            stability = None
            difficulty = None
            state = 0
            reviews = 0
        else:
            stability, difficulty, state, reviews = fsrs_row

        # Schedule next review and update FSRS state
        next_review, new_stability, new_difficulty = scheduler.schedule_next_review(
            stability=stability,
            difficulty=difficulty,
            performance=performance,
            state=state or 0
        )

        # Calculate mastery
        new_mastery = scheduler.mastery_from_fsrs(new_stability, new_difficulty)

        # Update FSRS state
        cursor.execute("""
            INSERT OR REPLACE INTO fsrs_state
            (topic_id, stability, difficulty, state, last_review, next_review, reviews)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (
            topic_row_id,
            new_stability,
            new_difficulty,
            _get_new_state(state or 0, performance),
            datetime.now().isoformat(),
            next_review.isoformat(),
            (reviews or 0) + 1
        ))

        # Update topic mastery and next_review
        cursor.execute("""
            UPDATE topics
            SET mastery = ?, next_review = ?, status = 'in_progress', updated_at = ?
            WHERE id = ?
        """, (new_mastery, next_review.date().isoformat(), datetime.now().isoformat(), topic_row_id))

        # Record session
        cursor.execute("""
            INSERT INTO sessions (session_type, topic_id, performance, ended_at)
            VALUES (?, ?, ?, ?)
        """, (session_type, topic_row_id, performance, datetime.now().isoformat()))

        conn.commit()

        return new_mastery

    finally:
        conn.close()


def get_topic_mastery(db_path: Path, topic_row_id: int) -> float:
    """Get current mastery for a topic.

    Args:
        db_path: Path to the SQLite database
        topic_row_id: Row ID of the topic

    Returns:
        Current mastery value (0.0 to 1.0)
    """
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    try:
        cursor.execute("""
            SELECT t.mastery
            FROM topics t
            WHERE t.id = ?
        """, (topic_row_id,))

        row = cursor.fetchone()
        return row[0] if row else 0.0

    finally:
        conn.close()


def _get_new_state(current_state: int, performance: float) -> int:
    """Get new FSM state based on performance.

    States:
        0 = New
        1 = Learning
        2 = Review
        3 = Relearning

    Args:
        current_state: Current FSM state
        performance: Performance score (0.0-1.0)

    Returns:
        New state value
    """
    if current_state == 0:
        # New -> Learning
        return 1
    elif current_state == 1:
        # Learning -> Review (if successful)
        return 2 if performance >= 0.6 else 1
    elif current_state == 2:
        # Review -> Relearning (if failed)
        return 3 if performance < 0.6 else 2
    elif current_state == 3:
        # Relearning -> Review (if successful)
        return 2 if performance >= 0.6 else 3

    return current_state
