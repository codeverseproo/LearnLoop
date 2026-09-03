"""Tests for Obsidian vault management."""

import tempfile
from pathlib import Path
import pytest
from scripts.vault_manager import VaultManager


class TestVaultManager:
    """Test vault management functionality."""

    @pytest.fixture
    def temp_vault(self):
        """Create a temporary vault for testing."""
        with tempfile.TemporaryDirectory() as tmpdir:
            vault_path = Path(tmpdir) / "test-vault"
            vault_path.mkdir(parents=True)
            yield vault_path

    def test_vault_manager_initialization(self, temp_vault):
        """Test vault manager initializes correctly."""
        manager = VaultManager(vault_path=temp_vault, goal_id="test-goal")

        assert manager.vault_path == temp_vault
        assert manager.goal_id == "test-goal"

    def test_create_vault_structure(self, temp_vault):
        """Test vault structure is created."""
        manager = VaultManager(vault_path=temp_vault, goal_id="test-goal")
        manager.create_vault_structure()

        # Check directories exist
        expected_dirs = [
            "00-Dashboard",
            "10-Active-Topics",
            "20-Review-Queue",
            "30-Completed-Topics",
            "40-Practice",
            "50-Resources"
        ]

        for dirname in expected_dirs:
            assert (temp_vault / dirname).exists()
            assert (temp_vault / dirname).is_dir()

    def test_write_note(self, temp_vault):
        """Test writing a note to vault."""
        manager = VaultManager(vault_path=temp_vault, goal_id="test-goal")
        manager.create_vault_structure()

        note_content = """---
id: T01-test-topic
created: 2026-08-31
mastery: 0.0
---

# Test Topic

## Overview
This is a test note.
"""

        note_path = manager.write_note(
            topic_id="T01-test-topic",
            content=note_content,
            directory="10-Active-Topics"
        )

        assert note_path.exists()
        assert note_path.name == "T01-test-topic.md"

    def test_write_note_creates_parent_dirs(self, temp_vault):
        """Test that write_note creates parent directories if needed."""
        manager = VaultManager(vault_path=temp_vault, goal_id="test-goal")

        # Don't call create_vault_structure
        note_content = "# Test Note"

        note_path = manager.write_note(
            topic_id="T01-test",
            content=note_content,
            directory="10-Active-Topics"
        )

        assert note_path.exists()

    def test_update_dashboard(self, temp_vault):
        """Test updating progress dashboard."""
        manager = VaultManager(vault_path=temp_vault, goal_id="test-goal")
        manager.create_vault_structure()

        dashboard_data = {
            "total_topics": 10,
            "mastered": 3,
            "in_progress": 4,
            "current_streak": 7,
            "longest_streak": 14
        }

        manager.update_dashboard(dashboard_data)

        dashboard_path = temp_vault / "00-Dashboard" / "Progress.md"
        assert dashboard_path.exists()

        content = dashboard_path.read_text()
        assert "10" in content  # total_topics
        assert "7" in content  # current_streak

    def test_write_note_with_frontmatter(self, temp_vault):
        """Test note includes correct frontmatter."""
        manager = VaultManager(vault_path=temp_vault, goal_id="test-goal")
        manager.create_vault_structure()

        manager.write_note(
            topic_id="T05-polity",
            title="Constitutional Basics",
            content="## Overview\nConstitution is the supreme law.",
            mastery=0.5,
            next_review="2026-09-07"
        )

        note_path = temp_vault / "10-Active-Topics" / "T05-polity.md"
        content = note_path.read_text()

        assert "id: T05-polity" in content
        assert "mastery: 0.50" in content
        assert "next_review: '2026-09-07'" in content

    def test_archive_completed_topic(self, temp_vault):
        """Test moving completed topic to archive."""
        manager = VaultManager(vault_path=temp_vault, goal_id="test-goal")
        manager.create_vault_structure()

        # Write an active note
        manager.write_note(
            topic_id="T01-complete",
            content="# Completed Topic",
            directory="10-Active-Topics"
        )

        # Archive it
        manager.archive_topic("T01-complete")

        # Check moved
        assert not (temp_vault / "10-Active-Topics" / "T01-complete.md").exists()
        assert (temp_vault / "30-Completed-Topics" / "T01-complete.md").exists()

    def test_write_note_with_related_and_sources(self, temp_vault):
        """Test note with related topics and sources in frontmatter."""
        manager = VaultManager(vault_path=temp_vault, goal_id="test-goal")
        manager.create_vault_structure()

        manager.write_note(
            topic_id="T10-advanced",
            content="## Overview\nAdvanced topic.",
            related=["T01-prereq", "T02-basics"],
            sources=["Textbook Ch.5", "Course Video 3"]
        )

        note_path = temp_vault / "10-Active-Topics" / "T10-advanced.md"
        content = note_path.read_text()

        assert "related:" in content
        assert "[[T01-prereq]]" in content
        assert "[[T02-basics]]" in content
        assert "sources:" in content
        assert "Textbook Ch.5" in content

    def test_write_review_queue(self, temp_vault):
        """Test writing daily review queue."""
        manager = VaultManager(vault_path=temp_vault, goal_id="test-goal")
        manager.create_vault_structure()

        topics = [
            {"topic_id": "T01", "name": "Polity", "priority": "HIGH", "mastery": 0.3, "retrievability": 0.5},
            {"topic_id": "T02", "name": "History", "priority": "MEDIUM", "mastery": 0.6, "retrievability": 0.7},
            {"topic_id": "T03", "name": "Geography", "priority": "LOW", "mastery": 0.8, "retrievability": 0.9}
        ]

        queue_path = manager.write_review_queue(topics, date_str="2026-08-31")

        assert queue_path.exists()
        assert queue_path.name == "Due-2026-08-31.md"

        content = queue_path.read_text()
        assert "Review Queue - 2026-08-31" in content
        assert "T01: Polity" in content
        assert "HIGH" not in content  # Should use emoji instead
        assert "30.0%" in content  # mastery 0.3 as percentage

    def test_write_review_queue_high_priority_emoji(self, temp_vault):
        """Test that review queue uses emoji for priorities."""
        manager = VaultManager(vault_path=temp_vault, goal_id="test-goal")

        topics = [
            {"topic_id": "T01", "name": "Urgent", "priority": "HIGH", "mastery": 0.2, "retrievability": 0.3}
        ]

        queue_path = manager.write_review_queue(topics)
        content = queue_path.read_text()

        # HIGH priority should show red circle emoji
        assert "🔴" in content
