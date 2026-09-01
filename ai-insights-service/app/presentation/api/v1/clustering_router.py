from __future__ import annotations

from fastapi import APIRouter, HTTPException

from app.application.dto import ClusteringRequest, ClusteringResponse
from app.application.use_cases.cluster_players import ClusterPlayersUseCase
from app.infrastructure.clustering.sklearn_kmeans_repository import InsufficientPlayersError

router = APIRouter(prefix="/api/v1/clustering", tags=["clustering"])
_use_case = ClusterPlayersUseCase()


@router.post("/players", response_model=ClusteringResponse, response_model_by_alias=True)
def cluster_players(request: ClusteringRequest) -> ClusteringResponse:
    try:
        return _use_case.execute(request)
    except InsufficientPlayersError as err:
        raise HTTPException(status_code=422, detail=f"Au moins {err.required} joueurs sont nécessaires (reçu: {err.provided}).") from err
