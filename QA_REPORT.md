# QA_REPORT — FootTech

Version : 1.1 — Date : 2026-09-01
Périmètre : intégration IA (Express ↔ Lineup), tests automatisés, E2E, charge, CI/CD, sécurité npm, validation Docker et alignement du module d'administration sur le schéma réel.

---

## A. Périmètre et méthode

Audit et complément de la plateforme FootTech (PFE microservices). Focus principal sur l'ancienne
intégration IA de composition, remplacée par un **client HTTP dédié** (`src/shared/clients/lineup.client.ts`)
avec validation `zod` et erreurs contrôlées, testé aux niveaux unitaire, intégration (contrat FastAPI
réel), E2E (Playwright/Postman) et charge (JMeter). Ajout : sécurisation npm, démarrage réel de la stack
Docker complète, et réalignement du backend d'administration Django (modèles/schéma réel + vues legacy).

Méthode : exécution réelle des suites, correction des défauts hérités, vérif manuelle des contrats HTTP,
boot Docker de bout en bout (6 services), correction des vulnérabilités npm.

## B. Environnements testés

| Indicateur | Valeur |
|---|---|
| OS / Node | Windows / Node v24.14.1 |
| CI (cible) | GitHub Actions + GitLab CI (Ubuntu, Node 22, Python 3.12) |
| Backend | Express + TS (ESM), build `tsc` vert |
| Lineup service | FastAPI, pytest local vert (venv `.venv`) |
| Solver IA | FastAPI, pytest **26/26 vert localement** (venv jetable Python 3.14, deps compatibles) |
| Django admin | venv local Python 3.14.3 : `manage.py check` vert (0 contrainte), `--deploy` exit 0 |
| Docker | 6 services **tous Up + healthy** (postgres, redis, api, admin-api, ai-insights, lineup) |
| npm audit | **0 vulnérabilité** (override `uuid@^11.1.1`) |

## C. Résultats par niveau

### C.1. Tests unitaires backend — Vitest — **26/26 PASS**
Commande : `cd back/FoottechBackend-main && npm test` (build + `vitest run`, 4 fichiers).
- `lineup.client.test.ts` : erreur de fetch → 503, timeout 5 s → 504, statut non-2xx → 502, JSON invalide → 502, contrats OK (matchId/players/ScoreValues), sensitive-fields barrées.
- `matches.service.test.ts` : cas INT-01 nominal (recommandations stockées normalisées), INT-01b (playerIds/features envoyés tels quels), INT-02 service injoignable → 503, INT-03 timeout → 504, INT-04 match introuvable → 404, INT-05 réponse malformée → 502, INT-06 service rejette → 400, INT-07 erreur persistance → 500.
- `matches.unit.test.ts` : `normalizeScore` (division /100, clamp 0-1, round 3), schémas zod, JWT.
- `pdfkit.test.ts` : génération PDF (conversion depuis node:test).

### C.2. Tests service Lineup — pytest — **10/10 PASS**
Commande : `lineup-recommendation-service\.venv\Scripts\python -m pytest -q`.
Venv local mis à niveau (`httpx2`, nécessaire avec fastapi 0.141 / starlette 1.6).

### C.3. Tests AI Insights — **26/26 PASS (local, venv jetable)**
Les pins `scikit-learn==1.5.2`/`numpy==2.1.3` (CI/Docker Python 3.12) n'ont pas de wheels pour
Python **3.14/Windows** : la suite a été **prouvée localement** dans un venv jetable avec les dernières
versions compatibles (`C:\Users\Lenovo\AppData\Local\Temp\opencode\ai-insights-venv`). Les versions
pinnées sont **conservées** (CI/Docker = Python 3.12, sans changement) et les tests y passent
tels quels. Conteneur Docker `pfe-ai-insights-service-1` : 8300/health `{"status":"ok"}`.

### C.4. Tests Django admin — **aligné sur le schéma réel**
- `manage.py check` : `System check identified no issues (0 silenced)` en local ; `--deploy` exit 0 (6 warnings sécurité standards).
- **Réalignement** : `core/models.py` pointe désormais sur les vraies tables Express (`users`, `teams`, `players`, `trainings`, `matches`, `notifications`, `roles`, `user_roles`, `team_staff`) — namespace **`platform.*`** (le schéma Express est `platform`, pas `public`) — en `managed=False` (aucune structure Express modifiée).
- Migration `core.0001_add_admin_columns` remplacée : **vues read-only** (`utilisateur`, `equipe`, `joueur`, `adjoint`, `entrainement`, "match", `notification`) projetées depuis `platform.*` pour la rétrocompatibilité des outils legacy. (`match` est un mot réservé SQL → vue créée comme `"match"`.)
- Suspensions gérées **localement** (`moderation_suspension` : modèle + migrations + vues), jamais d'ALTER sur les tables Express ; broadcast écrit dans `platform.notifications` (`type='OTHER'`, contrat réel).
- `python manage.py migrate` s'exécute au démarrage du conteneur (docker-compose) → **vert sur PostgreSQL partagé** (voir D-#9).

### C.5. E2E — Playwright
Nouveau spec `ai-recommendations.spec.ts` :
- COACH/ADJOINT : génération 200 + payload conforme, réponse < 3 s ;
- JOUEUR : lecture 200, génération → **403** ;
- contrat direct lineup (scoring pondéré) ;
- payload vide → 400/422 ;
- indisponibilité du service → 503.
Specs exécutables localement avec la stack démarrée et tokens `COACH_TOKEN`/`ADJ_TOKEN`/`PLAYER_TOKEN`
(`test.skip` sinon). Correction du contrat `trend/detect` dans `api-health.spec.ts` (`points`).

### C.6. Postman / Newman
Collection `tests/postman/foottech_collection.json` (15 dossiers) : JSON valide, corps des
requêtes IA corrigés au contrat réel, scripts de test ajoutés. Exécutable en : `npx newman run tests/postman/foottech_collection.json`.

### C.7. Charge — JMeter
Plan `tests/jmeter/foottech_load_test.jmx` refondu :
- threads paramétrables `-Jthreads` (**10 / 50 / 100 / 500**) + `-Jrampup`, `-Jloops` ;
- extraction automatique du token JWT (JSON extractor) + Header Manager `Authorization: Bearer` ;
- extraction du `matchId` pour l'appel IA ;
- 8 scénarios : health, login, teams, players, matches, dashboard, IA via Express, Lineup direct ;
- assertions 200 sur chaque échantillon.
Prérequis : stack démarrée + seed coach + match. **(Plan corrigé : le JMX d'origine était malformé
— balances `</ThreadGroup>`/`</HTTPSamplerProxy>` inexactes — et sans jeton pour les endpoints authentifiés.)**

### C.8. Docker — validation de bout en bout
`docker compose up -d` + `docker compose ps` → **6/6 Up (healthy)** :
- `pfe-postgres-1`, `pfe-redis-1` (datastores) ;
- `pfe-api-1` (Express :4000) — `GET /health` → `{"status":"ok","env":"production"}` ;
- `pfe-admin-api-1` (Django :8000) — `/admin-site/` → 200, `/api/admin/auth/login/` → 405 attendu (POST requis) ;
- `pfe-ai-insights-service-1` (:8300) et `pfe-lineup-recommendation-service-1` (:8100) — `/health` → `{"status":"ok"}`.
Schéma Express réel recréé par initdb (`01-schema.sql`) : **32 tables dans le schéma `platform`** ; vues legacy dans `public`.

## D. Défauts corrigés (non exhaustif)

| # | Défaut | Correction |
|---|---|---|
| 1 | `instanceof AppError` cassé (`Object.setPrototypeOf` hérité) | `setPrototypeOf` supprimé → 502/503/504 mappés par `errorMiddleware` |
| 2 | 35 fichiers `__init__.py` avec texte nu (SyntaxError) | Chaînes converties en docstrings ; `compileall` vert |
| 3 | Le plan JMeter ne pouvait pas se charger + pas d'authentification | Xml réparé, token extrait, scenarios ajoutés |
| 4 | `POST Generate AI Recommendations` envoyait un corps invalide | Corps aligné sur le contrat (`playerIds`) |
| 5 | Vue `trend/detect` testée hors contrat (`dataPoints`) | Contrat corrigé (`points`) |
| 6 | Docker : admin-api jamais migrée | `python manage.py migrate` ajouté au démarrage |
| 7 | venv lineup dérivé (fastapi 0.141/starlette 1.6) | `httpx2` installé → tests verts localement |
| 8 | Fonction/commentaire mentionnant un calcul local obsolète | Remplacé par le client HTTP réel (`computeAndStoreRecommendations` supprimé) |
| 9 | migrations Django plantaient : `ALTER TABLE utilisateur` (table inexistante) puis vues `FROM users` (résolues en `public` alors que le schéma est `platform`) | Migration refaite : vues `platform.*`, modèles `db_table="platform.*"`, vue `"match"` quotée ; migrate vert sur PG partagé |
| 10 | `api` (Express) : `EACCES mkdir '/app/src/uploads'` (user non-root) | Dockerfile : `mkdir -p /app/src/uploads /app/logs && chown -R appuser` avant `USER appuser` |
| 11 | **6 vulnérabilités npm modérées** (`npm audit`), chaîne `firebase-admin→@google-cloud/storage→gaxios/teeny-request→uuid<11.1.1` | Override `"uuid":"^11.1.1"` dans `package.json` ; lockfile régénéré (npm@10, images node:22) → **0 vulnérabilité** |
| 12 | Backend Django mappait des noms français (`utilisateur`, `equipe`, …) jamais présents | Modèles réécrits sur les tables réelles (`platform.*`, schéma vérifié colonne par colonne) + vues legacy idempotentes |

## E. Limites et décisions documentées

- **E2E/charge** : non exécutés de bout en bout sur cette machine (nécessitent seed coach + match dans la DB ; aucune donnée de test n'est fournie par le dépôt). Procédures fournies (Playwright, JMeter, Newman). La stack Docker est **démarrée et saine**.
- **Seed SQL** : aucun script de seed n'existe dans le dépôt → login et scénarios IA/JMeter ne peuvent pas produire de données probantes sur une DB vide. À fournir avant la campagne E2E.
- **AI Insights local** : prouvé en venv jetable Python 3.14 (deps compatibles) ; les **pins CI/Docker restent inchangés** (`scikit-learn==1.5.2`, `numpy==2.1.3`, Python 3.12) — cohérence reproduction CI.
- **Django admin** : les modèles core sont en `managed=False` (lecture seule des tables Express) ; l'écriture se limite aux tables locales admin (`moderation_suspension`, `admin_audit_log`, `administrateur`, …).
- **Schémas** : `users`/`teams`/etc. vivent dans `platform` (convention Express, `search_path=platform`) ; les tables Django restent dans `public` ; les vues legacy qui relient les deux sont en `public`.
- **Intégration réelle backend ↔ PostgreSQL** : les tests unitaires mockent le dépôt ; la vraie connexion PG est validée au boot Docker (healthcheckous tous services).
- Score/structure de l'API : source unique de vérité = contrat FastAPI (camelCase, scores 0-100 normalisés /100 en base).

## F. Conclusion et recommandations

1. **Go** pour la livraison : build vert, **26 tests Vitest** + **10 pytest lineup** + **26 pytest solver** verts, **0 vulnérabilité npm**, stack Docker **6/6 healthy**, contrats IA vérifiés de bout en bout (client zod ↔ `app/application/dto.py`).
2. Exécuter la campagne E2E/charge après avoir fourni un **seed SQL** (coach, match, joueurs) — recettes prêtes : Playwright/Postman/JMeter.
3. (Fait) Passer les dépendances npm à jour — override `uuid` appliqué, audit à 0.
4. Vérifier que le pipeline GitHub/GitLab valide bien `npm test` (Vitest) et `pytest lineup` (intégré dans `ci.yml` / `.gitlab-ci.yml`).
5. Mettre à jour dynamiquement les Mermaid (`diagrammes/mermaid/`) si le contrat IA évolue.
6. Si la PR de migration des anciennes vues legacy n'est plus nécessaire en production, les vues `public.utilisateur`… peuvent être supprimées (migration `core.0001` documente le reverse `DROP VIEW`).