import pytest

from app.domain.clustering.entities import PlayerFeatureVector
from app.infrastructure.clustering.sklearn_kmeans_repository import (
    InsufficientPlayersError,
    cluster_players,
)


def attackers_and_defenders():
    # 3 profils "buteurs" (buts/match élevé, peu d'assists) et 3 profils
    # "milieux relayeurs" (peu de buts, beaucoup de minutes) — doit donner
    # 2 clusters nettement séparés.
    return [
        PlayerFeatureVector(1, goals_per_match=1.2, assists_per_match=0.1, minutes_per_match=70, height_cm=178, weight_kg=72),
        PlayerFeatureVector(2, goals_per_match=1.0, assists_per_match=0.2, minutes_per_match=65, height_cm=180, weight_kg=75),
        PlayerFeatureVector(3, goals_per_match=1.3, assists_per_match=0.0, minutes_per_match=75, height_cm=176, weight_kg=70),
        PlayerFeatureVector(4, goals_per_match=0.05, assists_per_match=0.6, minutes_per_match=88, height_cm=172, weight_kg=65),
        PlayerFeatureVector(5, goals_per_match=0.1, assists_per_match=0.5, minutes_per_match=90, height_cm=174, weight_kg=68),
        PlayerFeatureVector(6, goals_per_match=0.0, assists_per_match=0.7, minutes_per_match=85, height_cm=170, weight_kg=64),
    ]


def test_clustering_separates_two_clear_profiles():
    result = cluster_players(attackers_and_defenders(), n_clusters=2)
    assert result.n_clusters == 2
    assert len(result.assignments) == 6

    attackers_clusters = {a.cluster_id for a in result.assignments if a.player_id in (1, 2, 3)}
    midfielders_clusters = {a.cluster_id for a in result.assignments if a.player_id in (4, 5, 6)}
    # Chaque groupe doit être interne cohérent (même cluster pour les 3),
    # et les deux groupes doivent être dans des clusters DIFFÉRENTS.
    assert len(attackers_clusters) == 1
    assert len(midfielders_clusters) == 1
    assert attackers_clusters != midfielders_clusters


def test_insufficient_players_raises():
    with pytest.raises(InsufficientPlayersError) as exc_info:
        cluster_players(attackers_and_defenders()[:2], n_clusters=2)
    assert exc_info.value.provided == 2


def test_n_clusters_never_exceeds_player_count():
    result = cluster_players(attackers_and_defenders()[:4], n_clusters=10)
    assert result.n_clusters == 4


def test_distances_are_non_negative():
    result = cluster_players(attackers_and_defenders(), n_clusters=2)
    assert all(a.distance_to_centroid >= 0 for a in result.assignments)
