# Workflow QA - Jira

Workflow recommandé pour le suivi des bugs/pistes liés au projet FootTech.

## Statuts

```
OPEN → IN PROGRESS → FIXED → TESTING → CLOSED
                          ↓
                    REVIEW (si non conforme)
```

| Statut        | Description                                                         |
|---------------|---------------------------------------------------------------------|
| OPEN          | Bug signalé, non trié.                                              |
| IN PROGRESS   | Développeur en cours de correction (branche + PR).                  |
| FIXED         | Correctif livré, en attente de validation QA.                       |
| TESTING       | QA reproduit le test (Postman / Playwright / manuel).               |
| REVIEW        | Non conforme : retour au dev avec le résultat du test QA.           |
| CLOSED        | Testé et validé.                                                    |

## Champs obligatoires

| Champ            | Exemple                                            |
|------------------|----------------------------------------------------|
| Type             | Bug / Amélioration / Tâche                          |
| Priorité         | Critical / High / Medium / Low                      |
| Environnement    | Local / CI / Production / branche                   |
| Module           | Auth / Dashboard / Entrainements / Matches / IA / Admin |
| Endpoint         | `POST /api/v1/matches/:id/ai-recommendations` sur 8100  |
| Seuil accepté    | Latence P95, statut HTTP, payload attendu           |

## Définition de Done

1. Code corrigé + tests (vitest/pytest) verts.
2. Repro validé via la collection Postman (repli automatique Postman/Newman).
3. Scénario Playwright correspondant vert (si applicable).
4. Aucune régression sur les chemins critiques (login, dashboard, IA).
5. Issue fermée avec preuve : lien test / capture.