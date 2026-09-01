from __future__ import annotations

from dataclasses import dataclass
from enum import Enum


class DocumentType(str, Enum):
    MEDICAL_CERTIFICATE = "MEDICAL_CERTIFICATE"
    ID_CARD = "ID_CARD"
    OTHER = "OTHER"


@dataclass(frozen=True)
class ExtractedField:
    label: str
    value: str
    confidence: float


@dataclass(frozen=True)
class DocumentExtractionResult:
    document_type: DocumentType
    fields: list[ExtractedField]
    raw_text: str
