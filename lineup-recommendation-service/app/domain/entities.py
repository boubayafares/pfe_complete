"""Domain layer — pure business objects, zero framework/IO dependency.

Mirrors the shape of the `ai_lineup_recommendations` table in
foottech_v2_schema.sql so the output of this service can be inserted
directly by the backend without translation.
"""
from __future__ import annotations

from dataclasses import dataclass
from enum import Enum


class RecommendedStatus(str, Enum):
    STARTER = "STARTER"
    SUBSTITUTE = "SUBSTITUTE"
    NOT_SELECTED = "NOT_SELECTED"


@dataclass(frozen=True)
class ScoreWeights:
    """Relative importance of each sub-score in the final composite score.

    Must sum to 1.0 — enforced in __post_init__ rather than left as an
    implicit assumption, since a silently-unnormalized weight set would
    produce a final_score outside the expected 0-100 range and corrupt
    every downstream `ai_lineup_recommendations.score` value.
    """

    presence: float
    performance: float
    fatigue: float
    version: str = "manual-default"

    def __post_init__(self) -> None:
        total = self.presence + self.performance + self.fatigue
        if not (0.99 <= total <= 1.01):
            raise ValueError(f"ScoreWeights must sum to 1.0, got {total} (version={self.version})")

    @staticmethod
    def default() -> "ScoreWeights":
        # Poids de repli si aucune calibration StatsBomb n'a encore été
        # exécutée (voir scripts/calibrate_from_statsbomb.py) — reflète le
        # même poids implicite que l'ancien scoring pondéré côté backend
        # Express (présence/performance/fatigue à parts égales).
        return ScoreWeights(presence=1 / 3, performance=1 / 3, fatigue=1 / 3, version="equal-default")


@dataclass(frozen=True)
class PlayerFeatures:
    """Input features for one player, as computed by the Express backend
    from its own tables (attendances, match_player_stats, player_injuries).
    """

    player_id: int
    presence_rate: float  # 0.0-1.0, part des entraînements/matchs récents où le joueur était PRESENT
    recent_performance_rating: float  # 0-10, moyenne des match_evaluations récentes
    acute_chronic_workload_ratio: float  # ACWR — charge aiguë (7j) / charge chronique (28j)
    days_since_last_match: int

    def __post_init__(self) -> None:
        if not (0.0 <= self.presence_rate <= 1.0):
            raise ValueError(f"presence_rate must be in [0,1], got {self.presence_rate}")
        if not (0.0 <= self.recent_performance_rating <= 10.0):
            raise ValueError(f"recent_performance_rating must be in [0,10], got {self.recent_performance_rating}")


@dataclass(frozen=True)
class PlayerRecommendation:
    player_id: int
    presence_score: float
    performance_score: float
    fatigue_score: float
    final_score: float
    recommended_status: RecommendedStatus
