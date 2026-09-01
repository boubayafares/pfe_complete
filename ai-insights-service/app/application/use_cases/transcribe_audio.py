from __future__ import annotations

from pathlib import Path

from app.application.dto import TranscriptionResponse
from app.infrastructure.whisper.whisper_client import WhisperClient, WhisperUnavailableError


class TranscriptionFailedError(Exception):
    pass


class TranscribeAudioUseCase:
    def __init__(self, client: WhisperClient) -> None:
        self._client = client

    def execute(self, audio_path: Path) -> TranscriptionResponse:
        try:
            text, language, confidence, duration = self._client.transcribe(audio_path)
        except WhisperUnavailableError as err:
            raise TranscriptionFailedError(
                "Le moteur de transcription locale n'est pas disponible. "
                "Vérifiez que faster-whisper est installé et que le modèle a été téléchargé."
            ) from err

        return TranscriptionResponse(text=text, language_detected=language, confidence=confidence, duration_seconds=duration)
