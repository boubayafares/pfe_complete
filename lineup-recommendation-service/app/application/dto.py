"""Pydantic request/response schemas — the exact wire contract with the
Express backend (matches.service.ts). Field names are camelCase to match
what the TS side sends/expects without a translation layer on either side.
"""
from __future__ import annotations

from pydantic import BaseModel, Field, field_validator

from app.domain.entities import RecommendedStatus


class PlayerFeaturesDto(BaseModel):
    player_id: int = Field(alias="playerId")
    presence_rate: float = Field(alias="presenceRate", ge=0.0, le=1.0)
    recent_performance_rating: float = Field(alias="recentPerformanceRating", ge=0.0, le=10.0)
    acute_chronic_workload_ratio: float = Field(alias="acuteChronicWorkloadRatio", ge=0.0)
    days_since_last_match: int = Field(alias="daysSinceLastMatch", ge=0)

    model_config = {"populate_by_name": True}


class LineupRecommendationRequest(BaseModel):
    match_id: int = Field(alias="matchId")
    players: list[PlayerFeaturesDto]

    model_config = {"populate_by_name": True}

    @field_validator("players")
    @classmethod
    def non_empty(cls, v: list[PlayerFeaturesDto]) -> list[PlayerFeaturesDto]:
        if not v:
            raise ValueError("players must not be empty")
        return v


class PlayerRecommendationDto(BaseModel):
    player_id: int = Field(serialization_alias="playerId")
    presence_score: float = Field(serialization_alias="presenceScore")
    performance_score: float = Field(serialization_alias="performanceScore")
    fatigue_score: float = Field(serialization_alias="fatigueScore")
    final_score: float = Field(serialization_alias="finalScore")
    recommended_status: RecommendedStatus = Field(serialization_alias="recommendedStatus")

    model_config = {"populate_by_name": True}


class LineupRecommendationResponse(BaseModel):
    match_id: int = Field(serialization_alias="matchId")
    weights_version: str = Field(serialization_alias="weightsVersion")
    recommendations: list[PlayerRecommendationDto]

    model_config = {"populate_by_name": True}
