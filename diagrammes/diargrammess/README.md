# Diagrammes UML FootTech — couverture des 74 User Stories

Ce dossier contient les sources PlantUML UTF-8. Les diagrammes sont organisés par type et chaque User Story est reliée à cinq vues UML dans `traceability.csv`.

## Inventaire

- Cas d'utilisation : 16 diagrammes
- Séquences : 16 diagrammes
- Activités : 16 diagrammes
- Classes : 10 diagrammes
- États / actions : 6 diagrammes
- Total : 64 fichiers PlantUML
- Couverture : US-01 à US-74, sans doublon ni omission

## Arborescence

- `use_cases/` : diagramme global et un diagramme par épopée.
- `classes/` : vue globale et classes détaillées par domaine.
- `sequences/` : séquence globale et une séquence par épopée, avec un groupe par User Story.
- `activities/` : activité globale et une activité par épopée.
- `states_actions/` : cycles de vie, transitions et actions métier.
- `traceability.csv` : correspondance exacte User Story → cinq diagrammes.

## Régénération

1. Exécuter `python generate_all_uml.py` pour reconstruire les sources.
2. Exécuter PlantUML sur le dossier pour produire les PNG : `plantuml -charset UTF-8 -tpng '**/*.puml'`.

Les diagrammes décrivent le comportement du projet FootTech et non un modèle générique. Ils incluent notamment le contrôle JWT/RBAC, l'isolation par équipe, la transaction atomique des présences, Express/FastAPI/Django, Flutter, JavaFX, Socket.IO, FCM et Twilio.
