"""Calibrates ScoreWeights.performance vs ScoreWeights.presence using VAEP
(Valuing Actions by Estimating Probabilities) computed on StatsBomb Open
Data via the `socceraction` library.

HONNÊTETÉ IMPORTANTE sur ce que cette calibration peut et ne peut PAS faire :
StatsBomb Open Data ne contient AUCUNE donnée de charge d'entraînement, de
repos ou de blessure — il n'y a donc rien dans ce dataset pour calibrer le
poids `fatigue`, qui reste sur sa valeur de référence interne (voir
ScoreWeights.default) jusqu'à ce que le club ait accumulé assez d'historique
ACWR/blessures réel pour le calibrer sur SES propres données. Ce script ne
calibre donc que le poids relatif présence vs performance, à partir d'une
heuristique simple (variance du signal = pouvoir discriminant), pas d'un
véritable modèle causal. C'est un point de départ défendable, pas une
vérité statistique — à recalibrer sur données internes dès que possible.

⚠️ L'API de `socceraction` a changé plusieurs fois par le passé (spadl.statsbomb
vs data.statsbomb selon la version installée). Si les imports ci-dessous
échouent avec ta version installée, consulte la doc socceraction pour l'API
équivalente de ta version — c'est un script offline exécuté ponctuellement
en local, pas un composant critique du runtime de l'API.
"""
from __future__ import annotations

import pandas as pd
from sklearn.ensemble import GradientBoostingClassifier

from app.domain.entities import ScoreWeights
from app.infrastructure.statsbomb.statsbomb_client import StatsBombClient

MIN_ACTIONS_FOR_TRAINING = 500  # garde-fou: pas assez de données pour un modèle VAEP fiable en-dessous


def _actions_for_match(client: StatsBombClient, match_id: int) -> pd.DataFrame:
    import socceraction.spadl as spadl
    from socceraction.spadl import statsbomb as spadl_statsbomb

    events = client.events(match_id)
    home_team_id = events.loc[events["team"].notna(), "team"].iloc[0]  # approximation raisonnable pour un script offline
    actions = spadl_statsbomb.convert_to_actions(events, home_team_id=home_team_id)
    return spadl.add_names(actions)


def _train_vaep_and_score(actions: pd.DataFrame) -> pd.DataFrame:
    import socceraction.vaep.features as fs
    import socceraction.vaep.formula as vaepformula
    import socceraction.vaep.labels as lab

    gamestates = fs.gamestates(actions, nb_prev_actions=3)
    features = pd.concat(
        [
            fs.actiontype_onehot(gamestates),
            fs.result_onehot(gamestates),
            fs.bodypart_onehot(gamestates),
            fs.startlocation(gamestates),
            fs.endlocation(gamestates),
            fs.movement(gamestates),
        ],
        axis=1,
    )
    labels = pd.concat([lab.scores(actions), lab.concedes(actions)], axis=1)

    scores_model = GradientBoostingClassifier(n_estimators=50, max_depth=3)
    concedes_model = GradientBoostingClassifier(n_estimators=50, max_depth=3)
    scores_model.fit(features, labels["scores"])
    concedes_model.fit(features, labels["concedes"])

    p_scores = scores_model.predict_proba(features)[:, 1]
    p_concedes = concedes_model.predict_proba(features)[:, 1]
    values = vaepformula.value(actions, pd.Series(p_scores, index=actions.index), pd.Series(p_concedes, index=actions.index))
    return pd.concat([actions[["player_id", "team_id", "time_seconds"]], values], axis=1)


def calibrate(competition_id: int, season_id: int, max_matches: int | None = None) -> ScoreWeights:
    client = StatsBombClient()
    matches = client.list_matches(competition_id, season_id)
    match_ids = matches["match_id"].tolist()
    if max_matches:
        match_ids = match_ids[:max_matches]

    all_actions = []
    for match_id in match_ids:
        try:
            all_actions.append(_actions_for_match(client, match_id))
        except Exception:  # noqa: BLE001 — un match mal formé ne doit pas arrêter toute la calibration
            continue

    actions = pd.concat(all_actions, ignore_index=True)
    if len(actions) < MIN_ACTIONS_FOR_TRAINING:
        raise ValueError(
            f"Only {len(actions)} actions collected across {len(match_ids)} matches — "
            f"increase max_matches or pick a competition/season with more data."
        )

    scored = _train_vaep_and_score(actions)

    # Proxy "performance": VAEP total par joueur, normalisé par le temps de
    # jeu observé dans l'échantillon (évite de favoriser artificiellement
    # les joueurs qui ont simplement joué plus de minutes).
    per_player = scored.groupby("player_id").agg(
        vaep_total=("vaep_value", "sum"),
        seconds_played=("time_seconds", "count"),
    )
    per_player["vaep_per_action"] = per_player["vaep_total"] / per_player["seconds_played"].clip(lower=1)

    # Proxy "présence": part du temps total de l'échantillon que ce joueur
    # a effectivement disputée.
    per_player["presence_share"] = per_player["seconds_played"] / per_player["seconds_played"].sum()

    # Heuristique de calibration: le sous-score dont la variance
    # (normalisée) est la plus grande porte le plus d'information pour
    # différencier les joueurs -> il mérite un poids plus élevé. Simple,
    # transparent, mais explicitement une heuristique — voir avertissement
    # en tête de fichier.
    var_performance = per_player["vaep_per_action"].var()
    var_presence = per_player["presence_share"].var()
    total_var = var_performance + var_presence
    performance_weight_raw = var_performance / total_var if total_var > 0 else 0.5
    presence_weight_raw = 1 - performance_weight_raw

    # Le poids fatigue n'est PAS calibrable depuis StatsBomb (pas de donnée
    # de charge/repos dans ce dataset) — on lui laisse un tiers fixe et on
    # redistribue le reste entre présence/performance selon l'heuristique
    # ci-dessus.
    fatigue_weight = 1 / 3
    remaining = 1 - fatigue_weight
    performance_weight = remaining * performance_weight_raw
    presence_weight = remaining * presence_weight_raw

    return ScoreWeights(
        presence=round(presence_weight, 3),
        performance=round(performance_weight, 3),
        fatigue=round(fatigue_weight, 3),
        version=f"statsbomb-vaep-competition{competition_id}-season{season_id}",
    )
