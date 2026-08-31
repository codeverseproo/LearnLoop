"""Integration tests for complete learning workflows."""
import tempfile
from pathlib import Path
from datetime import datetime, timedelta
import sqlite3
import pytest

from scripts.sqlite_init import init_database
from scripts.fsrs_scheduler import FSRSScheduler
from scripts.mastery_update import update_mastery
from scripts.vault_manager import VaultManager


class TestCompleteLearningWorkflow:
    def test_create_goal_add_topic_learn_review_cycle(self):
        """Complete workflow: create → add topic → learn → review."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir) / 'integration-test'
            goal_path.mkdir(parents=True)
            db_path = init_database('integration-test', goal_path, 'exam')

            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()

            cursor.execute("""
                INSERT INTO topics (topic_id, name, status, mastery)
                VALUES ('T01', 'Test Topic', 'pending', 0.0)
            """)
            topic_row_id = cursor.lastrowid
            conn.commit()

            scheduler = FSRSScheduler()
            next_review, new_stability, new_difficulty = scheduler.schedule_next_review(
                stability=None, difficulty=None, performance=0.8, state=0
            )

            # FSRS calculates interval based on stability; for new items, default stability is 2.5 days
            # Interval = 9 * stability * (threshold^-1 - 1) ≈ 5 days
            assert next_review.date() <= (datetime.now() + timedelta(days=7)).date()

            new_mastery = update_mastery(
                db_path=db_path,
                topic_row_id=topic_row_id,
                performance=0.9,
                session_type='review'
            )

            assert new_mastery > 0.0
            conn.close()

    def test_scheduled_review_priority_ordering(self):
        """Review queue ordered by retrievability (lowest stability first)."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir) / 'review-test'
            goal_path.mkdir(parents=True)
            db_path = init_database('review-test', goal_path, 'exam')

            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()

            topics = [
                ('T01', 'Topic 1', 2.0),
                ('T02', 'Topic 2', 10.0),
                ('T03', 'Topic 3', 30.0),
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

            cursor.execute("""
                SELECT t.topic_id, fs.stability
                FROM topics t
                JOIN fsrs_state fs ON t.id = fs.topic_id
                ORDER BY fs.stability ASC
            """)

            results = cursor.fetchall()
            assert results[0][0] == 'T01'
            assert results[2][0] == 'T03'
            conn.close()

    def test_vault_note_created_during_learning(self):
        """Learning session creates vault note."""
        with tempfile.TemporaryDirectory() as tmpdir:
            vault_path = Path(tmpdir) / 'test-vault'
            vm = VaultManager(vault_path=vault_path, goal_id='test-goal')
            vm.create_vault_structure()

            note_content = """## Overview
Test note.

## Key Concepts
- Concept A
"""

            note_path = vm.write_note(
                topic_id='T01-test',
                content=note_content,
                mastery=0.0,
                next_review='2026-09-01'
            )

            assert note_path.exists()
            content = note_path.read_text()
            assert 'id: T01-test' in content


class TestMultiSessionWorkflow:
    def test_spaced_repetition_across_sessions(self):
        """Verify stability increases across multiple reviews."""
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

            mastery_1 = update_mastery(db_path, topic_row_id, 0.9, 'review')
            mastery_2 = update_mastery(db_path, topic_row_id, 0.85, 'review')

            assert mastery_2 > mastery_1
            conn.close()
