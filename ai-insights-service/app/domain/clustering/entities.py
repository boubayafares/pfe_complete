from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class PlayerFeatureVector:
    """Vecteur de features construit depuis player_season_profile +
    match_player_stats — chaque dimension doit être numérique et sur une
    échelle comparable (voir infrastructure/clustering pour la normalisation,
    qui n'est PAS de la responsabilité du domaine)."""

    player_id: int
    goals_per_match: float
    assists_per_match: float
    minutes_per_match: float
    height_cm: float
    weight_kg: float


@dataclass(frozen=True)
class ClusterAssignment:
    player_id: int
    cluster_id: int
    distance_to_centroid: float  # plus bas = profil "typique" de son cluster


@dataclass(frozen=True)
class ClusteringResult:
    assignments: list[ClusterAssignment]
    n_clusters: int
    inertia: float  # somme des distances au carré — utile pour comparer plusieurs valeurs de k
