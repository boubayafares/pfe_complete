from __future__ import annotations

from app.application.dto import TrendRequest, TrendResponse
from app.domain.trend.entities import DataPoint
from app.domain.trend.services import compute_trend


class DetectTrendUseCase:
    def execute(self, request: TrendRequest) -> TrendResponse:
        points = [DataPoint(date=p.date, value=p.value) for p in request.points]
        result = compute_trend(points)
        return TrendResponse(
            player_id=request.player_id,
            direction=result.direction.value,
            slope_per_month=result.slope_per_month,
            r_squared=result.r_squared,
            data_points_used=result.data_points_used,
        )
