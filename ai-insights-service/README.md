# ai-insights-service

5 modules d'analyse pour FootTech, regroupés dans un seul service FastAPI
(Clean Architecture, même pattern que `lineup-recommendation-service` et
`faq-assistant-service`) plutôt que 5 microservices séparés — plus simple
à opérer, chaque module reste indépendant en interne (son propre dossier
`domain/`).

## Modules

| Module | Endpoint | Compatible avec (schéma FootTech) | Dépendance lourde ? |
|---|---|---|---|
| Tendance joueur | `POST /api/v1/trend/detect` | `match_evaluations.note`, `player_season_profile` dans le temps | Non (calcul pur) |
| Clustering | `POST /api/v1/clustering/players` | `player_season_profile`, `match_player_stats` | Non (scikit-learn) |
| Ton des commentaires | `POST /api/v1/tone/analyze` | `match_evaluations.commentaire`, `exercise_proposals.reviewComment` | Non (lexique) |
| Transcription vocale | `POST /api/v1/transcription/transcribe` | `training_sheets`, `match_evaluations` | Oui (faster-whisper) |
| Extraction de documents | `POST /api/v1/documents/extract` | `player_guardians`, `player_school_info`, certificats médicaux | Oui (paddleocr) |

## ⚠️ Honnêteté sur ce qui a été réellement vérifié

- **Tendance, clustering, ton** : testés avec de vraies exécutions (26
  tests, `pytest`, y compris un vrai K-means scikit-learn sur des données
  synthétiques qui sépare correctement deux profils de joueurs distincts).
  Serveur lancé et interrogé en conditions réelles.
- **Transcription et documents OCR** : le code suit l'API réelle de
  `faster-whisper`/`paddleocr`, mais **n'a pas pu être exécuté avec un vrai
  modèle chargé** dans le bac à sable où ce service a été construit — le
  réseau y est restreint à une liste blanche (PyPI, GitHub...) qui
  n'inclut ni huggingface.co (modèles Whisper) ni les CDN PaddlePaddle
  (modèles PaddleOCR). Seul le chemin d'intégration est testé, avec des
  clients factices (`tests/test_transcription_use_case.py`,
  `tests/test_document_extraction_use_case.py`). **À valider avec de
  vrais modèles avant mise en production.**

## Activer les modules IA lourds (transcription, documents)

```bash
pip install faster-whisper paddleocr paddlepaddle
```

Décommenter les lignes correspondantes dans `requirements.txt` avant de
reconstruire l'image Docker. Le premier appel à chaque module télécharge
son modèle (quelques centaines de Mo pour Whisper `small`, un peu plus
pour PaddleOCR) — prévoir un volume Docker persistant pour ne pas
retélécharger à chaque redémarrage de conteneur (voir `docker-compose.yml`).

## Contrats d'intégration (backend Express)

### Tendance joueur
```json
POST /api/v1/trend/detect
{"playerId": 7, "points": [{"date": "2026-01-01T00:00:00", "value": 6.5}, ...]}

→ {"playerId": 7, "direction": "PROGRESSING", "slopePerMonth": 1.27, "rSquared": 0.99, "dataPointsUsed": 3}
```
`direction` ∈ `PROGRESSING` / `STABLE` / `DECLINING`. Minimum 3 points
(`422` sinon) — en-dessous, toute tendance calculée serait du bruit.

### Clustering de joueurs
```json
POST /api/v1/clustering/players
{"players": [{"playerId": 1, "goalsPerMatch": 1.2, "assistsPerMatch": 0.1, "minutesPerMatch": 70, "heightCm": 178, "weightKg": 72}, ...], "nClusters": 3}

→ {"assignments": [{"playerId": 1, "clusterId": 0, "distanceToCentroid": 0.42}, ...], "nClusters": 3, "inertia": 4.1}
```
Minimum 4 joueurs. Les features sont standardisées automatiquement avant
clustering — pas besoin de normaliser côté appelant.

### Ton d'un commentaire
```json
POST /api/v1/tone/analyze
{"comment": "Ce joueur est nul."}

→ {"flag": "TOO_HARSH", "matchedTerms": ["nul"], "suggestion": "Essaie de reformuler..."}
```
`flag` ∈ `OK` / `TOO_HARSH` / `TOO_GENERIC` / `EMPTY`. Suggéré comme
vérification avant enregistrement d'une évaluation (`match_evaluations`)
ou d'un commentaire de review (`exercise_proposals`) — jamais bloquant,
juste indicatif pour le coach.

### Transcription vocale
```
POST /api/v1/transcription/transcribe
Content-Type: multipart/form-data
audio: <fichier .wav/.mp3>

→ {"text": "...", "languageDetected": "fr", "confidence": 0.91, "durationSeconds": 12.4}
```
`503` si le moteur Whisper n'est pas chargé/disponible — jamais de 500
opaque.

### Extraction de document
```
POST /api/v1/documents/extract
Content-Type: multipart/form-data
image: <fichier .jpg/.png>

→ {"documentType": "MEDICAL_CERTIFICATE", "fields": [{"label": "date", "value": "12/08/2026", "confidence": 0.92}], "rawText": "..."}
```
`503` si le moteur OCR n'est pas chargé/disponible.

## 🔴 Rappel sécurité (documents)

`player_guardians`, `player_school_info` et les certificats médicaux
concernent des **mineurs**. Même traités localement (aucune donnée
envoyée à un tiers), ces fichiers exigent :
- un chiffrement au repos (pas de stockage en clair du fichier uploadé
  au-delà du traitement immédiat — voir `tempfile.NamedTemporaryFile`
  dans `documents_router.py`, qui supprime le fichier automatiquement
  après la requête),
- une politique de rétention explicite côté club (combien de temps
  garder le document source vs seulement les champs extraits),
- **aucune reconnaissance faciale n'est implémentée ici** — voir la
  discussion précédente sur les risques RGPD spécifiques aux mineurs.

## Démarrer en local

```bash
pip install -r requirements.txt
uvicorn app.presentation.main:app --reload --port 8300
pytest -v
```

## Avec Docker

```bash
docker compose up --build
```
