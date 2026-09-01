from __future__ import annotations

from pathlib import Path

from app.application.dto import DocumentExtractionResponse, ExtractedFieldDto
from app.infrastructure.ocr.field_extractor import detect_document_type, extract_fields
from app.infrastructure.ocr.paddleocr_client import OcrUnavailableError, PaddleOcrClient


class DocumentExtractionFailedError(Exception):
    pass


class ExtractDocumentUseCase:
    def __init__(self, client: PaddleOcrClient) -> None:
        self._client = client

    def execute(self, image_path: Path) -> DocumentExtractionResponse:
        try:
            lines = self._client.extract_text(image_path)
        except OcrUnavailableError as err:
            raise DocumentExtractionFailedError(
                "Le moteur OCR local n'est pas disponible. Vérifiez que paddleocr est installé."
            ) from err

        texts_only = [t for t, _ in lines]
        document_type = detect_document_type(texts_only)
        fields = extract_fields(lines)
        raw_text = "\n".join(texts_only)

        return DocumentExtractionResponse(
            document_type=document_type.value,
            fields=[
                ExtractedFieldDto(label=f.label, value=f.value, confidence=f.confidence)
                for f in fields
            ],
            raw_text=raw_text,
        )
