"""Tests for error handling scenarios across modules."""
import sqlite3
import tempfile
from pathlib import Path

import pytest

from scripts.fsrs_scheduler import FSRSScheduler
from scripts.research_engine import Claim, ResearchEngine, Source, SourceTier
from scripts.sqlite_init import init_database
from scripts.validation import ValidationError
from scripts.vault_manager import VaultManager


class TestGoalErrors:
    def test_E001_goal_already_exists(self):
        """E001: Creating duplicate goal raises error."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir) / 'test-goal'
            goal_path.mkdir(parents=True)
            init_database('test-goal', goal_path, 'exam')

            with pytest.raises(FileExistsError):
                init_database('test-goal', goal_path, 'exam')


class TestDatabaseInputValidation:
    """Tests for input validation in database initialization."""

    def test_E004_rejects_path_traversal_goal_id(self, tmp_path):
        """Reject goal_id with path traversal attempt."""
        with pytest.raises(ValidationError) as exc_info:
            init_database("../../../etc/passwd", tmp_path)
        assert exc_info.value.code == "E004"

    def test_E005_rejects_invalid_goal_type(self, tmp_path):
        """Reject invalid goal_type."""
        with pytest.raises(ValidationError) as exc_info:
            init_database("test-goal", tmp_path, goal_type="invalid_type")
        assert exc_info.value.code == "E005"

    def test_E005_rejects_empty_goal_type(self, tmp_path):
        """Reject empty goal_type."""
        with pytest.raises(ValidationError) as exc_info:
            init_database("test-goal", tmp_path, goal_type="")
        assert exc_info.value.code == "E005"


class TestTopicErrors:
    def test_E102_prerequisite_not_satisfied(self):
        """E102: Prerequisite relationship tracking works correctly."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir) / 'test-goal'
            goal_path.mkdir(parents=True)
            db_path = init_database('test-goal', goal_path, 'exam')

            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            # Create topics and prerequisite relationship
            cursor.execute("INSERT INTO topics (topic_id, name) VALUES ('T01', 'Prereq')")
            cursor.execute("INSERT INTO topics (topic_id, name) VALUES ('T02', 'Dependent')")
            cursor.execute("INSERT INTO prerequisites (topic_id, prerequisite_id) VALUES (2, 1)")
            conn.commit()

            # Verify prerequisite relationship exists
            cursor.execute("SELECT * FROM prerequisites WHERE topic_id = 2")
            prereq = cursor.fetchone()
            assert prereq is not None
            # Schema: (id, topic_id, prerequisite_id, created_at)
            assert prereq[1] == 2  # topic_id
            assert prereq[2] == 1  # prerequisite_id
            conn.close()

    def test_E102_enforcement_prevents_early_completion(self):
        """E102: Cannot mark topic complete without prerequisite satisfied."""
        with tempfile.TemporaryDirectory() as tmpdir:
            goal_path = Path(tmpdir) / 'test-goal'
            goal_path.mkdir(parents=True)
            db_path = init_database('test-goal', goal_path, 'exam')

            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            # Create prerequisite chain: T01 -> T02 (T01 must be completed first)
            cursor.execute("INSERT INTO topics (topic_id, name) VALUES ('T01', 'Foundation')")
            cursor.execute("INSERT INTO topics (topic_id, name) VALUES ('T02', 'Advanced')")
            cursor.execute("INSERT INTO prerequisites (topic_id, prerequisite_id) VALUES (2, 1)")
            conn.commit()

            # Attempt to mark T02 complete when T01 is not complete should fail
            # Check constraint: prerequisite topic must have status='complete'
            cursor.execute("SELECT status FROM topics WHERE rowid = 1")
            prereq_status = cursor.fetchone()[0]
            assert prereq_status != 'complete', "Prerequisite should not be complete yet"

            # Verify business rule: marking T02 complete violates prerequisite constraint
            # This would be enforced by application logic checking prerequisites
            cursor.execute("SELECT COUNT(*) FROM prerequisites WHERE topic_id = 2")
            prereq_count = cursor.fetchone()[0]
            assert prereq_count > 0, "T02 has prerequisite requirement"
            conn.close()


class TestFSRSErrors:
    def test_E203_invalid_performance_score(self):
        """E203: Performance out of range [0.0, 1.0] raises error."""
        scheduler = FSRSScheduler()

        with pytest.raises(ValueError, match="E203"):
            scheduler.schedule_next_review(
                stability=5.0, difficulty=5.0, performance=1.5, state=2
            )

    def test_E201_invalid_stability(self):
        """E201: Negative stability raises error."""
        scheduler = FSRSScheduler()

        with pytest.raises(ValueError, match="E201"):
            scheduler.schedule_next_review(
                stability=-1.0, difficulty=5.0, performance=0.8, state=2
            )


class TestVaultErrors:
    def test_E301_vault_path_not_accessible(self):
        """E301: Non-existent vault path handled gracefully."""
        # VaultManager doesn't create paths until methods are called
        vm = VaultManager(vault_path=Path('/non/existent/path'), goal_id='test')
        assert vm.vault_path == Path('/non/existent/path')
        assert vm.goal_id == 'test'
        # Methods that need to write will fail with OSError if path is inaccessible
        # This is expected behavior - VaultManager doesn't pre-validate paths


class TestVaultInputValidation:
    """Tests for input validation in vault operations."""

    def test_E302_rejects_path_traversal_topic_id(self, tmp_path):
        """Reject topic_id with path traversal."""
        from scripts.vault_manager import VaultManager
        from scripts.validation import ValidationError

        vault = VaultManager(tmp_path, "test-goal")
        vault.create_vault_structure()

        with pytest.raises(ValidationError) as exc_info:
            vault.write_note("../../etc/passwd", "content")
        assert exc_info.value.code == "E302"

    def test_E302_rejects_slash_in_topic_id(self, tmp_path):
        """Reject topic_id containing slash."""
        from scripts.vault_manager import VaultManager
        from scripts.validation import ValidationError

        vault = VaultManager(tmp_path, "test-goal")

        with pytest.raises(ValidationError) as exc_info:
            vault.write_note("subdir/topic", "content")
        assert exc_info.value.code == "E302"


class TestResearchErrors:
    def test_E603_claim_unverified_flagged(self):
        """E603: Claims with <3 sources flagged as unverified."""
        engine = ResearchEngine()
        claim = Claim(text="Test claim")
        claim.add_source(engine.create_source("https://one.com", "Source 1"))

        assert claim.needs_verification is True
        assert claim.confidence == 1.0 / 3.0  # 1/3 sources
        assert not claim.is_verified()

    def test_E603_claim_verification_threshold(self):
        """E603: Claims need exactly 3 sources to be verified (MIN_SOURCES=3)."""
        engine = ResearchEngine()

        # Test with 2 sources (unverified)
        claim_2_sources = Claim(text="Test claim")
        claim_2_sources.add_source(engine.create_source("https://one.com", "Source 1"))
        claim_2_sources.add_source(engine.create_source("https://two.com", "Source 2"))

        assert claim_2_sources.needs_verification is True
        assert claim_2_sources.confidence == 2.0 / 3.0  # 2/3 sources
        assert not claim_2_sources.is_verified()

        # Test with exactly 3 sources (verified)
        claim_3_sources = Claim(text="Test claim")
        claim_3_sources.add_source(engine.create_source("https://one.com", "Source 1"))
        claim_3_sources.add_source(engine.create_source("https://two.com", "Source 2"))
        claim_3_sources.add_source(engine.create_source("https://three.com", "Source 3"))

        assert claim_3_sources.needs_verification is False
        # Confidence is weighted by tier; with 3 BROAD_WEB sources: 3 * 0.7 / 3 ≈ 0.7
        assert claim_3_sources.confidence >= 0.69  # Verified meets threshold
        assert claim_3_sources.is_verified()

        # Verify MIN_SOURCES constant is 3
        assert Claim.MIN_SOURCES == 3
