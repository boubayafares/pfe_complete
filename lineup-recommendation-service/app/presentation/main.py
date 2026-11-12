from __future__ import annotations

import hmac

from fastapi import FastAPI
from fastapi import Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.infrastructure.config import settings
from app.presentation.api.v1.lineup_router import router as lineup_router


def create_app() -> FastAPI:
    app = FastAPI(
        title="FootTech Lineup Recommendation Service",
        version="1.0.0",
        description="Calcule les scores de composition d'équipe (présence/performance/fatigue) "
        "à partir de features fournies par le backend Express. Voir README pour le contrat d'intégration.",
    )

    @app.middleware("http")
    async def require_service_token(request: Request, call_next):
        if request.url.path.startswith("/api/") and settings.service_token:
            supplied = request.headers.get("x-service-token", "")
            if not hmac.compare_digest(supplied, settings.service_token):
                return JSONResponse(status_code=401, content={"detail": "Invalid service token"})
        return await call_next(request)

    if settings.allowed_origins:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=settings.allowed_origins,
            allow_methods=["POST", "GET"],
            allow_headers=["*"],
        )

    app.include_router(lineup_router)

    @app.get("/health", tags=["health"])
    def health() -> dict[str, str]:
        return {"status": "ok"}

    return app


app = create_app()
