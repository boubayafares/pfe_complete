from __future__ import annotations

from fastapi import APIRouter

from app.application.dto import ToneAnalysisRequest, ToneAnalysisResponse
from app.application.use_cases.analyze_tone import AnalyzeToneUseCase

router = APIRouter(prefix="/api/v1/tone", tags=["tone"])
_use_case = AnalyzeToneUseCase()


@router.post("/analyze", response_model=ToneAnalysisResponse, response_model_by_alias=True)
def analyze_tone(request: ToneAnalysisRequest) -> ToneAnalysisResponse:
    return _use_case.execute(request)
