from __future__ import annotations

import json
from pathlib import Path

from app.domain.entities import ScoreWeights

DEFAULT_WEIGHTS_PATH = Path(__file__).parent / "weights.json"


class WeightsRepository:
    """Loads calibrated ScoreWeights from disk, falling back to the equal
    default if no calibration has been run yet (see
    scripts/calibrate_from_statsbomb.py). Kept as a simple JSON file rather
    than a database table since this microservice owns no data of its own —
    it's a pure computation service, consistent with the other FootTech AI
    microservices (detection/tracking/OCR) which are also stateless.
    """

    def __init__(self, path: Path = DEFAULT_WEIGHTS_PATH) -> None:
        self._path = path

    def load_or_default(self) -> ScoreWeights:
        if not self._path.exists():
            return ScoreWeights.default()
        try:
            data = json.loads(self._path.read_text())
            return ScoreWeights(
                presence=data["presence"],
                performance=data["performance"],
                fatigue=data["fatigue"],
                version=data.get("version", "calibrated-unversioned"),
            )
        except (json.JSONDecodeError, KeyError, ValueError):
            # Un fichier de poids corrompu/mal formé ne doit jamais faire
            # planter l'API de recommandation — on retombe sur le défaut
            # plutôt que de renvoyer une 500 au backend Express.
            return ScoreWeights.default()

    def save(self, weights: ScoreWeights) -> None:
        self._path.write_text(
            json.dumps(
                {
                    "presence": weights.presence,
                    "performance": weights.performance,
                    "fatigue": weights.fatigue,
                    "version": weights.version,
                },
                indent=2,
            )
        )
