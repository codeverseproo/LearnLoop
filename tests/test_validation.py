#!/usr/bin/env python3
"""Tests for input validation module."""

import pytest
from scripts.validation import (
    ValidationError,
    validate_goal_id,
    validate_topic_id,
    validate_performance,
    validate_stability,
    validate_goal_type,
)


class TestValidateGoalId:
    """Tests for goal_id validation."""

    def test_valid_goal_id_simple(self):
        """Accept simple alphanumeric goal_id."""
        assert validate_goal_id("upsc-prelims") == "upsc-prelims"

    def test_valid_goal_id_with_underscore(self):
        """Accept goal_id with underscores."""
        assert validate_goal_id("my_goal_123") == "my_goal_123"

    def test_valid_goal_id_minimal(self):
        """Accept minimal goal_id."""
        assert validate_goal_id("a") == "a"

    def test_reject_empty_goal_id(self):
        """Reject empty goal_id with E004."""
        with pytest.raises(ValidationError) as exc_info:
            validate_goal_id("")
        assert exc_info.value.code == "E004"
        assert "cannot be empty" in str(exc_info.value)

    def test_reject_path_traversal_dotdot(self):
        """Reject path traversal attempt with .."""
        with pytest.raises(ValidationError) as exc_info:
            validate_goal_id("../etc/passwd")
        assert exc_info.value.code == "E004"
        assert "Invalid goal_id format" in str(exc_info.value)

    def test_reject_path_traversal_slash(self):
        """Reject goal_id with slash."""
        with pytest.raises(ValidationError) as exc_info:
            validate_goal_id("path/to/goal")
        assert exc_info.value.code == "E004"

    def test_reject_special_chars(self):
        """Reject goal_id with special characters."""
        for invalid_id in ["goal@home", "goal#123", "goal name", "goal!"]:
            with pytest.raises(ValidationError) as exc_info:
                validate_goal_id(invalid_id)
            assert exc_info.value.code == "E004"

    def test_reject_too_long_goal_id(self):
        """Reject goal_id exceeding 64 chars."""
        long_id = "a" * 65
        with pytest.raises(ValidationError) as exc_info:
            validate_goal_id(long_id)
        assert exc_info.value.code == "E004"
        assert "too long" in str(exc_info.value)


class TestValidateTopicId:
    """Tests for topic_id validation."""

    def test_valid_topic_id(self):
        """Accept valid topic_id."""
        assert validate_topic_id("T01-introduction") == "T01-introduction"

    def test_valid_topic_id_complex(self):
        """Accept complex but valid topic_id."""
        assert validate_topic_id("topic-with_numbers-2") == "topic-with_numbers-2"

    def test_reject_empty_topic_id(self):
        """Reject empty topic_id with E302."""
        with pytest.raises(ValidationError) as exc_info:
            validate_topic_id("")
        assert exc_info.value.code == "E302"

    def test_reject_path_traversal_topic(self):
        """Reject path traversal in topic_id."""
        with pytest.raises(ValidationError) as exc_info:
            validate_topic_id("../../etc/passwd")
        assert exc_info.value.code == "E302"

    def test_reject_too_long_topic_id(self):
        """Reject topic_id exceeding 128 chars."""
        long_id = "T" * 129
        with pytest.raises(ValidationError) as exc_info:
            validate_topic_id(long_id)
        assert exc_info.value.code == "E302"
        assert "too long" in str(exc_info.value)


class TestValidatePerformance:
    """Tests for performance validation."""

    def test_valid_performance_zero(self):
        """Accept performance of 0.0."""
        assert validate_performance(0.0) == 0.0

    def test_valid_performance_one(self):
        """Accept performance of 1.0."""
        assert validate_performance(1.0) == 1.0

    def test_valid_performance_midpoint(self):
        """Accept performance of 0.5."""
        assert validate_performance(0.5) == 0.5

    def test_reject_negative_performance(self):
        """Reject negative performance with E203."""
        with pytest.raises(ValidationError) as exc_info:
            validate_performance(-0.1)
        assert exc_info.value.code == "E203"

    def test_reject_above_one_performance(self):
        """Reject performance > 1.0."""
        with pytest.raises(ValidationError) as exc_info:
            validate_performance(1.5)
        assert exc_info.value.code == "E203"

    def test_reject_string_performance(self):
        """Reject non-numeric performance."""
        with pytest.raises(ValidationError) as exc_info:
            validate_performance("good")
        assert exc_info.value.code == "E203"


class TestValidateStability:
    """Tests for stability validation."""

    def test_valid_stability_zero(self):
        """Accept stability of 0."""
        assert validate_stability(0.0) == 0.0

    def test_valid_stability_positive(self):
        """Accept positive stability."""
        assert validate_stability(10.5) == 10.5

    def test_none_stability_allowed(self):
        """Accept None stability (for new items)."""
        assert validate_stability(None) is None

    def test_reject_negative_stability(self):
        """Reject negative stability with E201."""
        with pytest.raises(ValidationError) as exc_info:
            validate_stability(-1.0)
        assert exc_info.value.code == "E201"


class TestValidateGoalType:
    """Tests for goal_type validation."""

    def test_valid_goal_types(self):
        """Accept all valid goal_type values."""
        assert validate_goal_type("exam") == "exam"
        assert validate_goal_type("skill") == "skill"
        assert validate_goal_type("degree") == "degree"
        assert validate_goal_type("topic") == "topic"

    def test_reject_invalid_goal_type(self):
        """Reject invalid goal_type with E005."""
        with pytest.raises(ValidationError) as exc_info:
            validate_goal_type("invalid")
        assert exc_info.value.code == "E005"

    def test_reject_empty_goal_type(self):
        """Reject empty goal_type."""
        with pytest.raises(ValidationError) as exc_info:
            validate_goal_type("")
        assert exc_info.value.code == "E005"


class TestValidationError:
    """Tests for ValidationError class."""

    def test_error_has_code(self):
        """ValidationError stores error code."""
        err = ValidationError("E001", "Test error")
        assert err.code == "E001"

    def test_error_message_format(self):
        """ValidationError formats message with code."""
        err = ValidationError("E001", "Test error")
        assert str(err) == "E001: Test error"
