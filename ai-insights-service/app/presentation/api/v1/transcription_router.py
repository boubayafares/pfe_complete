from __future__ import annotations

import shutil
import tempfile
from pathlib import Path

from fastapi import APIRouter, File, HTTPException, UploadFile

from app.application.dto import TranscriptionResponse
from app.application.use_cases.transcribe_audio import TranscribeAudioUseCase, TranscriptionFailedError
from app.infrastructure.whisper.whisper_client import WhisperClient

router = APIRouter(prefix="/api/v1/transcription", tags=["transcription"])
_client = WhisperClient()
_use_case = TranscribeAudioUseCase(_client)


@router.post("/transcribe", response_model=TranscriptionResponse, response_model_by_alias=True)
async def transcribe(audio: UploadFile = File(...)) -> TranscriptionResponse:
    with tempfile.NamedTemporaryFile(suffix=Path(audio.filename or "audio.wav").suffix, delete=True) as tmp:
        shutil.copyfileobj(audio.file, tmp)
        tmp.flush()
        try:
            return _use_case.execute(Path(tmp.name))
        except TranscriptionFailedError as err:
            raise HTTPException(status_code=503, detail=str(err)) from err
