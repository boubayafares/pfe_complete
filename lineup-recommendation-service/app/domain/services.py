"""Domain service: the actual scoring math. No I/O, no framework — trivially
unit-testable, and this is exactly the logic ported from the backend's
existing weighted présence/performance/fatigue scoring, just made
configurable via ScoreWeights instead of hardcoded fractions.
"""
from __future__ import annotations

from .entities import PlayerFeatures, PlayerRecommendation, RecommendedStatus, ScoreWeights

# Seuils de sélection — au-delà du score, un joueur est recommandé titulaire ;
# en-dessous, remplaçant ; en-dessous du plancher, non retenu. Ce sont des
# valeurs de départ raisonnables, à ajuster une fois assez d'historique
# interne accumulé pour comparer aux décisions réelles du coach.
STARTER_THRESHOLD = 70.0
SUBSTITUTE_THRESHOLD = 40.0


def _fatigue_score(acwr: float, days_since_last_match: int) -> float:
    """Convertit l'ACWR + le repos récent en un score de fraîcheur 0-100.

    La zone "sweet spot" ACWR 0.8-1.3 (Gabbett) est la zone à risque de
    blessure la plus basse ET la zone de forme la plus haute — on la
    récompense donc, tout en pénalisant progressivement de part et
    d'autre (sous-charge = perte de forme, surcharge = risque de blessure).
    """
    if acwr < 0.8:
        acwr_component = 60 + (acwr / 0.8) * 20  # sous-entraînement: 60-80
    elif acwr <= 1.3:
        acwr_component = 100 - abs(acwr - 1.05) * 40  # sweet spot: proche de 100
    else:
        overshoot = min(acwr - 1.3, 1.0)
        acwr_component = max(0.0, 80 - overshoot * 80)  # surcharge: chute rapide vers 0

    rest_component = min(days_since_last_match / 4.0, 1.0) * 100  # plateau après 4 jours de repos
    return round(0.7 * acwr_component + 0.3 * rest_component, 1)


def compute_recommendation(features: PlayerFeatures, weights: ScoreWeights) -> PlayerRecommendation:
    presence_score = round(features.presence_rate * 100, 1)
    performance_score = round(features.recent_performance_rating * 10, 1)
    fatigue_score = _fatigue_score(features.acute_chronic_workload_ratio, features.days_since_last_match)

    final_score = round(
        weights.presence * presence_score
        + weights.performance * performance_score
        + weights.fatigue * fatigue_score,
        1,
    )

    if final_score >= STARTER_THRESHOLD:
        status = RecommendedStatus.STARTER
    elif final_score >= SUBSTITUTE_THRESHOLD:
        status = RecommendedStatus.SUBSTITUTE
    else:
        status = RecommendedStatus.NOT_SELECTED

    return PlayerRecommendation(
        player_id=features.player_id,
        presence_score=presence_score,
        performance_score=performance_score,
        fatigue_score=fatigue_score,
        final_score=final_score,
        recommended_status=status,
    )
