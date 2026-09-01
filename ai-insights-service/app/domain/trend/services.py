from __future__ import annotations

from datetime import datetime

from app.domain.trend.entities import (
    MIN_DATA_POINTS,
    STABLE_SLOPE_THRESHOLD,
    DataPoint,
    TrendDirection,
    TrendResult,
)


class InsufficientDataError(Exception):
    def __init__(self, provided: int, required: int) -> None:
        self.provided = provided
        self.required = required
        super().__init__(f"Need at least {required} data points, got {provided}")


def _days_since_epoch(dt: datetime) -> float:
    return (dt - datetime(1970, 1, 1, tzinfo=dt.tzinfo)).total_seconds() / 86400.0


def compute_trend(points: list[DataPoint]) -> TrendResult:
    if len(points) < MIN_DATA_POINTS:
        raise InsufficientDataError(len(points), MIN_DATA_POINTS)

    sorted_points = sorted(points, key=lambda p: p.date)
    xs = [_days_since_epoch(p.date) for p in sorted_points]
    ys = [p.value for p in sorted_points]
    n = len(xs)

    mean_x = sum(xs) / n
    mean_y = sum(ys) / n

    ss_xy = sum((x - mean_x) * (y - mean_y) for x, y in zip(xs, ys))
    ss_xx = sum((x - mean_x) ** 2 for x in xs)

    if ss_xx == 0:
        # Toutes les mesures le même jour — aucune tendance temporelle calculable.
        slope_per_day = 0.0
        r_squared = 0.0
    else:
        slope_per_day = ss_xy / ss_xx
        ss_yy = sum((y - mean_y) ** 2 for y in ys)
        r_squared = (ss_xy**2) / (ss_xx * ss_yy) if ss_yy > 0 else 0.0

    slope_per_month = slope_per_day * 30

    if abs(slope_per_month) < STABLE_SLOPE_THRESHOLD:
        direction = TrendDirection.STABLE
    elif slope_per_month > 0:
        direction = TrendDirection.PROGRESSING
    else:
        direction = TrendDirection.DECLINING

    return TrendResult(
        direction=direction,
        slope_per_month=round(slope_per_month, 3),
        r_squared=round(r_squared, 3),
        data_points_used=n,
    )
