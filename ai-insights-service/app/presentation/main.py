from __future__ import annotations

import hmac
import os

from fastapi import FastAPI
from fastapi import Request
from fastapi.responses import JSONResponse

from app.presentation.api.v1.clustering_router import router as clustering_router
from app.presentation.api.v1.documents_router import router as documents_router
from app.presentation.api.v1.tone_router import router as tone_router
from app.presentation.api.v1.transcription_router import router as transcription_router
from app.presentation.api.v1.trend_router import router as trend_router


def create_app() -> FastAPI:
    app = FastAPI(
        title="FootTech AI Insights Service",
        version="1.0.0",
        description="5 modules d'analyse: tendance joueur, clustering, ton des commentaires, "
        "transcription vocale locale, extraction de documents. Voir README pour le détail par module.",
    )

    service_token = os.environ.get("AI_INSIGHTS_SERVICE_TOKEN", "")

    @app.middleware("http")
    async def require_service_token(request: Request, call_next):
        if request.url.path.startswith("/api/") and service_token:
            supplied = request.headers.get("x-service-token", "")
            if not hmac.compare_digest(supplied, service_token):
                return JSONResponse(status_code=401, content={"detail": "Invalid service token"})
        return await call_next(request)

    app.include_router(trend_router)
    app.include_router(clustering_router)
    app.include_router(tone_router)
    app.include_router(transcription_router)
    app.include_router(documents_router)

    @app.get("/health", tags=["health"])
    def health() -> dict[str, str]:
        return {"status": "ok"}

    return app


app = create_app()
