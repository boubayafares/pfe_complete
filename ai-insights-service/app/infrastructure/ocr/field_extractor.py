"""Transforme les lignes de texte brut renvoyées par l'OCR en champs
structurés — logique par mots-clés/regex, volontairement simple et
explicable plutôt qu'un modèle d'extraction d'entités entraîné (overkill
pour un document au format à peu près standardisé comme un certificat
médical français).
"""
from __future__ import annotations

import re

from app.domain.document_ocr.entities import DocumentType, ExtractedField

DATE_PATTERN = re.compile(r"\b(\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4})\b")

MEDICAL_KEYWORDS = ["certificat", "aptitude", "contre-indication", "médecin", "docteur", "sport"]
ID_KEYWORDS = ["carte", "identité", "national", "né(e) le", "cin"]


def detect_document_type(lines: list[str]) -> DocumentType:
    joined = " ".join(lines).lower()
    if any(k in joined for k in MEDICAL_KEYWORDS):
        return DocumentType.MEDICAL_CERTIFICATE
    if any(k in joined for k in ID_KEYWORDS):
        return DocumentType.ID_CARD
    return DocumentType.OTHER


def extract_fields(lines: list[tuple[str, float]]) -> list[ExtractedField]:
    fields: list[ExtractedField] = []
    for text, confidence in lines:
        date_match = DATE_PATTERN.search(text)
        if date_match:
            fields.append(ExtractedField(label="date", value=date_match.group(1), confidence=confidence))
    return fields
