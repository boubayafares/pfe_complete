# FootTech — Plateforme de gestion de club de football

FootTech est une plateforme complète de gestion de club de football (PFE), organisée en
microservices pour distinguer les rôles Coach / Adjoint / Joueur / Administrateur.

## Architecture

```
┌─────────────────────────────┐      ┌──────────────────────────────┐
│  foottech_admin_desktop     │      │  front/foottechproject       │
│  (JavaFX, bureau admin)     │      │  (Flutter: mobile + web +    │
└──────────────┬──────────────┘      │   desktop + Linux/macOS)     │
               │ HTTP                 └──────────────┬───────────────┘
               ▼                                     │ HTTP + Socket.IO
┌─────────────────────────────┐      ┌───────────────▼───────────────┐
│  foottech_admin_backend     │      │  back/FoottechBackend-main    │
│  (Django / DRF, :8000)      │      │  API Express + TS (:4000)     │
└──────────────┬──────────────┘      └──────────────┬───────────────┘
               │                                     │
               └────────────┬────────────────────────┘
                            ▼
              ┌──────────────────────────────────┐
              │        PostgreSQL 16 (:5432)     │
              │   Redis 7 (:6379)  (cache/push)  │
              └──────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
┌───────────────┐  ┌────────────────┐  ┌──────────────────┐
│ AI insights   │  │ Lineup reco    │  │  (modules)       │
│ FastAPI :8300 │  │ FastAPI :8100  │  │  actuels/en dur  │
│ tendance,     │  │ composition    │  │  (socle)         │
│ clustering,   │  │ (présence,     │  └──────────────────┘
│ ton, OCR,     │  │ performance,   │
│ transcription │  │ fatigue/VAEP)  │
└───────────────┘  └────────────────┘
```

## Services

| Service | Stack | Port | Rôle |
|---|---|---|---|
| `back/FoottechBackend-main` | Express + TypeScript | 4000 | API principale (auth JWT, équipes, joueurs, entraînements, présences, matchs, calendrier, notifications, dashboard) |
| `front/foottechproject` | Flutter (Riverpod, GoRouter, Dio) | — | Application Coach / Adjoint / Joueur (multi-plateforme) |
| `foottech_admin_backend` | Django 5 + DRF | 8000 | Back office administrateur (supervision plateforme) |
| `foottech_admin_desktop` | Java 21 + JavaFX | — | Application de bureau administrateur |
| `ai-insights-service` | Python 3.12 + FastAPI | 8300 | Tendances joueurs, clustering, ton, transcription, OCR |
| `lineup-recommendation-service` | Python 3.12 + FastAPI | 8100 | Recommandation de composition d'équipe |

Base de données : **PostgreSQL 16** — schéma dans `foottech_v2_schema.sql` (32 tables dans le schéma `platform` + vue `player_season_bilan`).

## Démarrage rapide (Docker)

Prérequis : Docker + `docker compose`.

1. Copier l'environnement et le remplir :
   ```bash
   cp .env.example .env
   # éditer .env (DB_PASSWORD, JWT_ACCESS_SECRET, JWT_REFRESH_SECRET, etc.)
   ```
2. Lancer toute la plateforme :
   ```bash
   docker compose up --build
   ```
3. Accès :
   - API Express : http://localhost:4000 (docs Swagger : `/docs` hors prod)
   - Django admin : http://localhost:8000/admin-site/
   - AI insights : http://localhost:8300/health
   - Lineup : http://localhost:8100/health

## Démarrage local (sans Docker)

### API Express
```bash
cd back/FoottechBackend-main
npm install
cp .env.example .env        # renseigner DB + JWT
npm run dev                 # ou: npm run build && npm start
```

### Application Flutter
```bash
cd front/foottechproject
flutter pub get
cp .env.example .env        # API_BASE_URL, SOCKET_URL, APP_NAME
flutter run
```

### Back office (Django)
```bash
cd foottech_admin_backend/foottech_admin_backend
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

## Intégration continue

Deux pipelines sont fournis (fonctionnellement équivalents) :
- **GitHub Actions** : `.github/workflows/ci.yml`
- **GitLab CI** : `.gitlab-ci.yml`

Chacun construit le backend, l'admin, le front Flutter et les deux services IA, puis
pousse les images Docker (registry GitHub ou GitLab).

## Tests

| Niveau | Emplacement | Contenu |
|---|---|---|
| API E2E (smoke) | `tests/cypress`, `tests/playwright`, `tests/selenium`, `tests/postman` | health check, auth (401/200), RBAC IA (Playwright), runs Newman en CI |
| Charge | `tests/jmeter` | Paramétrable `-Jthreads` (10 / 50 / 100 / 500 users) |
| Spécification OpenAPI | `tests/openapi/foottech_api.yaml` | Contrat de l'API |
| Unitaires backend | `back/FoottechBackend-main` (`npm test` = build + **Vitest**, 26 tests) | client IA, INT-01..07, PDF, schémas |
| Unitaires IA | `ai-insights-service`, `lineup-recommendation-service` (`pytest`) | 26 + 10 tests : logique métier, clustering, contrat lineup |

## Notes d'intégration

- **Django admin** : les modèles du back office pointent sur les tables réelles de l'API Express,
  dans le schéma **`platform`** (`managed=False`, lecture seule — aucune structure Express modifiée).
  Une migration idempotente crée des **vues legacy** (`public.utilisateur`, `public.match`, …)
  pour la rétrocompatibilité. Les suspensions/bannissements sont stockés localement
  (`moderation_suspension`), la diffusion d'annonces insère dans `platform.notifications`.
- **Push notifications** : le backend enregistre les tokens FCM (`POST /api/v1/notifications/push-token`)
  et les utilise à la création de chaque notification. Firebase doit être configuré via
  `FIREBASE_*` dans `.env` (sinon les push sont logués en mode dev).
- **SMS OTP** : les codes sont envoyés via Twilio si `TWILIO_*` est renseigné, sinon logués
  (mode dev).
- **Rapport de match PDF** : généré côté serveur via `POST /api/v1/matches/:id/report/generate`
  (bibliothèque `pdfkit`), stocké sous `/uploads/reports/` et servi statiquement.
- **IA de composition** : `POST /api/v1/matches/:id/ai-recommendations` (rôles Coach/Adjoint).
  L'API Express agrège les features (présence 10 dernières séances, perf 5 derniers matchs,
  ACWR proxy 7j/28j, jours depuis le dernier match), les envoie au
  `lineup-recommendation-service` (`LINEUP_SERVICE_URL`, **timeout 5 s** garanti) puis
  stocke les scores normalisés (0-1). Erreurs contrôlées : 404 match, 400 payload invalide,
  502 réponse invalidée, 503 service injoignable, 504 dépassement du délai.
- **Schémas Mermaid** : `diagrammes/mermaid/` (architecture, flux IA lineup, dataflow, déploiement/CI/CD).
# pfe_complete
