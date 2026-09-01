"""Domain layer — détection de tendance sur une série de notes/mesures
dans le temps. Logique pure (régression linéaire simple, pas de dépendance
lourde) — testable sans aucune I/O.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from enum import Enum


class TrendDirection(str, Enum):
    PROGRESSING = "PROGRESSING"
    STABLE = "STABLE"
    DECLINING = "DECLINING"


@dataclass(frozen=True)
class DataPoint:
    date: datetime
    value: float  # note d'évaluation (0-10), ou toute autre métrique numérique de player_season_profile


@dataclass(frozen=True)
class TrendResult:
    direction: TrendDirection
    slope_per_month: float  # pente de la régression, unité = valeur/mois
    r_squared: float  # qualité de l'ajustement — proche de 0 = tendance peu fiable (bruit)
    data_points_used: int


# En-dessous de ce nombre de points, toute tendance calculée serait du
# bruit statistique — mieux vaut dire "pas assez de données" que d'inventer
# une tendance sur 2 points.
MIN_DATA_POINTS = 3

# Seuil de pente (valeur/mois) en-dessous duquel on considère que c'est du
# bruit plutôt qu'une vraie progression/régression.
STABLE_SLOPE_THRESHOLD = 0.15
