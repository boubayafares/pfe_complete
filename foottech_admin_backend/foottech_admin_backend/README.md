# FootTech Admin Backend (Django)

Backend Django/DRF dédié au rôle **Administrateur** de la plateforme FootTech.
C'est un service séparé de l'API Express (Coach/Adjoint/Joueur) : il possède
son propre modèle d'utilisateur et sa propre authentification JWT, mais se
connecte à **la même base PostgreSQL** pour superviser les équipes, les
utilisateurs et l'activité de la plateforme.

## Pourquoi un service séparé plutôt qu'un 4e rôle dans l'API Express ?

- Un administrateur gère la plateforme entière (toutes les équipes), pas un
  club en particulier — son périmètre et ses permissions n'ont rien à voir
  avec ceux d'un Coach/Adjoint/Joueur.
- Authentification totalement indépendante (table `administrateur` dédiée,
  JWT signé avec un secret différent) : compromettre un compte joueur ne
  donne aucun accès à ce service, et inversement.
- Django admin (`/admin-site/`) offre gratuitement une interface
  d'administration interne pour les opérations ponctuelles.

## Installation

```bash
python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt

cp .env.example .env               # renseigner DATABASE_URL (même base que l'API Express) et DJANGO_SECRET_KEY

# Applique UNIQUEMENT les colonnes additives nécessaires (actif) sur les
# tables utilisateur/equipe déjà créées par sql/schema.sql du backend Express,
# puis crée les tables propres à ce service (administrateur, journal d'audit,
# tables Django standard : auth, sessions, blacklist JWT...)
python manage.py migrate

python manage.py createsuperuser --email admin@foottech.app
python manage.py runserver
```

⚠️ **Prérequis** : le schéma de `foottech-backend/sql/schema.sql` (API Express)
doit déjà être appliqué sur la base cible avant de lancer `migrate` ici — ce
service ne fait qu'ajouter deux colonnes (`actif`) aux tables `utilisateur`
et `equipe`, il ne les crée pas.

## Endpoints

### Authentification (`/api/admin/auth/`)
| Méthode | Route | Description |
|---|---|---|
| POST | `login/` | Connexion par email — retourne `access` + `refresh` |
| POST | `refresh/` | Renouvelle l'access token |
| GET/PATCH | `me/` | Profil de l'administrateur connecté |
| POST | `change-password/` | Changement de mot de passe |
| GET | `/api/admin/administrateurs/` | Liste des administrateurs |
| POST | `/api/admin/administrateurs/` | Créer un administrateur (super-admin uniquement) |

### Supervision (`/api/admin/`)
| Méthode | Route | Description |
|---|---|---|
| GET | `dashboard/` | KPIs plateforme : équipes, utilisateurs par rôle, joueurs actifs, matchs du mois... |
| GET | `teams/?search=&actif=&categorie=` | Liste de tous les clubs, avec coach et effectif |
| GET | `teams/<id>/` | Détail d'un club |
| GET | `teams/<id>/players/` | Effectif d'un club |
| POST | `teams/<id>/suspend/` \| `activate/` | Suspendre / réactiver un club (`{"raison": "..."}`) |
| GET | `users/?search=&role=&actif=` | Tous les utilisateurs, tous clubs confondus |
| POST | `users/<id>/suspend/` \| `activate/` | Suspendre / réactiver un compte |
| GET | `matches/?statut=&id_equipe=` | Supervision des matchs (lecture seule) |
| GET | `trainings/?statut=&id_equipe=` | Supervision des entraînements (lecture seule) |
| POST | `broadcast/` | Diffuser une notification (`{"message": "...", "cible_role": "TOUS\|COACH\|ADJOINT\|JOUEUR"}`) |
| GET | `audit-logs/?action=&cible_type=` | Historique de toutes les actions de modération |

Toutes les routes (sauf `login/`, `refresh/`) nécessitent
`Authorization: Bearer <access_token>`.

### Interface Django admin
`http://localhost:8000/admin-site/` — utile pour des opérations ponctuelles
(recherche rapide, consultation du journal d'audit en lecture seule).

## Structure

```
foottech_admin_backend/
  foottech_admin/        # settings.py, urls.py (config du projet)
  administrateurs/        # Modèle Administrateur (AUTH_USER_MODEL), login JWT, /me/
  core/                    # Miroir non managé (managed=False) des tables Express :
                           #   Utilisateur, Equipe, Joueur, Adjoint, Entrainement, Match, Notification
                           # + migration additive (colonnes `actif`)
  moderation/              # AuditLog (managed) + dashboard, gestion équipes/utilisateurs, broadcast
  requirements.txt
```

## Validé

Ce projet a été testé de bout en bout (login → JWT avec claims personnalisés →
dashboard agrégé → suspension d'équipe → journal d'audit → diffusion de
notification écrite dans la table `notification` partagée avec l'API
Express) avant livraison.

## Notes de sécurité

- `SIMPLE_JWT` utilise un secret **différent** de celui de l'API Express
  (`DJANGO_SECRET_KEY` ≠ `JWT_ACCESS_SECRET` côté Express) : un token émis par
  l'un n'est jamais valide sur l'autre.
- Les refresh tokens sont mis en liste noire après rotation
  (`rest_framework_simplejwt.token_blacklist`).
- `IsSuperAdmin` restreint la création de nouveaux administrateurs au rôle
  `SUPER_ADMIN`.
