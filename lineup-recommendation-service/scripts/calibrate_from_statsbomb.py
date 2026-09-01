"""CLI: recalibre les poids présence/performance/fatigue depuis StatsBomb
Open Data et les écrit dans app/infrastructure/persistence/weights.json.

Exemple (Coupe du Monde féminine 2023, disponible en accès libre):
    python scripts/calibrate_from_statsbomb.py --competition-id 72 --season-id 107 --max-matches 20

Utilise `statsbombpy competitions()` pour lister les compétitions/saisons
disponibles en accès libre si tu ne connais pas les IDs à l'avance.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.infrastructure.persistence.weights_repository import WeightsRepository  # noqa: E402
from app.infrastructure.statsbomb.vaep_calibrator import calibrate  # noqa: E402


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--competition-id", type=int, required=True)
    parser.add_argument("--season-id", type=int, required=True)
    parser.add_argument("--max-matches", type=int, default=None, help="Limite le nombre de matchs traités (plus rapide pour tester)")
    args = parser.parse_args()

    print(f"Calibration en cours sur compétition={args.competition_id}, saison={args.season_id}...")
    weights = calibrate(args.competition_id, args.season_id, max_matches=args.max_matches)
    print(f"Poids calibrés: presence={weights.presence}, performance={weights.performance}, fatigue={weights.fatigue}")

    WeightsRepository().save(weights)
    print(f"Écrit dans {WeightsRepository().load_or_default() and 'app/infrastructure/persistence/weights.json'}")


if __name__ == "__main__":
    main()
