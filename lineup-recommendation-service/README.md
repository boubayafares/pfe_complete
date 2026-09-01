# lineup-recommendation-service

Microservice FastAPI de recommandation de composition d'équipe pour FootTech.
Suit le même pattern Clean Architecture que tes autres microservices IA
(Object Detection YOLO11, Tracking, OCR) : domain → application →
infrastructure → presentation, Docker + Kubernetes + GitHub Actions.

## Ce que ce service fait

Calcule le score final de recommandation (`ai_lineup_recommendations`) pour
chaque joueur convoqué à un match, à partir de trois sous-scores déjà
présents dans ton architecture : présence, performance, fatigue. C'est le
même calcul que celui déjà en place côté backend Express (`matches`
module), sorti dans un microservice dédié pour pouvoir :

1. **Calibrer les poids** (présence/performance/fatigue) sur des données
   réelles plutôt que des poids fixés à la main, via VAEP (Valuing Actions
   by Estimating Probabilities) calculé sur StatsBomb Open Data.
2. **Recalibrer périodiquement** sur les données internes du club une fois
   qu'il y a assez d'historique (matchs, évaluations, blessures) — voir
   `scripts/calibrate_from_statsbomb.py` pour la calibration initiale, à
   remplacer plus tard par une calibration sur les données internes.

## Ce que ce service ne fait PAS

Il ne prédit pas la performance d'un joueur qu'il n'a jamais vu — VAEP sur
StatsBomb sert à calibrer une **méthodologie** (quelle importance relative
donner à chaque sous-score), pas à transférer des données de joueurs pros
vers des joueurs U15. Le calcul du score final reste basé sur TES données
(presence_score, performance_score, fatigue_score calculés côté backend
Express à partir de `attendances`, `match_player_stats`, `match_evaluations`).

## Contrat d'intégration avec le backend Express existant

```
POST /api/v1/lineup/recommendations
```

**Requête** (envoyée par `matches.service.ts` lors de
`POST /matches/:id/ai-recommendations`) :

```json
{
  "matchId": 42,
  "players": [
    {
      "playerId": 7,
      "presenceRate": 0.86,
      "recentPerformanceRating": 7.2,
      "acuteChronicWorkloadRatio": 1.05,
      "daysSinceLastMatch": 3
    }
  ]
}
```

**Réponse** — un objet par joueur, directement insérable dans
`ai_lineup_recommendations` (colonnes `match_id`, `player_id`,
`presence_score`, `performance_score`, `fatigue_score`, `score`,
`recommended_status`) :

```json
{
  "matchId": 42,
  "weightsVersion": "statsbomb-calibration-v1",
  "recommendations": [
    {
      "playerId": 7,
      "presenceScore": 86.0,
      "performanceScore": 72.0,
      "fatigueScore": 91.5,
      "finalScore": 81.3,
      "recommendedStatus": "STARTER"
    }
  ]
}
```

Voir `scripts/express_client_snippet.ts` pour l'appel côté backend Express.

## Démarrer en local

```bash
cd lineup-recommendation-service
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.presentation.main:app --reload --port 8100
```

## Calibrer les poids depuis StatsBomb Open Data

```bash
python scripts/calibrate_from_statsbomb.py --competition-id 43 --season-id 106
# écrit app/infrastructure/persistence/weights.json
```

Nécessite `statsbombpy` et `socceraction` (dans `requirements.txt`).
Premier téléchargement lent (données mises en cache localement par
`statsbombpy`).

## Tests

```bash
pytest
```
