from __future__ import annotations

from app.application.dto import ToneAnalysisRequest, ToneAnalysisResponse
from app.domain.tone.services import analyze_tone


class AnalyzeToneUseCase:
    def execute(self, request: ToneAnalysisRequest) -> ToneAnalysisResponse:
        result = analyze_tone(request.comment)
        return ToneAnalysisResponse(flag=result.flag.value, matched_terms=result.matched_terms, suggestion=result.suggestion)
