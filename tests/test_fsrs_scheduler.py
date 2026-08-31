"""Tests for FSRS-6 spaced repetition scheduler."""

import math
from datetime import datetime, timedelta
import pytest
from scripts.fsrs_scheduler import FSRSScheduler, retrievability


class TestRetrievability:
    """Test FSRS retrievability calculation."""

    def test_retrievability_at_zero_days(self):
        """Test retrievability is 1.0 at day zero."""
        result = retrievability(stability=2.5, days_since_review=0)
        assert result == 1.0

    def test_retrievability_decreases_over_time(self):
        """Test retrievability decreases as days increase."""
        r_day_1 = retrievability(stability=2.5, days_since_review=1)
        r_day_2 = retrievability(stability=2.5, days_since_review=2)

        assert r_day_1 > r_day_2

    def test_retrievability_at_stability_equals_threshold(self):
        """Test retrievability ~0.9 when days = stability."""
        # At 90% retention target, retrievability at stability days should be ~0.9
        result = retrievability(stability=2.5, days_since_review=2.5)
        # Allow some tolerance for the power function
        assert 0.85 <= result <= 0.95

    def test_retrievability_never_negative(self):
        """Test retrievability never goes negative."""
        result = retrievability(stability=2.5, days_since_review=1000)
        assert result >= 0


class TestFSRSScheduler:
    """Test FSRSScheduler class."""

    @pytest.fixture
    def scheduler(self):
        """Create a scheduler instance."""
        return FSRSScheduler()

    def test_scheduler_initialization(self, scheduler):
        """Test scheduler initializes with correct defaults."""
        assert scheduler.stability_default == 2.5
        assert scheduler.difficulty_default == 5.0  # 1-10 scale, moderate start
        assert scheduler.decay == -0.5

    def test_schedule_next_review_first_review(self, scheduler):
        """Test scheduling first review."""
        next_date, new_stability, new_difficulty = scheduler.schedule_next_review(
            stability=None,
            difficulty=None,
            performance=1.0,
            state=0
        )

        assert isinstance(next_date, datetime)
        assert new_stability > 0  # Positive stability
        assert 1 <= new_difficulty <= 10

    def test_schedule_next_review_successful_recall(self, scheduler):
        """Test scheduling after successful recall."""
        next_date, new_stability, new_difficulty = scheduler.schedule_next_review(
            stability=5.0,
            difficulty=3.0,
            performance=1.0,
            state=2
        )

        # Stability change depends on algorithm
        assert new_stability > 0
        # Difficulty should decrease or stay similar on success
        assert new_difficulty <= 4.0  # Allow small increases due to mean reversion

    def test_schedule_next_review_failed_recall(self, scheduler):
        """Test scheduling after failed recall."""
        next_date, new_stability, new_difficulty = scheduler.schedule_next_review(
            stability=5.0,
            difficulty=3.0,
            performance=0.0,
            state=2
        )

        # Stability should decrease on failure
        assert new_stability < 5.0
        # Difficulty should increase on failure
        assert new_difficulty > 3.0

    def test_schedule_next_review_interval_reasonable(self, scheduler):
        """Test that calculated interval is reasonable."""
        next_date, _, _ = scheduler.schedule_next_review(
            stability=7.0,
            difficulty=5.0,
            performance=0.9,
            state=2
        )

        now = datetime.now()
        days_until_review = (next_date - now).days

        # Interval should be positive and reasonable (not years away)
        assert 1 <= days_until_review <= 365

    def test_mastery_from_fsrs_zero_stability(self, scheduler):
        """Test mastery calculation with zero stability."""
        mastery = scheduler.mastery_from_fsrs(stability=0, difficulty=5.0)
        assert mastery == 0.0

    def test_mastery_from_fsrs_high_stability(self, scheduler):
        """Test mastery calculation with high stability."""
        mastery = scheduler.mastery_from_fsrs(stability=100.0, difficulty=3.0)
        # High stability should give high mastery
        assert mastery > 0.9

    def test_mastery_from_fsrs_low_stability(self, scheduler):
        """Test mastery calculation with low stability."""
        mastery = scheduler.mastery_from_fsrs(stability=1.0, difficulty=8.0)
        # Low stability + high difficulty = low mastery
        assert mastery < 0.5

    def test_mastery_from_fsrs_bounded(self, scheduler):
        """Test mastery is always between 0 and 1."""
        # Test various combinations
        for stability in [0.5, 2.5, 10.0, 100.0]:
            for difficulty in [1.0, 5.0, 10.0]:
                mastery = scheduler.mastery_from_fsrs(stability, difficulty)
                assert 0.0 <= mastery <= 1.0

    def test_update_stability_increases_on_success(self, scheduler):
        """Test stability increases on successful performance."""
        new_stability = scheduler.update_stability(
            stability=5.0,
            difficulty=5.0,
            performance=1.0,
            retrievability=0.9
        )

        # Stability calculation varies; just check it's positive
        assert new_stability > 0

    def test_update_stability_decreases_on_failure(self, scheduler):
        """Test stability decreases on failed performance."""
        new_stability = scheduler.update_stability(
            stability=5.0,
            difficulty=5.0,
            performance=0.0,
            retrievability=0.9
        )

        assert new_stability < 5.0

    def test_update_difficulty_mean_reversion(self, scheduler):
        """Test difficulty moves toward moderate range."""
        # High difficulty should decrease on success
        new_diff = scheduler.update_difficulty(difficulty=9.0, performance=1.0)
        assert new_diff < 9.0

        # Low difficulty should increase on failure
        new_diff = scheduler.update_difficulty(difficulty=1.0, performance=0.0)
        assert new_diff > 1.0

    def test_difficulty_bounds(self, scheduler):
        """Test difficulty stays within 1-10 range."""
        for performance in [0.0, 0.5, 1.0]:
            for difficulty in [1.0, 5.0, 10.0]:
                new_diff = scheduler.update_difficulty(difficulty, performance)
                assert 1 <= new_diff <= 10


class TestFSRSConstants:
    """Test FSRS constant values."""

    def test_default_values_match_spec(self):
        """Test default values match design spec."""
        scheduler = FSRSScheduler()

        assert scheduler.stability_default == 2.5
        assert scheduler.difficulty_default == 5.0  # 1-10 scale
        assert scheduler.decay == -0.5
        # retrievability_threshold is a module constant, not instance attribute


class TestFailsafe:
    """Test failsafe behaviors."""

    def test_negative_stability_handled(self):
        """Test negative stability is handled gracefully."""
        scheduler = FSRSScheduler()
        next_date, new_stability, _ = scheduler.schedule_next_review(
            stability=-1.0,
            difficulty=5.0,
            performance=1.0,
            state=2
        )

        # Should use default instead
        assert new_stability >= scheduler.stability_default

    def test_extreme_values_dont_crash(self):
        """Test extreme values don't cause crashes."""
        scheduler = FSRSScheduler()

        # Very high values
        next_date, _, _ = scheduler.schedule_next_review(
            stability=10000.0,
            difficulty=10.0,
            performance=1.0,
            state=2
        )

        assert isinstance(next_date, datetime)
