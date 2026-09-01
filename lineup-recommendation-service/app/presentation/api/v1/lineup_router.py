from __future__ import annotations

from fastapi import APIRouter, Depends

from app.application.dto import LineupRecommendationRequest, LineupRecommendationResponse
from app.application.use_cases.compute_lineup_recommendation import ComputeLineupRecommendationUseCase
from app.infrastructure.persistence.weights_repository import WeightsRepository

router = APIRouter(prefix="/api/v1/lineup", tags=["lineup"])


def get_use_case() -> ComputeLineupRecommendationUseCase:
    return ComputeLineupRecommendationUseCase(WeightsRepository())


@router.post("/recommendations", response_model=LineupRecommendationResponse, response_model_by_alias=True)
def compute_recommendations(
    request: LineupRecommendationRequest,
    use_case: ComputeLineupRecommendationUseCase = Depends(get_use_case),
) -> LineupRecommendationResponse:
    return use_case.execute(request)
