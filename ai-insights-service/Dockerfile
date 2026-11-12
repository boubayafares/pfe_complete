# Image "légère" par défaut: trend + clustering + tone (aucune dépendance
# lourde). Les modules transcription/documents nécessitent
# faster-whisper/paddleocr — décommenter dans requirements.txt et
# reconstruire l'image si tu veux les activer (voir README, section
# "Activer les modules IA lourds").

FROM python:3.12-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends libgomp1 && rm -rf /var/lib/apt/lists/*
# libgomp1: requis par scikit-learn (OpenMP) pour KMeans en multi-thread.

COPY requirements-runtime.txt .
RUN python -m pip install --no-cache-dir --upgrade pip==26.2.1 \
    && python -m pip install --no-cache-dir -r requirements-runtime.txt

COPY app ./app

RUN useradd --no-create-home --shell /usr/sbin/nologin appuser
USER appuser

EXPOSE 8300

HEALTHCHECK --interval=30s --timeout=3s CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8300/health')" || exit 1

CMD ["uvicorn", "app.presentation.main:app", "--host", "0.0.0.0", "--port", "8300"]
