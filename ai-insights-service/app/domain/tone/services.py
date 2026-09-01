"""Analyse de ton par lexique — pas de LLM nécessaire pour le cas de base.
Volontairement simple et explicable : un coach doit pouvoir comprendre
immédiatement pourquoi un commentaire a été signalé, ce qu'un modèle
boîte noire ne permettrait pas facilement pour ce cas d'usage précis.
"""
from __future__ import annotations

from app.domain.tone.entities import ToneAnalysisResult, ToneFlag

# Termes durs — pensé pour des commentaires sur des MINEURS, seuil bas
# volontairement (mieux vaut un faux positif occasionnel qu'un vrai
# commentaire blessant qui passe).
HARSH_TERMS_FR = ["nul", "mauvais joueur", "inutile", "catastrophique", "aucun niveau", "à revoir complètement", "décevant"]
HARSH_TERMS_AR = ["سيء", "لا فائدة", "ضعيف جدا", "كارثي"]

GENERIC_TERMS_FR = ["bien", "ok", "moyen", "correct", "ça va", "rien à dire"]
GENERIC_TERMS_AR = ["جيد", "عادي", "لا شيء"]

SUGGESTION_TEMPLATE = (
    "Essaie de reformuler en te concentrant sur un point concret à améliorer "
    "plutôt qu'un jugement général — ex: 'perd trop souvent le ballon sous "
    "pression, à travailler en conduite de balle' plutôt qu'un simple 'mauvais'."
)


def _find_matches(text_lower: str, terms: list[str]) -> list[str]:
    return [t for t in terms if t in text_lower]


def analyze_tone(comment: str) -> ToneAnalysisResult:
    stripped = comment.strip()
    if not stripped:
        return ToneAnalysisResult(flag=ToneFlag.EMPTY, matched_terms=[], suggestion=None)

    text_lower = stripped.lower()

    harsh_matches = _find_matches(text_lower, HARSH_TERMS_FR + HARSH_TERMS_AR)
    if harsh_matches:
        return ToneAnalysisResult(flag=ToneFlag.TOO_HARSH, matched_terms=harsh_matches, suggestion=SUGGESTION_TEMPLATE)

    # Un commentaire "générique" n'est signalé que s'il est aussi COURT —
    # "bien" seul est générique, mais "bien géré la pression en fin de
    # match, a su relancer proprement" contient "bien" sans être générique.
    word_count = len(stripped.split())
    generic_matches = _find_matches(text_lower, GENERIC_TERMS_FR + GENERIC_TERMS_AR)
    if generic_matches and word_count <= 4:
        return ToneAnalysisResult(flag=ToneFlag.TOO_GENERIC, matched_terms=generic_matches, suggestion=None)

    return ToneAnalysisResult(flag=ToneFlag.OK, matched_terms=[], suggestion=None)
