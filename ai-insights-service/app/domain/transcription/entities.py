from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class TranscriptionResult:
    text: str
    language_detected: str
    confidence: float
    duration_seconds: float
