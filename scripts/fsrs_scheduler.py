#!/usr/bin/env python3
"""FSRS-6 spaced repetition scheduler for MIT Learning Skill.

Implements the Free Spaced Repetition Scheduler algorithm for
optimal review scheduling and mastery calculation.
"""

import math
from datetime import datetime, timedelta
from typing import Optional, Tuple


# FSRS-6 Constants
RETRIEVABILITY_THRESHOLD = 0.9  # Target 90% retention
STABILITY_DEFAULT = 2.5  # Default stability in days
DIFFICULTY_DEFAULT = 5.0  # Default difficulty (1-10 scale)
DECAY = -0.5  # Decay factor for mastery calculation

# Upper bounds for safety
MAX_STABILITY = 365.0  # 1 year maximum stability
MAX_INTERVAL = 365  # Maximum interval in days


def retrievability(stability: float, days_since_review: float) -> float:
    """Calculate probability of recall using FSRS formula.

    FSRS power law: R(t, S) = (1 + t/(9*S))^-1

    Args:
        stability: Time for retrievability to decay to 90%
        days_since_review: Days since last review

    Returns:
        Probability of recall (0.0 to 1.0)
    """
    if stability <= 0:
        return 0.0

    factor = 1 + days_since_review / (9 * stability)
    return max(0.0, factor ** -1)


class FSRSScheduler:
    """FSRS-6 scheduler for spaced repetition."""

    def __init__(
        self,
        stability_default: float = STABILITY_DEFAULT,
        difficulty_default: float = DIFFICULTY_DEFAULT,
        decay: float = DECAY
    ):
        """Initialize scheduler with defaults.

        Args:
            stability_default: Default stability for new items
            difficulty_default: Default difficulty (1-10)
            decay: Decay factor for mastery calculation
        """
        self.stability_default = stability_default
        self.difficulty_default = difficulty_default
        self.decay = decay
        self.retrievability_threshold = RETRIEVABILITY_THRESHOLD

    def schedule_next_review(
        self,
        stability: Optional[float],
        difficulty: Optional[float],
        performance: float,
        state: int = 0
    ) -> Tuple[datetime, float, float]:
        """Calculate next review date and updated parameters.

        Args:
            stability: Current stability (None for new items)
            difficulty: Current difficulty (None for new items)
            performance: Performance score (0.0-1.0)
            state: Current FSM state (0=New, 1=Learning, 2=Review, 3=Relearning)

        Returns:
            Tuple of (next_review_date, new_stability, new_difficulty)
        """
        # Validate inputs
        if stability is not None and stability < 0:
            raise ValueError("E201: Invalid stability value - must be non-negative")

        if not 0.0 <= performance <= 1.0:
            raise ValueError("E203: Invalid performance score - must be in [0.0, 1.0]")

        # Initialize new items
        if stability is None:
            stability = self.stability_default
        if difficulty is None:
            difficulty = self.difficulty_default

        # Cap stability at maximum
        stability = min(stability, MAX_STABILITY)

        # Calculate retrievability for state update
        r = retrievability(stability, 0)

        # Update parameters based on performance
        new_stability = self.update_stability(
            stability, difficulty, performance, r
        )
        new_difficulty = self.update_difficulty(difficulty, performance)

        # Cap new stability
        new_stability = min(new_stability, MAX_STABILITY)

        # Calculate interval using new stability
        # Target retrievability = 0.9
        # Solve R(t) = 0.9 for t: t = 9 * S * (threshold^(-1) - 1)
        interval_days = 9 * new_stability * (RETRIEVABILITY_THRESHOLD ** -1 - 1)

        # Clamp interval to valid range
        interval_days = max(1, min(MAX_INTERVAL, interval_days))

        next_review = datetime.now() + timedelta(days=interval_days)

        return next_review, new_stability, new_difficulty

    def update_stability(
        self,
        stability: float,
        difficulty: float,
        performance: float,
        retrievability: float
    ) -> float:
        """Update stability based on performance.

        Stability increases on success, decreases on failure.

        Args:
            stability: Current stability
            difficulty: Current difficulty (1-10)
            performance: Performance score (0.0-1.0)
            retrievability: Current retrievability

        Returns:
            New stability value
        """
        if stability <= 0:
            return self.stability_default

        # Stability increase factor
        # f(D) = 11 - difficulty (higher difficulty = smaller increase)
        f_d = 11 - difficulty

        # f(S) - saturation effect (larger S = smaller relative increase)
        f_s = 1 + (stability ** 0.5) / 10

        # f(R) - retrievability effect (lower R = larger increase when recalled)
        f_r = 0.5 + retrievability

        # Performance factor
        # Good performance (1.0) -> increase stability
        # Poor performance (0.0) -> decrease stability
        if performance >= 0.6:  # Successful recall
            p_factor = 1 + (performance - 0.6) * 2
            # Stability growth: balance all factors
            new_stability = stability * (1 + f_d * 0.1 * p_factor)
        else:  # Failed recall - decrease stability
            new_stability = stability * (0.5 + performance * 0.5)

        return max(self.stability_default * 0.1, new_stability)

    def update_difficulty(
        self,
        difficulty: float,
        performance: float
    ) -> float:
        """Update difficulty based on performance.

        Difficulty decreases on success (item seems easier),
        increases on failure (item seems harder).
        Mean reversion toward 5.0.

        Args:
            difficulty: Current difficulty (1-10)
            performance: Performance score (0.0-1.0)

        Returns:
            New difficulty value (clamped to 1-10)
        """
        # Mean reversion factor
        mean = 5.0
        reversion_rate = 0.1

        # Performance adjustment
        # Success (high performance) -> decrease difficulty
        # Failure (low performance) -> increase difficulty
        perf_adjustment = (1 - performance) * 2

        # Apply mean reversion
        new_difficulty = difficulty + (mean - difficulty) * reversion_rate * 0.1

        # Apply performance adjustment (reduced impact for stability)
        new_difficulty += perf_adjustment * 0.1

        # Clamp to valid range
        return max(1.0, min(10.0, new_difficulty))

    def mastery_from_fsrs(
        self,
        stability: float,
        difficulty: float
    ) -> float:
        """Calculate mastery score from FSRS state.

        Formula: mastery = 1 - exp(decay * stability / difficulty)

        Args:
            stability: Current stability in days
            difficulty: Current difficulty (1-10)

        Returns:
            Mastery score (0.0 to 1.0)
        """
        if stability <= 0:
            return 0.0

        # Adjust difficulty to avoid division issues
        d_adj = max(difficulty, 0.01)

        try:
            mastery = 1 - math.exp(self.decay * stability / d_adj)
            return max(0.0, min(1.0, mastery))
        except (OverflowError, ValueError):
            return 0.0


def calculate_review_priority(
    stability: float,
    last_review: datetime,
    threshold: float = RETRIEVABILITY_THRESHOLD
) -> float:
    """Calculate review priority based on retrievability.

    Topics with retrievability below threshold get higher priority.

    Args:
        stability: Current stability in days
        last_review: When the topic was last reviewed
        threshold: Target retrievability threshold

    Returns:
        Priority score (lower = more urgent)
    """
    days_since = (datetime.now() - last_review).days
    r = retrievability(stability, days_since)

    # Priority = how far below threshold
    # Negative = overdue (high priority)
    # Positive = not due yet (low priority)
    return r - threshold
