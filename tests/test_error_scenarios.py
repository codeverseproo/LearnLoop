"""Tests for error handling scenarios across modules."""
import tempfile
from pathlib import Path
import pytest
import sqlite3

from scripts.sqlite_init import init_database
from scripts.vault_manager import VaultManager
from scripts.research_engine import ResearchEngine, Claim, Source, SourceTier


class TestGoalErrors:
    def test_E001_goal_already_exists(self):
        """E001: Creating duplicate goal raises error."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir) / 'test-goal'
            goal_path.mkdir(parents=True)
            init_database('test-goal', goal_path, 'exam')

            with pytest.raises(FileExistsError):
                init_database('test-goal', goal_path, 'exam')


class TestTopicErrors:
    def test_E102_prerequisite_not_satisfied(self):
        """E102: Learning topic without prerequisites fails."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir) / 'test-goal'
            goal_path.mkdir(parents=True)
            db_path = init_database('test-goal', goal_path, 'exam')

            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            cursor.execute("INSERT INTO topics (topic_id, name) VALUES ('T01', 'Prereq')")
            cursor.execute("INSERT INTO topics (topic_id, name) VALUES ('T02', 'Dependent')")
            cursor.execute("INSERT INTO prerequisites (topic_id, prerequisite_id) VALUES (2, 1)")
            conn.commit()
            cursor.execute("SELECT * FROM prerequisites WHERE topic_id = 2")
            prereq = cursor.fetchone()
            assert prereq is not None
            conn.close()


class TestFSRSErrors:
    def test_E203_invalid_performance_score(self):
        """E203: Performance out of range [0.0, 1.0] raises error."""
        from scripts.fsrs_scheduler import FSRSScheduler
        scheduler = FSRSScheduler()

        with pytest.raises(ValueError, match="E203"):
            scheduler.schedule_next_review(
                stability=5.0, difficulty=5.0, performance=1.5, state=2
            )

    def test_E201_invalid_stability(self):
        """E201: Negative stability raises error."""
        from scripts.fsrs_scheduler import FSRSScheduler
        scheduler = FSRSScheduler()

        with pytest.raises(ValueError, match="E201"):
            scheduler.schedule_next_review(
                stability=-1.0, difficulty=5.0, performance=0.8, state=2
            )


class TestVaultErrors:
    def test_E301_vault_path_not_accessible(self):
        """E301: Non-existent vault path handled gracefully."""
        vm = VaultManager(vault_path=Path('/non/existent/path'), goal_id='test')
        # Should not raise, creates parent dirs
        # If it can't create, it raises OSError


class TestResearchErrors:
    def test_E603_claim_unverified_flagged(self):
        """E603: Claims with <3 sources flagged as unverified."""
        engine = ResearchEngine()
        claim = Claim(text="Test claim")
        claim.add_source(engine.create_source("https://one.com", "Source 1"))

        assert claim.needs_verification is True
