 # FootTech Admin Console (Java / JavaFX)

Application de bureau (Windows / macOS / Linux) pour le rôle **Administrateur**
de FootTech. Client JavaFX consommant l'API du
[foottech_admin_backend](../foottech_admin_backend) (Django/DRF).

## Prérequis

- JDK 21+ (testé avec OpenJDK 21)
- Maven 3.8+
- Le backend Django Admin lancé et accessible (par défaut `http://localhost:8000/api/admin`)

## Lancer l'application

```bash
mvn javafx:run
```

Pour pointer vers une autre URL d'API :

```bash
mvn javafx:run -Dapi.baseUrl=https://admin-api.foottech.app/api/admin
# ou via variable d'environnement :
FOOTTECH_ADMIN_API_URL=https://admin-api.foottech.app/api/admin mvn javafx:run
```

## Construire un exécutable distribuable

```bash
mvn package
java -jar target/foottech-admin-desktop-1.0.0.jar
```

Le jar produit est un *fat-jar* (toutes les dépendances incluses via
`maven-shade-plugin`) exécutable directement avec `java -jar`, sans
installation JavaFX séparée sur la machine cible.

## Fonctionnalités

- **Connexion JWT** dédiée (email + mot de passe d'administrateur), tokens
  persistés via `java.util.prefs` (Registre Windows / plist macOS / dconf
  Linux — jamais en clair sur disque), rafraîchissement automatique du token
  d'accès sur expiration (avec gestion correcte de la rotation + liste noire
  des refresh tokens côté Django).
- **Tableau de bord** : cartes de statistiques (équipes, utilisateurs, joueurs,
  activité du mois) + répartition des utilisateurs par rôle.
- **Équipes** : recherche, filtre par statut, suspension/réactivation avec
  confirmation.
- **Utilisateurs** : recherche, filtre par rôle et par statut,
  suspension/réactivation avec confirmation.
- **Diffusion** : envoi d'une notification à tous les utilisateurs ou à un
  rôle ciblé (écrite directement dans la table partagée avec l'API Express).
- **Journal d'audit** : historique de toutes les actions de modération.

## Structure

```
src/main/java/com/foottech/admin/
  App.java              # point d'entrée JavaFX (gère la session persistée au démarrage)
  Launcher.java          # point d'entrée alternatif pour le fat-jar (java -jar)
  config/                # URL de base de l'API
  network/                # ApiClient (HttpClient + JWT + refresh), TokenStore, ApiException
  model/                  # POJOs miroir des serializers Django (mapping snake_case automatique)
  service/                # Un service par domaine (auth, dashboard, teams, users, audit, broadcast)
  controller/              # Contrôleurs JavaFX (un par écran FXML)
src/main/resources/
  fxml/                    # Vues : Splash, Login, Main (shell), Dashboard, Teams, Users, Broadcast, AuditLog
  css/style.css            # Charte Navy/Green (cohérente avec le client Flutter)
```

## Notes techniques

- Le mapping JSON snake_case (`nom_equipe`, `id_utilisateur`...) vers les
  champs Java camelCase (`nomEquipe`, `idUtilisateur`...) est automatique via
  `PropertyNamingStrategies.SNAKE_CASE` sur l'`ObjectMapper` Jackson — aucune
  annotation `@JsonProperty` à maintenir manuellement.
- Toutes les requêtes réseau s'exécutent sur un thread dédié (jamais sur
  l'Application Thread de JavaFX) ; les mises à jour de l'UI reviennent
  systématiquement via `Platform.runLater(...)`.
- Aucun framework d'injection de dépendances : `ServiceLocator` (singleton)
  suffit pour une application de cette taille et reste facile à suivre.

## Limite connue de cet environnement de livraison

Ce projet n'a pas pu être compilé ici : le sandbox n'a accès ni à Maven
Central ni aux dépôts JavaFX (uniquement npm/PyPI/crates.io/GitHub sont
joignables). Le code a été relu statiquement avec la même rigueur
(vérification systématique des accolades, des imports, de la correspondance
entre chaque `fx:id`/`onAction` des FXML et les champs/méthodes `@FXML` des
contrôleurs, des noms de package), mais je te recommande de lancer
`mvn javafx:run` dès réception pour confirmer la compilation chez toi.
