from __future__ import annotations

from fastapi import APIRouter, HTTPException

from app.application.dto import TrendRequest, TrendResponse
from app.application.use_cases.detect_trend import DetectTrendUseCase
from app.domain.trend.services import InsufficientDataError

router = APIRouter(prefix="/api/v1/trend", tags=["trend"])
_use_case = DetectTrendUseCase()


@router.post("/detect", response_model=TrendResponse, response_model_by_alias=True)
def detect_trend(request: TrendRequest) -> TrendResponse:
    try:
        return _use_case.execute(request)
    except InsufficientDataError as err:
        raise HTTPException(status_code=422, detail=f"Au moins {err.required} points sont nécessaires (reçu: {err.provided}).") from err
