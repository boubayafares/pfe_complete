# Template de bug (copier-coller dans Jira)

**Summary** : [Module] court descriptif

**Description** :
- **Comportement attendu** :
- **Comportement constaté** :

**Reproduction** (étapes) :
1.
2.

**Environnement** : `local / CI / prod` — branche, commit, OS.

**Résultats** :
- Statut HTTP : `200 / 400 / 403 / 404 / 502 / 503 / 504 / 500`
- Réponse (payload) :
- Logs serveur :

**Preuve de test** :
- [ ] Reproduction Postman → `tests/postman/foottech_collection.json`
- [ ] Test automatisé Vitest (`matches.service.test.ts` cas INT-xx) ou pytest
- [ ] Scénario Playwright : `tests/playwright/specs/ai-recommendations.spec.ts`
- [ ] Charge JMeter : `tests/jmeter/foottech_load_test.jmx` (niveau + résultats)

**Impact** : latence / dispo / sécurité / données — impacté : coach / adjoint / joueur / admin.

**Définition de Done** (à cocher au CLOSE) :
- [ ] Correctif + tests verts (`npm test`, `pytest`)
- [ ] Repli Postman OK
- [ ] Playwright OK
- [ ] Fermé avec preuve