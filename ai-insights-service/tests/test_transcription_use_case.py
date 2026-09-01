from pathlib import Path

import pytest

from app.application.use_cases.transcribe_audio import TranscribeAudioUseCase, TranscriptionFailedError
from app.infrastructure.whisper.whisper_client import WhisperUnavailableError


class FakeWhisperClient:
    """Remplace faster-whisper — aucun modèle réel requis en test. Le
    vrai WhisperClient (infrastructure/whisper/whisper_client.py) suit la
    même interface `.transcribe(path) -> (text, lang, confidence, duration)`."""

    def __init__(self, canned=None, raise_unavailable=False):
        self._canned = canned
        self._raise = raise_unavailable

    def transcribe(self, audio_path: Path):
        if self._raise:
            raise WhisperUnavailableError("modèle non chargé (simulé)")
        return self._canned or ("Karim a bien progressé au marquage cette semaine.", "fr", 0.91, 12.4)


def test_transcription_happy_path():
    use_case = TranscribeAudioUseCase(FakeWhisperClient())
    result = use_case.execute(Path("/tmp/fake.wav"))
    assert result.text == "Karim a bien progressé au marquage cette semaine."
    assert result.language_detected == "fr"
    assert result.confidence == 0.91


def test_transcription_unavailable_raises_clear_error():
    use_case = TranscribeAudioUseCase(FakeWhisperClient(raise_unavailable=True))
    with pytest.raises(TranscriptionFailedError):
        use_case.execute(Path("/tmp/fake.wav"))
