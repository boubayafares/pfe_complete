from __future__ import annotations

from dataclasses import dataclass
from enum import Enum


class ToneFlag(str, Enum):
    OK = "OK"
    TOO_HARSH = "TOO_HARSH"
    TOO_GENERIC = "TOO_GENERIC"
    EMPTY = "EMPTY"


@dataclass(frozen=True)
class ToneAnalysisResult:
    flag: ToneFlag
    matched_terms: list[str]
    suggestion: str | None
