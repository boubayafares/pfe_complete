from __future__ import annotations

import numpy as np
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

from app.domain.clustering.entities import ClusterAssignment, ClusteringResult, PlayerFeatureVector

MIN_PLAYERS_FOR_CLUSTERING = 4  # en-dessous, le clustering n'a pas de sens statistique


class InsufficientPlayersError(Exception):
    def __init__(self, provided: int, required: int) -> None:
        self.provided = provided
        self.required = required
        super().__init__(f"Need at least {required} players, got {provided}")


def _to_matrix(vectors: list[PlayerFeatureVector]) -> np.ndarray:
    return np.array(
        [[v.goals_per_match, v.assists_per_match, v.minutes_per_match, v.height_cm, v.weight_kg] for v in vectors]
    )


def cluster_players(vectors: list[PlayerFeatureVector], n_clusters: int = 3, random_state: int = 42) -> ClusteringResult:
    if len(vectors) < MIN_PLAYERS_FOR_CLUSTERING:
        raise InsufficientPlayersError(len(vectors), MIN_PLAYERS_FOR_CLUSTERING)

    n_clusters = min(n_clusters, len(vectors))  # jamais plus de clusters que de joueurs

    raw_matrix = _to_matrix(vectors)
    # Standardisation OBLIGATOIRE: sans elle, "minutes_per_match" (échelle
    # 0-90) écraserait totalement "goals_per_match" (échelle 0-3) dans le
    # calcul de distance euclidienne du K-means — un joueur qui joue
    # beaucoup mais ne marque jamais serait artificiellement "proche" d'un
    # buteur qui joue peu, uniquement à cause de l'échelle des unités.
    scaler = StandardScaler()
    scaled_matrix = scaler.fit_transform(raw_matrix)

    model = KMeans(n_clusters=n_clusters, random_state=random_state, n_init=10)
    labels = model.fit_predict(scaled_matrix)
    distances = model.transform(scaled_matrix)  # distance de chaque point à chaque centroïde

    assignments = [
        ClusterAssignment(
            player_id=vectors[i].player_id,
            cluster_id=int(labels[i]),
            distance_to_centroid=round(float(distances[i][labels[i]]), 3),
        )
        for i in range(len(vectors))
    ]

    return ClusteringResult(assignments=assignments, n_clusters=n_clusters, inertia=round(float(model.inertia_), 3))
