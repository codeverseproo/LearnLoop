#!/usr/bin/env python3
"""Obsidian vault management for MIT Learning Skill.

Creates vault structure, writes notes, and manages dashboards.
"""

import shutil
from datetime import date, datetime
from pathlib import Path
from typing import Any, Dict, Optional

from scripts.validation import validate_topic_id


class VaultManager:
    """Manages Obsidian vault for a learning goal.

    Attributes:
        vault_path: Path to the vault directory
        goal_id: Unique identifier for the goal
    """

    # Standard vault directory structure
    DIRECTORIES = [
        "00-Dashboard",
        "10-Active-Topics",
        "20-Review-Queue",
        "30-Completed-Topics",
        "40-Practice",
        "50-Resources"
    ]

    def __init__(self, vault_path: Path, goal_id: str):
        """Initialize vault manager.

        Args:
            vault_path: Path to the vault directory
            goal_id: Unique identifier for the goal
        """
        self.vault_path = Path(vault_path)
        self.goal_id = goal_id

    def create_vault_structure(self) -> None:
        """Create standard vault directory structure."""
        for dirname in self.DIRECTORIES:
            dir_path = self.vault_path / dirname
            dir_path.mkdir(parents=True, exist_ok=True)

    def write_note(
        self,
        topic_id: str,
        content: str,
        directory: str = "10-Active-Topics",
        title: Optional[str] = None,
        mastery: float = 0.0,
        next_review: Optional[str] = None,
        related: Optional[list] = None,
        sources: Optional[list] = None
    ) -> Path:
        """Write a note to the vault.

        Args:
            topic_id: Unique identifier for the topic (e.g., 'T01-topic-slug')
            content: Note body content (markdown)
            directory: Vault subdirectory
            title: Note title (defaults to topic_id)
            mastery: Current mastery level (0.0-1.0)
            next_review: Next review date (ISO format)
            related: List of related topic IDs
            sources: List of source references

        Returns:
            Path to the created note file

        Raises:
            ValidationError(E302): If topic_id is invalid
        """
        # Validate topic_id BEFORE any filesystem operations
        validate_topic_id(topic_id)

        # Ensure directory exists
        dir_path = self.vault_path / directory
        dir_path.mkdir(parents=True, exist_ok=True)

        # Build frontmatter
        frontmatter = self._build_frontmatter(
            topic_id=topic_id,
            mastery=mastery,
            next_review=next_review,
            related=related,
            sources=sources
        )

        # Build full note
        note_title = title or topic_id.replace("-", " ").replace("T0", "Topic ").title()

        full_content = f"""---
{frontmatter}---

# {note_title}

{content}

---
Next Review: {next_review or 'TBD'}
"""

        # Write file
        note_path = dir_path / f"{topic_id}.md"
        note_path.write_text(full_content)

        return note_path

    def _build_frontmatter(
        self,
        topic_id: str,
        mastery: float,
        next_review: Optional[str],
        related: Optional[list],
        sources: Optional[list]
    ) -> str:
        """Build YAML frontmatter for a note.

        Args:
            topic_id: Topic identifier
            mastery: Mastery level
            next_review: Next review date
            related: Related topic IDs
            sources: Source references

        Returns:
            YAML frontmatter string
        """
        lines = [
            f"id: {topic_id}",
            f"created: '{date.today().isoformat()}'",
            f"updated: '{datetime.now().isoformat()}'",
            f"mastery: {mastery:.2f}"
        ]

        if next_review:
            lines.append(f"next_review: '{next_review}'")

        if related:
            lines.append("related:")
            for r in related:
                lines.append(f"  - '[[{r}]]'")

        if sources:
            lines.append("sources:")
            for s in sources:
                lines.append(f"  - '{s}'")

        return "\n".join(lines) + "\n"

    def update_dashboard(self, data: Dict[str, Any]) -> Path:
        """Update the progress dashboard.

        Args:
            data: Dashboard data dictionary with keys:
                - total_topics: int
                - mastered: int
                - in_progress: int
                - current_streak: int
                - longest_streak: int
                - title: str (optional)

        Returns:
            Path to the dashboard file
        """
        dashboard_dir = self.vault_path / "00-Dashboard"
        dashboard_dir.mkdir(parents=True, exist_ok=True)

        title = data.get("title", self.goal_id.replace("-", " ").title())

        # Calculate percentages
        total = data.get("total_topics", 0)
        mastered = data.get("mastered", 0)
        in_progress = data.get("in_progress", 0)

        mastered_pct = (mastered / total * 100) if total > 0 else 0
        in_progress_pct = (in_progress / total * 100) if total > 0 else 0

        # Build progress bars
        mastered_bar = self._progress_bar(mastered_pct)
        in_progress_bar = self._progress_bar(in_progress_pct)

        content = f"""# {title} Progress

## Summary
| Metric | Value |
|--------|-------|
| Total topics | {total} |
| Mastered | {mastered} ({mastered_pct:.1f}%) |
| In progress | {in_progress} |
| Available | {total - mastered - in_progress} |

## Visual Progress

### Overall Mastery
{mastered_bar} {mastered_pct:.1f}% Complete

### In Progress Topics
{in_progress_bar} {in_progress_pct:.1f}% Active

## Streak
- Current: {data.get('current_streak', 0)} days
- Longest: {data.get('longest_streak', 0)} days

## Next Up
- Due for review: Check review queue
- Recommended: Continue with current topic

---
Last updated: {datetime.now().strftime('%Y-%m-%d %H:%M')}
"""

        dashboard_path = dashboard_dir / "Progress.md"
        dashboard_path.write_text(content)

        return dashboard_path

    def _progress_bar(self, percentage: float, width: int = 10) -> str:
        """Create ASCII progress bar.

        Args:
            percentage: Percentage complete (0-100)
            width: Width in characters

        Returns:
            Progress bar string
        """
        filled = int(percentage / 100 * width)
        empty = width - filled

        return "■" * filled + "□" * empty

    def archive_topic(self, topic_id: str) -> None:
        """Move a completed topic to archive.

        Args:
            topic_id: Topic identifier

        Raises:
            ValidationError(E302): If topic_id is invalid
        """
        # Validate topic_id BEFORE any filesystem operations
        validate_topic_id(topic_id)

        active_path = self.vault_path / "10-Active-Topics" / f"{topic_id}.md"
        archive_path = self.vault_path / "30-Completed-Topics" / f"{topic_id}.md"

        if active_path.exists():
            archive_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(active_path), str(archive_path))

    def write_review_queue(
        self,
        topics: list,
        date_str: Optional[str] = None
    ) -> Path:
        """Write the daily review queue.

        Args:
            topics: List of topic dictionaries with:
                - topic_id: str
                - name: str
                - priority: str (HIGH|MEDIUM|LOW)
                - retrievability: float
                - mastery: float
            date_str: Date string (defaults to today)

        Returns:
            Path to the review queue file
        """
        date_str = date_str or date.today().isoformat()

        review_dir = self.vault_path / "20-Review-Queue"
        review_dir.mkdir(parents=True, exist_ok=True)

        lines = [f"# Review Queue - {date_str}\n"]
        lines.append("## Queue\n")
        lines.append("Priority-ordered by retrievability (lowest first).\n")

        for i, topic in enumerate(topics, 1):
            priority = topic.get("priority", "MEDIUM")
            emoji = {"HIGH": "🔴", "MEDIUM": "🟡", "LOW": "🟢"}.get(priority, "⚪")

            lines.append(f"### {i}. {topic['topic_id']}: {topic['name']} {emoji}")
            lines.append(f"- Mastery: {topic.get('mastery', 0):.1%}")
            lines.append(f"- Retrievability: {topic.get('retrievability', 0):.1%}")
            lines.append("")

        content = "\n".join(lines)

        queue_path = review_dir / f"Due-{date_str}.md"
        queue_path.write_text(content)

        return queue_path
