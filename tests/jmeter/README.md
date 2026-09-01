# FootTech JMeter Load Tests

## Prerequisites
- Apache JMeter 5.6+
- Java 17+
- **Stack démarrée** : backend Express (`:4000`), lineup-recommendation-service (`:8100`), PostgreSQL peuplé avec au moins un coach (`coach@test.com`) et un match (le token et le `matchId` sont extraits automatiquement par le plan).

## Running Tests

Charge configurable avec `-Jthreads` (montée en charge ramp 30s, 10 itérations) :

| Niveau            | Commande |
|-------------------|----------|
| Smoke (10 users)  | `jmeter -n -t foottech_load_test.jmx -Jthreads=10 -l smoke.jtl -e -o ./report-smoke` |
| Load test (50)    | `jmeter -n -t foottech_load_test.jmx -Jthreads=50 -l load.jtl -e -o ./report-load` |
| Stress test (100) | `jmeter -n -t foottech_load_test.jmx -Jthreads=100 -l stress.jtl -e -o ./report-stress` |
| Breakpoint (500)  | `jmeter -n -t foottech_load_test.jmx -Jthreads=500 -l breakpoint.jtl -e -o ./report-breakpoint` |

Autres paramètres : `-Jrampup=60`, `-Jloops=5`.

### View Report
Open `report-*/index.html` in a browser after test completion.

## Test Scenarios
1. **Health Check** - `GET /health` (disponibilité API)
2. **Authentication** - `POST /api/v1/auth/login` (extrait `data.accessToken` via JSON extractor)
3. **Team Operations** - `GET /api/v1/teams`
4. **Player Operations** - `GET /api/v1/players`
5. **Match Operations** - `GET /api/v1/matches` (extrait `data[0].id` → `matchId`)
6. **Dashboard** - `GET /api/v1/dashboard/me`
7. **IA Lineup via Express** - `POST /api/v1/matches/${matchId}/ai-recommendations` (prouve l'intégration Express → lineup : timeout 5 s garanti côté serveur)
8. **Lineup Service direct** - `POST :8100/api/v1/lineup/recommendations` (contrat camelCase, scores 0-100)

Un **Header Manager** injecte `Authorization: Bearer ${accessToken}` sur tous les échantillons authentifiés. Chaque échantillon est protégé par une assertion de code 200.

## Notes
- Le login utilise le coach de seed `coach@test.com / Test1234!` — adaptez `HTTPSampler` login si le seed est différent.
- Si la base n'a pas encore de match, l'extracteur `$.data[0].id` reste vide : le niveau “IA Lineup via Express” renverra un 400/404 attendu.
- Le plan est volontairement simple (mock-free) : il mesure la vraie chaîne Express → FastAPI → PostgreSQL.