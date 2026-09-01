from __future__ import annotations

import shutil
import tempfile
from pathlib import Path

from fastapi import APIRouter, File, HTTPException, UploadFile

from app.application.dto import DocumentExtractionResponse
from app.application.use_cases.extract_document import DocumentExtractionFailedError, ExtractDocumentUseCase
from app.infrastructure.ocr.paddleocr_client import PaddleOcrClient

router = APIRouter(prefix="/api/v1/documents", tags=["documents"])
_client = PaddleOcrClient()
_use_case = ExtractDocumentUseCase(_client)


@router.post("/extract", response_model=DocumentExtractionResponse, response_model_by_alias=True)
async def extract_document(image: UploadFile = File(...)) -> DocumentExtractionResponse:
    with tempfile.NamedTemporaryFile(suffix=Path(image.filename or "doc.jpg").suffix, delete=True) as tmp:
        shutil.copyfileobj(image.file, tmp)
        tmp.flush()
        try:
            return _use_case.execute(Path(tmp.name))
        except DocumentExtractionFailedError as err:
            raise HTTPException(status_code=503, detail=str(err)) from err
