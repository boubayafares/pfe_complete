from __future__ import annotations

from app.application.dto import (
    LineupRecommendationRequest,
    LineupRecommendationResponse,
    PlayerFeaturesDto,
    PlayerRecommendationDto,
)
from app.domain.entities import PlayerFeatures, ScoreWeights
from app.domain.services import compute_recommendation
from app.infrastructure.persistence.weights_repository import WeightsRepository


class ComputeLineupRecommendationUseCase:
    def __init__(self, weights_repository: WeightsRepository) -> None:
        self._weights_repository = weights_repository

    def execute(self, request: LineupRecommendationRequest) -> LineupRecommendationResponse:
        weights = self._weights_repository.load_or_default()
        recommendations = [self._score_one(p, weights) for p in request.players]
        return LineupRecommendationResponse(
            match_id=request.match_id,
            weights_version=weights.version,
            recommendations=recommendations,
        )

    @staticmethod
    def _score_one(dto: PlayerFeaturesDto, weights: ScoreWeights) -> PlayerRecommendationDto:
        features = PlayerFeatures(
            player_id=dto.player_id,
            presence_rate=dto.presence_rate,
            recent_performance_rating=dto.recent_performance_rating,
            acute_chronic_workload_ratio=dto.acute_chronic_workload_ratio,
            days_since_last_match=dto.days_since_last_match,
        )
        result = compute_recommendation(features, weights)
        return PlayerRecommendationDto(
            player_id=result.player_id,
            presence_score=result.presence_score,
            performance_score=result.performance_score,
            fatigue_score=result.fatigue_score,
            final_score=result.final_score,
            recommended_status=result.recommended_status,
        )
