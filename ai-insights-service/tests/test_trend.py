from datetime import datetime, timedelta

import pytest

from app.domain.trend.entities import DataPoint, TrendDirection
from app.domain.trend.services import InsufficientDataError, compute_trend


def make_points(values: list[float], start: datetime | None = None, step_days: int = 15):
    start = start or datetime(2026, 1, 1)
    return [DataPoint(date=start + timedelta(days=i * step_days), value=v) for i, v in enumerate(values)]


def test_progressing_trend_detected():
    points = make_points([5.0, 5.5, 6.0, 6.5, 7.0])
    result = compute_trend(points)
    assert result.direction == TrendDirection.PROGRESSING
    assert result.slope_per_month > 0


def test_declining_trend_detected():
    points = make_points([8.0, 7.5, 7.0, 6.0, 5.0])
    result = compute_trend(points)
    assert result.direction == TrendDirection.DECLINING
    assert result.slope_per_month < 0


def test_flat_values_are_stable():
    points = make_points([6.0, 6.1, 5.9, 6.0, 6.0])
    result = compute_trend(points)
    assert result.direction == TrendDirection.STABLE


def test_insufficient_data_raises():
    points = make_points([5.0, 6.0])
    with pytest.raises(InsufficientDataError) as exc_info:
        compute_trend(points)
    assert exc_info.value.provided == 2
    assert exc_info.value.required == 3


def test_unordered_points_are_sorted_before_computing():
    start = datetime(2026, 1, 1)
    points = [
        DataPoint(date=start + timedelta(days=60), value=7.0),
        DataPoint(date=start, value=5.0),
        DataPoint(date=start + timedelta(days=30), value=6.0),
    ]
    result = compute_trend(points)
    assert result.direction == TrendDirection.PROGRESSING
