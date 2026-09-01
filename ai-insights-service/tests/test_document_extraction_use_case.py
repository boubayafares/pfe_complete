from pathlib import Path

import pytest

from app.application.use_cases.extract_document import DocumentExtractionFailedError, ExtractDocumentUseCase
from app.infrastructure.ocr.paddleocr_client import OcrUnavailableError


class FakeOcrClient:
    def __init__(self, lines=None, raise_unavailable=False):
        self._lines = lines
        self._raise = raise_unavailable

    def extract_text(self, image_path: Path):
        if self._raise:
            raise OcrUnavailableError("moteur OCR non chargé (simulé)")
        return self._lines or []


def test_medical_certificate_detected():
    lines = [
        ("CERTIFICAT MEDICAL", 0.95),
        ("Aptitude au sport en compétition", 0.89),
        ("Fait le 12/08/2026", 0.92),
    ]
    use_case = ExtractDocumentUseCase(FakeOcrClient(lines=lines))
    result = use_case.execute(Path("/tmp/fake.jpg"))
    assert result.document_type == "MEDICAL_CERTIFICATE"
    assert any(f.value == "12/08/2026" for f in result.fields)


def test_id_card_detected():
    lines = [("CARTE NATIONALE D'IDENTITE", 0.9), ("Né(e) le 03/04/2011", 0.88)]
    use_case = ExtractDocumentUseCase(FakeOcrClient(lines=lines))
    result = use_case.execute(Path("/tmp/fake.jpg"))
    assert result.document_type == "ID_CARD"


def test_unrecognized_document_type():
    lines = [("texte quelconque", 0.5)]
    use_case = ExtractDocumentUseCase(FakeOcrClient(lines=lines))
    result = use_case.execute(Path("/tmp/fake.jpg"))
    assert result.document_type == "OTHER"


def test_ocr_unavailable_raises_clear_error():
    use_case = ExtractDocumentUseCase(FakeOcrClient(raise_unavailable=True))
    with pytest.raises(DocumentExtractionFailedError):
        use_case.execute(Path("/tmp/fake.jpg"))
