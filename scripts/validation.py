#!/usr/bin/env python3
"""Input validation module for MIT Learning Skill.

Provides centralized validation with regex patterns for safe identifiers.
All public API entry points should validate inputs before filesystem/database operations.
"""

import re
from typing import Optional


# Safe identifier pattern: alphanumeric, hyphens, underscores
SAFE_ID_PATTERN = re.compile(r'^[a-zA-Z0-9-_]+$')


class ValidationError(ValueError):
    """Base class for validation errors with error codes.

    All validation errors use format: E0XX for input errors,
    E2XX for calculation errors, E3XX for vault errors.
    """

    def __init__(self, code: str, message: str):
        self.code = code
        super().__init__(f"{code}: {message}")


def validate_goal_id(goal_id: str) -> str:
    """Validate goal_id is safe for filesystem and database.

    Args:
        goal_id: Goal identifier string

    Returns:
        Validated goal_id (unchanged)

    Raises:
        ValidationError(E004): If goal_id contains unsafe characters or is empty/too long
    """
    if not goal_id:
        raise ValidationError("E004", "goal_id cannot be empty")

    if not SAFE_ID_PATTERN.match(goal_id):
        raise ValidationError("E004", f"Invalid goal_id format: {goal_id!r}")

    if len(goal_id) > 64:
        raise ValidationError("E004", f"goal_id too long (max 64 chars): {len(goal_id)} chars")

    return goal_id


def validate_topic_id(topic_id: str) -> str:
    """Validate topic_id is safe for filesystem.

    Args:
        topic_id: Topic identifier string

    Returns:
        Validated topic_id (unchanged)

    Raises:
        ValidationError(E302): If topic_id contains unsafe characters or is empty/too long
    """
    if not topic_id:
        raise ValidationError("E302", "topic_id cannot be empty")

    if not SAFE_ID_PATTERN.match(topic_id):
        raise ValidationError("E302", f"Invalid topic_id format: {topic_id!r}")

    if len(topic_id) > 128:
        raise ValidationError("E302", f"topic_id too long (max 128 chars): {len(topic_id)} chars")

    return topic_id


def validate_performance(performance: float) -> float:
    """Validate performance is in [0.0, 1.0] range.

    Args:
        performance: Performance score

    Returns:
        Validated performance as float

    Raises:
        ValidationError(E203): If performance outside valid range or wrong type
    """
    if not isinstance(performance, (int, float)):
        raise ValidationError("E203", f"Performance must be numeric, got {type(performance).__name__}")

    perf_float = float(performance)

    if not 0.0 <= perf_float <= 1.0:
        raise ValidationError("E203", f"Performance out of range [0.0, 1.0]: {perf_float}")

    return perf_float


def validate_stability(stability: Optional[float]) -> Optional[float]:
    """Validate stability is non-negative if provided.

    Args:
        stability: Stability value or None for new items

    Returns:
        Validated stability (unchanged)

    Raises:
        ValidationError(E201): If stability is negative
    """
    if stability is None:
        return None

    if stability < 0:
        raise ValidationError("E201", f"Stability must be non-negative: {stability}")

    return stability


def validate_goal_type(goal_type: str) -> str:
    """Validate goal_type is one of allowed values.

    Args:
        goal_type: Goal type string

    Returns:
        Validated goal_type (unchanged)

    Raises:
        ValidationError(E005): If goal_type is invalid
    """
    valid_types = {'exam', 'skill', 'degree', 'topic'}

    if goal_type not in valid_types:
        raise ValidationError("E005", f"Invalid goal_type: {goal_type!r}. Must be one of {valid_types}")

    return goal_type
