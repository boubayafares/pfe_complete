# L'API de scoring elle-même (app/domain, app/application, app/presentation)
# n'a besoin que de FastAPI/Pydantic — statsbombpy/socceraction/sklearn/pandas
# ne servent qu'au script de calibration offline (scripts/calibrate_from_statsbomb.py),
# exécuté ponctuellement en local, jamais dans ce conteneur. D'où l'usage de
# requirements-runtime.txt ici plutôt que requirements.txt (~40MB vs ~600MB+ d'image).

FROM python:3.12-slim AS runtime

WORKDIR /app

COPY requirements-runtime.txt .
RUN python -m pip install --no-cache-dir --upgrade pip==26.2.1 \
    && python -m pip install --no-cache-dir -r requirements-runtime.txt

COPY app ./app

# Le fichier de poids calibrés (s'il existe) doit être copié explicitement —
# généré en local via scripts/calibrate_from_statsbomb.py puis committé, ou
# monté en volume/ConfigMap en production (voir k8s/configmap.yaml).
COPY app/infrastructure/persistence/weights.jso[n] ./app/infrastructure/persistence/

RUN groupadd --gid 10001 appgroup \
    && useradd --uid 10001 --gid appgroup --no-create-home --shell /usr/sbin/nologin appuser
USER 10001:10001

EXPOSE 8100

HEALTHCHECK --interval=30s --timeout=3s CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8100/health')" || exit 1

CMD ["uvicorn", "app.presentation.main:app", "--host", "0.0.0.0", "--port", "8100"]
