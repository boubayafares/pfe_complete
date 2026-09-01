from __future__ import annotations

from app.application.dto import ClusterAssignmentDto, ClusteringRequest, ClusteringResponse
from app.domain.clustering.entities import PlayerFeatureVector
from app.infrastructure.clustering.sklearn_kmeans_repository import cluster_players


class ClusterPlayersUseCase:
    def execute(self, request: ClusteringRequest) -> ClusteringResponse:
        vectors = [
            PlayerFeatureVector(
                player_id=p.player_id,
                goals_per_match=p.goals_per_match,
                assists_per_match=p.assists_per_match,
                minutes_per_match=p.minutes_per_match,
                height_cm=p.height_cm,
                weight_kg=p.weight_kg,
            )
            for p in request.players
        ]
        result = cluster_players(vectors, n_clusters=request.n_clusters)
        return ClusteringResponse(
            assignments=[
                ClusterAssignmentDto(
                    player_id=a.player_id,
                    cluster_id=a.cluster_id,
                    distance_to_centroid=a.distance_to_centroid,
                )
                for a in result.assignments
            ],
            n_clusters=result.n_clusters,
            inertia=result.inertia,
        )
