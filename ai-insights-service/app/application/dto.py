from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field

# --- Trend ---


class TrendDataPointDto(BaseModel):
    date: datetime
    value: float = Field(ge=0, le=10)


class TrendRequest(BaseModel):
    player_id: int = Field(alias="playerId")
    points: list[TrendDataPointDto]

    model_config = {"populate_by_name": True}


class TrendResponse(BaseModel):
    player_id: int = Field(serialization_alias="playerId")
    direction: str
    slope_per_month: float = Field(serialization_alias="slopePerMonth")
    r_squared: float = Field(serialization_alias="rSquared")
    data_points_used: int = Field(serialization_alias="dataPointsUsed")

    model_config = {"populate_by_name": True}


# --- Clustering ---


class PlayerFeatureDto(BaseModel):
    player_id: int = Field(alias="playerId")
    goals_per_match: float = Field(alias="goalsPerMatch")
    assists_per_match: float = Field(alias="assistsPerMatch")
    minutes_per_match: float = Field(alias="minutesPerMatch")
    height_cm: float = Field(alias="heightCm")
    weight_kg: float = Field(alias="weightKg")

    model_config = {"populate_by_name": True}


class ClusteringRequest(BaseModel):
    players: list[PlayerFeatureDto]
    n_clusters: int = Field(default=3, alias="nClusters", ge=2, le=10)

    model_config = {"populate_by_name": True}


class ClusterAssignmentDto(BaseModel):
    player_id: int = Field(serialization_alias="playerId")
    cluster_id: int = Field(serialization_alias="clusterId")
    distance_to_centroid: float = Field(serialization_alias="distanceToCentroid")

    model_config = {"populate_by_name": True}


class ClusteringResponse(BaseModel):
    assignments: list[ClusterAssignmentDto]
    n_clusters: int = Field(serialization_alias="nClusters")
    inertia: float

    model_config = {"populate_by_name": True}


# --- Tone ---


class ToneAnalysisRequest(BaseModel):
    comment: str = Field(min_length=0, max_length=2000)


class ToneAnalysisResponse(BaseModel):
    flag: str
    matched_terms: list[str] = Field(serialization_alias="matchedTerms")
    suggestion: str | None

    model_config = {"populate_by_name": True}


# --- Transcription ---


class TranscriptionResponse(BaseModel):
    text: str
    language_detected: str = Field(serialization_alias="languageDetected")
    confidence: float
    duration_seconds: float = Field(serialization_alias="durationSeconds")

    model_config = {"populate_by_name": True}


# --- Document OCR ---


class ExtractedFieldDto(BaseModel):
    label: str
    value: str
    confidence: float


class DocumentExtractionResponse(BaseModel):
    document_type: str = Field(serialization_alias="documentType")
    fields: list[ExtractedFieldDto]
    raw_text: str = Field(serialization_alias="rawText")

    model_config = {"populate_by_name": True}
