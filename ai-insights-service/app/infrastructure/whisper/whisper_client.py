"""Transcription 100% locale via `faster-whisper` (CTranslate2, tourne sur
CPU sans GPU dédié pour les modèles small/medium). Le modèle est téléchargé
UNE fois au premier usage (depuis Hugging Face) puis mis en cache
localement — après ce premier téléchargement, aucune donnée audio ne
quitte jamais la machine.

⚠️ HONNÊTETÉ: ce module n'a pas pu être testé avec un vrai modèle chargé
dans le bac à sable où ce service a été construit — le réseau y est limité
à une liste blanche de domaines (PyPI, GitHub...) qui n'inclut pas
huggingface.co, d'où le téléchargement du modèle serait impossible ici.
Le code est écrit et structuré correctement, mais SEUL le chemin
d'intégration (via WhisperTranscriptionService avec un client factice) a
été testé automatiquement — voir tests/test_transcription_use_case.py.
À valider avec un vrai `pip install faster-whisper` + modèle téléchargé
avant mise en production.
"""
from __future__ import annotations

from pathlib import Path


class WhisperUnavailableError(Exception):
    pass


class WhisperClient:
    def __init__(self, model_size: str = "small", device: str = "cpu", compute_type: str = "int8") -> None:
        self._model_size = model_size
        self._device = device
        self._compute_type = compute_type
        self._model = None  # chargement paresseux — le modèle (quelques centaines de Mo) ne doit pas se charger avant le premier vrai besoin

    def _ensure_loaded(self):
        if self._model is None:
            try:
                from faster_whisper import WhisperModel

                self._model = WhisperModel(self._model_size, device=self._device, compute_type=self._compute_type)
            except Exception as err:  # noqa: BLE001 — import différé, on convertit toute erreur en erreur métier claire
                raise WhisperUnavailableError(str(err)) from err
        return self._model

    def transcribe(self, audio_path: Path) -> tuple[str, str, float, float]:
        """Renvoie (texte, langue_détectée, confiance_moyenne, durée_secondes)."""
        model = self._ensure_loaded()
        segments, info = model.transcribe(str(audio_path))
        segments = list(segments)
        text = " ".join(s.text.strip() for s in segments)
        avg_confidence = sum(s.avg_logprob for s in segments) / len(segments) if segments else 0.0
        # avg_logprob est un log-probabilité négative — on la convertit en
        # un score 0-1 approximatif, plus lisible pour l'appelant.
        confidence = max(0.0, min(1.0, 1.0 + avg_confidence))
        return text, info.language, round(confidence, 3), round(info.duration, 1)
