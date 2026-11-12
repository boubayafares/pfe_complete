from __future__ import annotations

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parent

COLORS = {
    "Coach": "#1565C0",
    "Adjoint": "#2E7D32",
    "Joueur": "#EF6C00",
    "Utilisateur": "#546E7A",
    "Admin": "#6A1B9A",
}


def story(number: int, actors: tuple[str, ...], action: str, endpoint: str, result: str):
    return {
        "id": f"US-{number:02d}",
        "actors": actors,
        "action": action,
        "endpoint": endpoint,
        "result": result,
    }


EPICS = [
    {
        "num": 1,
        "slug": "authentification",
        "title": "Authentification",
        "client": "Application Flutter",
        "api": "API Express",
        "service": "AuthService",
        "store": "PostgreSQL / Twilio",
        "class_file": "01_classes_authentification.puml",
        "state_file": "01_etats_actions_compte.puml",
        "stories": [
            story(1, ("Coach",), "S'inscrire avec email et mot de passe", "POST /auth/register-coach", "Compte coach créé"),
            story(2, ("Coach", "Adjoint"), "Se connecter avec email et mot de passe", "POST /auth/login", "Tokens JWT délivrés"),
            story(3, ("Utilisateur",), "Renouveler automatiquement la session", "POST /auth/refresh", "Nouveaux tokens délivrés"),
            story(4, ("Coach",), "Activer un joueur par code OTP", "POST /players puis /auth/player/request-otp", "OTP envoyé sans être journalisé"),
            story(5, ("Joueur",), "Se connecter par téléphone et OTP", "POST /auth/player/verify-otp", "Compte activé et session ouverte"),
            story(6, ("Utilisateur",), "Se déconnecter", "POST /auth/logout", "Refresh token révoqué"),
        ],
    },
    {
        "num": 2,
        "slug": "equipes",
        "title": "Gestion des équipes",
        "client": "Application Flutter",
        "api": "API Express",
        "service": "TeamService",
        "store": "PostgreSQL",
        "class_file": "02_classes_equipes_joueurs_saisons.puml",
        "state_file": "02_etats_actions_organisation.puml",
        "stories": [
            story(7, ("Coach",), "Créer une équipe", "POST /teams", "Équipe créée"),
            story(8, ("Coach",), "Lister ses équipes", "GET /teams", "Équipes autorisées affichées"),
            story(9, ("Coach",), "Ajouter un adjoint à l'équipe", "POST /teams/:id/staff", "Adjoint affecté"),
            story(10, ("Coach",), "Retirer un adjoint de l'équipe", "DELETE /teams/:id/staff/:adjointId", "Affectation supprimée"),
        ],
    },
    {
        "num": 3,
        "slug": "joueurs",
        "title": "Gestion des joueurs",
        "client": "Application Flutter",
        "api": "API Express",
        "service": "PlayerService",
        "store": "PostgreSQL",
        "class_file": "02_classes_equipes_joueurs_saisons.puml",
        "state_file": "02_etats_actions_organisation.puml",
        "stories": [
            story(11, ("Coach",), "Ajouter un joueur avec activation OTP", "POST /players", "Joueur rattaché à l'équipe"),
            story(12, ("Coach",), "Consulter la fiche complète d'un joueur", "GET /players/:id", "Fiche agrégée affichée"),
            story(13, ("Coach",), "Modifier les informations d'un joueur", "PATCH /players/:id", "Profil mis à jour"),
            story(14, ("Coach",), "Ajouter les informations scolaires", "PUT /players/:id/school-info", "Scolarité enregistrée"),
            story(15, ("Coach",), "Enregistrer une blessure", "POST /players/:id/injuries", "Blessure historisée"),
            story(16, ("Coach",), "Consulter le profil saisonnier", "GET /players/:id/season-profile", "Évolution affichée"),
        ],
    },
    {
        "num": 4,
        "slug": "saisons",
        "title": "Gestion des saisons",
        "client": "Application Flutter",
        "api": "API Express",
        "service": "SeasonService",
        "store": "PostgreSQL",
        "class_file": "02_classes_equipes_joueurs_saisons.puml",
        "state_file": "02_etats_actions_organisation.puml",
        "stories": [
            story(17, ("Coach",), "Créer une saison", "POST /seasons", "Saison rattachée à l'équipe"),
            story(18, ("Utilisateur",), "Lister les saisons disponibles", "GET /seasons", "Saisons de l'équipe affichées"),
            story(19, ("Coach",), "Modifier les dates d'une saison", "PATCH /seasons/:id", "Dates validées et enregistrées"),
        ],
    },
    {
        "num": 5,
        "slug": "entrainements",
        "title": "Gestion des entraînements",
        "client": "Application Flutter",
        "api": "API Express",
        "service": "TrainingService",
        "store": "PostgreSQL",
        "class_file": "03_classes_entrainements.puml",
        "state_file": "03_etats_actions_entrainement_proposition.puml",
        "stories": [
            story(20, ("Coach",), "Créer un entraînement", "POST /trainings", "Séance planifiée"),
            story(21, ("Coach",), "Remplir la fiche de séance", "PUT /trainings/:id/sheet", "Objectifs et effectif enregistrés"),
            story(22, ("Coach",), "Ajouter des situations d'exercices", "POST /trainings/:id/situations", "Situations ajoutées"),
            story(23, ("Coach",), "Dessiner un schéma tactique", "POST /trainings/:id/situations/:sid/drawing", "Dessin JSONB sauvegardé"),
            story(24, ("Adjoint",), "Proposer un exercice au coach", "POST /exercise-proposals", "Proposition en attente"),
            story(25, ("Coach",), "Valider ou rejeter une proposition", "PATCH /exercise-proposals/:id/review", "Décision historisée"),
            story(26, ("Utilisateur",), "Lister les entraînements de l'équipe", "GET /trainings", "Séances autorisées affichées"),
        ],
    },
    {
        "num": 6,
        "slug": "presences",
        "title": "Gestion des présences",
        "client": "Application Flutter",
        "api": "API Express",
        "service": "AttendanceService",
        "store": "Transaction PostgreSQL",
        "class_file": "04_classes_presences.puml",
        "state_file": "03_etats_actions_entrainement_proposition.puml",
        "stories": [
            story(27, ("Adjoint",), "Marquer la présence d'un joueur", "POST /attendance/trainings/:id", "Présence enregistrée"),
            story(28, ("Adjoint",), "Marquer les présences en lot", "POST /attendance/trainings/:id/bulk", "Lot validé atomiquement"),
            story(29, ("Utilisateur",), "Consulter les présences d'un entraînement", "GET /attendance/trainings/:id", "Feuille de présence affichée"),
            story(30, ("Utilisateur",), "Consulter l'historique d'un joueur", "GET /attendance/players/:id", "Historique filtré affiché"),
        ],
    },
    {
        "num": 7,
        "slug": "matchs",
        "title": "Gestion des matchs",
        "client": "Application Flutter",
        "api": "API Express",
        "service": "MatchService",
        "store": "PostgreSQL",
        "class_file": "05_classes_matchs_live.puml",
        "state_file": "04_etats_actions_match.puml",
        "stories": [
            story(31, ("Coach",), "Créer un match", "POST /matches", "Match planifié"),
            story(32, ("Coach",), "Définir titulaires et remplaçants", "PUT /matches/:id/lineup", "Composition enregistrée"),
            story(33, ("Coach",), "Modifier le statut du match", "PATCH /matches/:id/status", "Transition de statut validée"),
        ],
    },
    {
        "num": 8,
        "slug": "ia_composition",
        "title": "IA de composition",
        "client": "Application Flutter",
        "api": "API Express",
        "service": "Lineup Recommendation Service",
        "store": "PostgreSQL / FastAPI",
        "class_file": "06_classes_ia_composition.puml",
        "state_file": "04_etats_actions_match.puml",
        "stories": [
            story(34, ("Coach",), "Obtenir une recommandation IA", "POST /matches/:id/ai-recommendations", "Scores et rôles proposés"),
            story(35, ("Coach",), "Consulter les scores IA du match", "GET /matches/:id/ai-recommendations", "Scores expliqués affichés"),
            story(36, ("Coach",), "Valider ou modifier la composition IA", "PUT /matches/:id/lineup", "Décision humaine conservée"),
            story(37, ("Coach",), "Recalculer la recommandation", "POST /matches/:id/ai-recommendations", "Nouvelle version persistée"),
        ],
    },
    {
        "num": 9,
        "slug": "match_live",
        "title": "Match en direct et après-match",
        "client": "Application Flutter",
        "api": "API Express / Socket.IO",
        "service": "LiveMatchService",
        "store": "PostgreSQL / PDFKit",
        "class_file": "05_classes_matchs_live.puml",
        "state_file": "04_etats_actions_match.puml",
        "stories": [
            story(38, ("Adjoint",), "Enregistrer les événements en direct", "POST /matches/:id/events", "Événement diffusé en temps réel"),
            story(39, ("Utilisateur",), "Consulter la timeline en temps réel", "Socket.IO room match/:id", "Timeline synchronisée"),
            story(40, ("Coach",), "Saisir les statistiques du match", "PUT /matches/:id/stats", "Statistiques enregistrées"),
            story(41, ("Coach",), "Évaluer les joueurs après le match", "PUT /matches/:id/evaluations", "Notes et commentaires enregistrés"),
            story(42, ("Coach",), "Générer le rapport de match", "POST /matches/:id/report/generate", "Rapport PDF archivé"),
        ],
    },
    {
        "num": 10,
        "slug": "statistiques",
        "title": "Statistiques et performances",
        "client": "Application Flutter",
        "api": "API Express",
        "service": "StatisticsService",
        "store": "Vue PostgreSQL",
        "class_file": "07_classes_statistiques_dashboards.puml",
        "state_file": "05_etats_actions_analyse_notification.puml",
        "stories": [
            story(43, ("Utilisateur",), "Consulter ses statistiques personnelles", "GET /dashboard/me", "Indicateurs personnels affichés"),
            story(44, ("Coach",), "Consulter les statistiques de l'équipe", "GET /dashboard/season-bilan", "Agrégats d'équipe affichés"),
            story(45, ("Coach",), "Comparer les performances des joueurs", "GET /dashboard/season-bilan?players=...", "Comparaison affichée"),
            story(46, ("Coach",), "Consulter l'évolution saisonnière d'un joueur", "GET /players/:id/season-profile", "Courbe d'évolution affichée"),
        ],
    },
    {
        "num": 11,
        "slug": "bilan_saison",
        "title": "Bilan de saison",
        "client": "Application Flutter",
        "api": "API Express",
        "service": "SeasonReportService",
        "store": "PostgreSQL / PDFKit",
        "class_file": "07_classes_statistiques_dashboards.puml",
        "state_file": "05_etats_actions_analyse_notification.puml",
        "stories": [
            story(47, ("Coach",), "Consulter le bilan de saison", "GET /dashboard/season-bilan", "Bilan agrégé affiché"),
            story(48, ("Coach",), "Exporter le bilan en PDF", "Commande UI vers PDFKit", "PDF téléchargé"),
            story(49, ("Coach",), "Filtrer le bilan par joueur ou poste", "GET /dashboard/season-bilan?player&position", "Bilan filtré"),
        ],
    },
    {
        "num": 12,
        "slug": "notifications_calendrier",
        "title": "Notifications et calendrier",
        "client": "Application Flutter",
        "api": "API Express / Socket.IO",
        "service": "NotificationCalendarService",
        "store": "PostgreSQL / Firebase FCM",
        "class_file": "08_classes_notifications_calendrier.puml",
        "state_file": "05_etats_actions_analyse_notification.puml",
        "stories": [
            story(50, ("Utilisateur",), "Recevoir des notifications push", "FCM + GET /notifications/mine", "Notification livrée"),
            story(51, ("Coach",), "Diffuser une notification à l'équipe", "POST /notifications/broadcast", "Destinataires notifiés"),
            story(52, ("Utilisateur",), "Marquer une notification comme lue", "PATCH /notifications/:id/read", "Statut lu enregistré"),
            story(53, ("Utilisateur",), "Consulter le calendrier partagé", "GET /calendar-events", "Événements de l'équipe affichés"),
            story(54, ("Coach",), "Créer un événement de calendrier", "POST /calendar-events", "Événement créé"),
        ],
    },
    {
        "num": 13,
        "slug": "ai_insights",
        "title": "AI Insights",
        "client": "Application Flutter",
        "api": "AI Insights FastAPI",
        "service": "Use Cases IA",
        "store": "scikit-learn / Whisper / OCR",
        "class_file": "06_classes_ia_composition.puml",
        "state_file": "05_etats_actions_analyse_notification.puml",
        "stories": [
            story(55, ("Coach",), "Détecter la tendance d'un joueur", "POST /api/v1/trend/detect", "Tendance et R² calculés"),
            story(56, ("Coach",), "Regrouper les joueurs par profils", "POST /api/v1/clustering/players", "Clusters calculés"),
            story(57, ("Coach",), "Analyser le ton d'un commentaire", "POST /api/v1/tone/analyze", "Classe et suggestion retournées"),
            story(58, ("Coach",), "Transcrire une observation vocale", "POST /api/v1/transcription", "Texte et confiance retournés"),
            story(59, ("Coach",), "Extraire les champs d'un document", "POST /api/v1/documents/extract", "Champs OCR structurés"),
        ],
    },
    {
        "num": 14,
        "slug": "administration",
        "title": "Administration de la plateforme",
        "client": "Client JavaFX",
        "api": "API Django REST",
        "service": "AdminModerationService",
        "store": "PostgreSQL / AuditLog",
        "class_file": "09_classes_administration.puml",
        "state_file": "01_etats_actions_compte.puml",
        "stories": [
            story(60, ("Admin",), "Se connecter au back-office", "POST /api/admin/auth/login/", "Session administrateur ouverte"),
            story(61, ("Admin",), "Consulter les KPI", "GET /api/admin/dashboard/", "KPI affichés"),
            story(62, ("Admin",), "Lister et filtrer les équipes", "GET /api/admin/teams/", "Équipes paginées"),
            story(63, ("Admin",), "Suspendre une équipe", "POST /api/admin/teams/:id/suspend/", "Équipe suspendue et auditée"),
            story(64, ("Admin",), "Réactiver une équipe", "POST /api/admin/teams/:id/activate/", "Équipe réactivée et auditée"),
            story(65, ("Admin",), "Lister les utilisateurs", "GET /api/admin/users/", "Utilisateurs paginés"),
            story(66, ("Admin",), "Suspendre un utilisateur", "POST /api/admin/users/:id/suspend/", "Utilisateur suspendu"),
            story(67, ("Admin",), "Réactiver un utilisateur", "POST /api/admin/users/:id/activate/", "Utilisateur réactivé"),
            story(68, ("Admin",), "Diffuser une notification globale", "POST /api/admin/broadcast/", "Diffusion auditée"),
            story(69, ("Admin",), "Consulter les journaux d'audit", "GET /api/admin/audit-logs/", "Actions sensibles affichées"),
            story(70, ("Admin",), "Gérer les comptes administrateurs", "CRUD /api/admin/administrators/", "Compte et rôle administrateur gérés"),
        ],
    },
    {
        "num": 15,
        "slug": "dashboards",
        "title": "Tableaux de bord",
        "client": "Flutter / JavaFX",
        "api": "Express / Django REST",
        "service": "DashboardService",
        "store": "PostgreSQL",
        "class_file": "07_classes_statistiques_dashboards.puml",
        "state_file": "05_etats_actions_analyse_notification.puml",
        "stories": [
            story(71, ("Coach",), "Consulter le dashboard coach", "GET /dashboard/me", "Synthèse coach affichée"),
            story(72, ("Joueur",), "Consulter le dashboard joueur", "GET /dashboard/me", "Synthèse personnelle affichée"),
            story(73, ("Admin",), "Consulter le dashboard de supervision", "GET /api/admin/dashboard/", "Indicateurs plateforme affichés"),
            story(74, ("Admin",), "Voir les joueurs en attente d'activation", "GET /api/admin/dashboard/", "Compteur et liste affichés"),
        ],
    },
]


def safe(text: str) -> str:
    return text.replace('"', "'")


def header(title: str) -> list[str]:
    return [
        "@startuml",
        f"title {title}",
        "skinparam backgroundColor #FFFFFF",
        'skinparam defaultFontName "Segoe UI"',
        "skinparam shadowing false",
        "skinparam ArrowColor #455A64",
        "skinparam packageStyle rectangle",
        "skinparam roundcorner 10",
        "",
    ]


def write(relative: str, content: str) -> None:
    path = ROOT / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content.rstrip() + "\n", encoding="utf-8")


def generate_use_case(epic: dict) -> str:
    lines = header(f"FootTech — Cas d'utilisation — Épopée {epic['num']} : {epic['title']}")
    lines += [
        "left to right direction",
        "skinparam usecase {",
        "  BackgroundColor #E3F2FD",
        "  BorderColor #1565C0",
        "  FontColor #0D47A1",
        "}",
    ]
    used_actors = {actor for item in epic["stories"] for actor in item["actors"]}
    definitions = {
        "Utilisateur": 'actor "Utilisateur" as USER #546E7A',
        "Coach": 'actor "Coach" as COACH #1565C0',
        "Adjoint": 'actor "Adjoint" as ADJOINT #2E7D32',
        "Joueur": 'actor "Joueur" as JOUEUR #EF6C00',
        "Admin": 'actor "Administrateur" as ADMIN #6A1B9A',
    }
    for actor in ("Utilisateur", "Coach", "Adjoint", "Joueur", "Admin"):
        if actor in used_actors:
            lines.append(definitions[actor])
    if "Utilisateur" in used_actors:
        for role, alias in (("Coach", "COACH"), ("Adjoint", "ADJOINT"), ("Joueur", "JOUEUR")):
            if role in used_actors:
                lines.append(f"{alias} -|> USER")
    lines.append(f'rectangle "FootTech — {safe(epic["title"])}" {{')
    for item in epic["stories"]:
        alias = item["id"].replace("-", "")
        lines.append(f'  usecase "{item["id"]}\\n{safe(item["action"])}" as {alias}')
    lines.append("}")
    actor_alias = {"Utilisateur": "USER", "Coach": "COACH", "Adjoint": "ADJOINT", "Joueur": "JOUEUR", "Admin": "ADMIN"}
    for item in epic["stories"]:
        alias = item["id"].replace("-", "")
        for actor in item["actors"]:
            lines.append(f"{actor_alias[actor]} --> {alias}")
    lines += [
        "",
        "note bottom",
        "  Chaque cas d'utilisation reprend l'identifiant exact du Product Backlog.",
        "  Les contrôles JWT, rôle et équipe sont appliqués avant l'accès métier.",
        "end note",
        "@enduml",
    ]
    return "\n".join(lines)


def generate_sequence(epic: dict) -> str:
    actors = []
    for item in epic["stories"]:
        for actor in item["actors"]:
            if actor not in actors:
                actors.append(actor)
    lines = header(f"FootTech — Séquence — Épopée {epic['num']} : {epic['title']}")
    lines += [
        "hide footbox",
        "autonumber",
        f'actor "{" / ".join(actors)}" as ACT',
        f'boundary "{safe(epic["client"])}" as APP',
        f'control "{safe(epic["api"])}" as API',
        f'control "{safe(epic["service"])}" as SVC',
        f'database "{safe(epic["store"])}" as DB',
        "",
    ]
    for item in epic["stories"]:
        lines += [
            f'group {item["id"]} — {safe(item["action"])}',
            f'  ACT -> APP: {safe(item["action"])}',
            f'  APP -> API: {safe(item["endpoint"])}',
            "  API -> API: Vérifier JWT, rôle et équipe active",
            "  API -> SVC: Exécuter le cas d'utilisation",
            f'  SVC -> DB: Lire / valider / persister ({item["id"]})',
            "  DB --> SVC: Données ou confirmation",
            f'  SVC --> API: {safe(item["result"])}',
            "  API --> APP: Réponse DTO / statut HTTP",
            f'  APP --> ACT: {safe(item["result"])}',
            "end",
            "",
        ]
    lines += [
        "note over API,SVC",
        "  En cas d'échec : réponse normalisée 400/401/403/404/409/422/503",
        "  sans divulgation de secret ni de détail PostgreSQL.",
        "end note",
        "@enduml",
    ]
    return "\n".join(lines)


def generate_activity(epic: dict) -> str:
    lines = header(f"FootTech — Activité — Épopée {epic['num']} : {epic['title']}")
    lines += [
        "skinparam ActivityBackgroundColor #E8F5E9",
        "skinparam ActivityBorderColor #2E7D32",
        "skinparam ActivityDiamondBackgroundColor #FFF8E1",
        "skinparam ActivityDiamondBorderColor #F57F17",
        "start",
        ":Ouvrir le module;",
        ":Vérifier la session, le rôle et l'équipe active;",
        "if (Accès autorisé ?) then (oui)",
        "  :Choisir la User Story;",
        "  switch (Fonction sélectionnée)",
    ]
    for item in epic["stories"]:
        lines += [
            f'  case ({item["id"]})',
            f'    :{safe(item["action"])}\\n{safe(item["endpoint"])};',
            f'    :{safe(item["result"])};',
        ]
    lines += [
        "  endswitch",
        "  :Actualiser l'état Riverpod / interface;",
        "else (non)",
        "  :Afficher 401 ou 403;",
        "endif",
        "if (Erreur métier ou technique ?) then (oui)",
        "  :Normaliser l'erreur et proposer une reprise;",
        "else (non)",
        "  :Confirmer l'opération;",
        "endif",
        "stop",
        "@enduml",
    ]
    return "\n".join(lines)


CLASS_DIAGRAMS = {
    "01_classes_authentification.puml": r"""
class "Utilisateur\nusers" as User {
  +id: UUID
  +email: String
  +phone: String
  -passwordHash: String
  +accountStatus: AccountStatus
  +login()
  +logout()
}
class "Rôle\nroles" as Role { +name: COACH|ADJOINT|JOUEUR }
class "UserRole\nuser_roles" as UserRole
class "RefreshToken\nrefresh_tokens" as Refresh { -tokenHash: String\n+expiresAt: DateTime\n+revokedAt: DateTime }
class "CodeActivation\nactivation_codes" as OTP { -codeHash: String\n+expiresAt: DateTime\n+usedAt: DateTime }
class "PushToken\npush_tokens" as Push { -token: String\n+platform: String }
class AuthController { +registerCoach()\n+login()\n+refresh()\n+requestOtp()\n+verifyOtp()\n+logout() }
class AuthService { +authenticate()\n+rotateRefreshToken()\n+activatePlayer()\n+revokeSession() }
User "1" -- "0..*" UserRole
Role "1" -- "0..*" UserRole
User "1" o-- "0..*" Refresh
User "1" o-- "0..*" OTP
User "1" o-- "0..*" Push
AuthController --> AuthService
AuthService --> User
AuthService --> Refresh
AuthService --> OTP
note bottom of AuthService
US-01 à US-06, US-60, US-66, US-67 et US-74.
OTP et tokens FCM ne sont jamais écrits dans les logs.
end note
""",
    "02_classes_equipes_joueurs_saisons.puml": r"""
class "Équipe\nteams" as Team { +id: UUID\n+name: String\n+category: String\n+coachId: UUID\n+status: TeamStatus }
class "MembreStaff\nteam_staff" as Staff { +teamId: UUID\n+adjointId: UUID }
class "Joueur\nplayers" as Player { +id: UUID\n+teamId: UUID\n+mainPosition: Position }
class "Tuteur\nplayer_guardians" as Guardian
class "Adresse\nplayer_address" as Address
class "Scolarité\nplayer_school_info" as School
class "Blessure\nplayer_injuries" as Injury { +severity: String\n+status: String }
class "Saison\nseasons" as Season { +id: UUID\n+teamId: UUID\n+startDate: Date\n+endDate: Date\n+isCurrent: Boolean }
class "ProfilSaison\nplayer_season_profile" as SeasonProfile
class TeamService { +create()\n+listForUser()\n+addStaff()\n+removeStaff() }
class PlayerService { +create()\n+getFullProfile()\n+update()\n+addInjury() }
class SeasonService { +createForTeam()\n+listForTeam()\n+updateDates() }
Team "1" o-- "0..*" Staff
Team "1" o-- "0..*" Player
Team "1" o-- "0..*" Season
Player "1" o-- "0..*" Guardian
Player "1" o-- "0..1" Address
Player "1" o-- "0..1" School
Player "1" o-- "0..*" Injury
Player "1" o-- "0..*" SeasonProfile
Season "1" o-- "0..*" SeasonProfile
TeamService --> Team
PlayerService --> Player
SeasonService --> Season
note bottom
US-07 à US-19. Toutes les lectures sont limitées à l'équipe active.
end note
""",
    "03_classes_entrainements.puml": r"""
class "Entraînement\ntrainings" as Training { +id: UUID\n+teamId: UUID\n+dateTime: DateTime\n+status: TrainingStatus }
class "FicheSéance\ntraining_sheets" as Sheet { +objectives: Text\n+expectedPlayers: Integer }
class "Situation\ntraining_situations" as Situation { +title: String\n+duration: Integer\n+instructions: Text }
class "DessinTactique\ntactical_drawings" as Drawing { +payload: JSONB }
class "PropositionExercice\nexercise_proposals" as Proposal { +teamId: UUID\n+status: PENDING|APPROVED|REJECTED\n+reviewedBy: UUID }
class TrainingService { +create()\n+upsertSheet()\n+addSituation()\n+saveDrawing()\n+listForTeam() }
class ExerciseProposalService { +propose()\n+review()\n+listForTeam() }
Training "1" o-- "0..1" Sheet
Training "1" o-- "0..*" Situation
Situation "1" o-- "0..*" Drawing
Training "1" o-- "0..*" Proposal
TrainingService --> Training
ExerciseProposalService --> Proposal
note bottom
US-20 à US-26. Les propositions sont explicitement rattachées à l'équipe.
end note
""",
    "04_classes_presences.puml": r"""
class "Présence\nattendances" as Attendance { +trainingId: UUID\n+playerId: UUID\n+status: PRESENT|ABSENT|LATE\n+note: String }
class AttendanceItemDTO { +playerId: UUID\n+status: AttendanceStatus }
class BulkAttendanceDTO { +items: AttendanceItemDTO[] }
class AttendanceController { +markOne()\n+markBulk()\n+listByTraining()\n+historyByPlayer() }
class AttendanceService { +validateTeamScope()\n+saveOne()\n+saveBulkAtomic()\n+getHistory() }
class TransactionManager { +begin()\n+commit()\n+rollback() }
AttendanceController --> AttendanceService
AttendanceService --> Attendance
AttendanceService --> TransactionManager
BulkAttendanceDTO "1" o-- "1..*" AttendanceItemDTO
AttendanceService ..> BulkAttendanceDTO
note bottom of AttendanceService
US-27 à US-30. Le lot est atomique : toute erreur provoque un rollback complet.
end note
""",
    "05_classes_matchs_live.puml": r"""
class "Match\nmatches" as Match { +id: UUID\n+teamId: UUID\n+opponent: String\n+status: SCHEDULED|LIVE|FINISHED }
class "Composition\nmatch_lineups" as Lineup { +playerId: UUID\n+role: STARTER|SUBSTITUTE }
class "Événement\nmatch_events" as Event { +minute: Integer\n+type: GOAL|CARD|SUBSTITUTION|INJURY }
class "StatistiqueJoueur\nmatch_player_stats" as Stat { +minutes: Integer\n+goals: Integer\n+assists: Integer }
class "Évaluation\nmatch_evaluations" as Evaluation { +rating: Decimal\n+comment: Text }
class "RapportMatch\nmatch_reports" as Report { +filePath: String\n+generatedAt: DateTime }
class MatchService { +create()\n+setLineup()\n+changeStatus()\n+recordStats()\n+evaluate()\n+generateReport() }
class LiveGateway { +joinMatchRoom()\n+publishEvent()\n+publishScore() }
Match "1" o-- "0..*" Lineup
Match "1" o-- "0..*" Event
Match "1" o-- "0..*" Stat
Match "1" o-- "0..*" Evaluation
Match "1" o-- "0..1" Report
MatchService --> Match
LiveGateway --> Event
note bottom
US-31 à US-33 et US-38 à US-42. Socket.IO diffuse dans la room match:{id}.
end note
""",
    "06_classes_ia_composition.puml": r"""
class LineupController { +generateRecommendation()\n+getRecommendations()\n+confirmLineup() }
class LineupClient { +recommend(payload)\n+timeout: 5s }
class RecommendationUseCase { +execute(players, weights) }
class ScoringService { +presenceScore()\n+performanceScore()\n+fatigueScore()\n+finalScore() }
class "RecommandationIA\nai_lineup_recommendations" as Recommendation { +matchId: UUID\n+playerId: UUID\n+score: Decimal\n+suggestedRole: Role }
class TrendUseCase { +detect(points) }
class ClusteringUseCase { +cluster(players) }
class ToneUseCase { +analyze(comment) }
class TranscriptionUseCase { +transcribe(audio) }
class DocumentExtractionUseCase { +extract(image) }
LineupController --> LineupClient
LineupClient --> RecommendationUseCase
RecommendationUseCase --> ScoringService
RecommendationUseCase --> Recommendation
note bottom
US-34 à US-37 et US-55 à US-59.
Le coach conserve la décision finale ; les services IA sont remplaçables.
end note
""",
    "07_classes_statistiques_dashboards.puml": r"""
class "BilanJoueurSaison\nplayer_season_bilan" as SeasonView { +playerId: UUID\n+seasonId: UUID\n+matches: Integer\n+minutes: Integer\n+goals: Integer\n+assists: Integer\n+averageRating: Decimal }
class StatisticsService { +personalStats()\n+teamStats()\n+comparePlayers()\n+playerEvolution() }
class SeasonReportService { +buildBilan()\n+filter()\n+exportPdf() }
class DashboardService { +coachDashboard()\n+playerDashboard()\n+adminDashboard()\n+pendingActivations() }
class DashboardDTO { +kpis: Map\n+upcomingEvents: List\n+alerts: List }
StatisticsService --> SeasonView
SeasonReportService --> SeasonView
DashboardService --> StatisticsService
DashboardService --> DashboardDTO
note bottom
US-43 à US-49 et US-71 à US-74.
Les agrégats sont filtrés selon l'identité, le rôle et l'équipe.
end note
""",
    "08_classes_notifications_calendrier.puml": r"""
class "Notification\nnotifications" as Notification { +id: UUID\n+userId: UUID\n+type: NotificationType\n+message: Text\n+isRead: Boolean }
class "TokenPush\npush_tokens" as PushToken { +userId: UUID\n-token: String\n+platform: String }
class "ÉvénementCalendrier\ncalendar_events" as CalendarEvent { +teamId: UUID\n+title: String\n+startAt: DateTime\n+endAt: DateTime }
class NotificationService { +sendToUser()\n+broadcastToTeam()\n+markRead() }
class FirebaseGateway { +sendMulticast() }
class SocketGateway { +emitToUserRoom() }
class CalendarService { +listForTeam()\n+create()\n+update()\n+delete() }
Notification "0..*" --> "1" PushToken
NotificationService --> Notification
NotificationService --> FirebaseGateway
NotificationService --> SocketGateway
CalendarService --> CalendarEvent
note bottom
US-50 à US-54. Les tokens push sont secrets et ne sont jamais journalisés.
end note
""",
    "09_classes_administration.puml": r"""
class Administrator { +id: UUID\n+email: String\n+role: SUPER_ADMIN|MODERATOR|SUPPORT\n+isActive: Boolean }
class AdminAuthService { +login()\n+refresh()\n+checkPermission() }
class AdminDashboardService { +getKpis()\n+pendingPlayers() }
class ModerationService { +suspendTeam()\n+activateTeam()\n+suspendUser()\n+activateUser()\n+broadcast() }
class AuditLog { +actorId: UUID\n+action: String\n+targetType: String\n+targetId: UUID\n+timestamp: DateTime }
class JavaFxApiClient { +get()\n+post()\n+refreshToken() }
class TokenStore { +save()\n+load()\n+clear() }
JavaFxApiClient --> AdminAuthService
JavaFxApiClient --> ModerationService
JavaFxApiClient --> AdminDashboardService
JavaFxApiClient --> TokenStore
ModerationService --> AuditLog
Administrator "1" --> "0..*" AuditLog
note bottom
US-60 à US-70 et US-73 à US-74. Toute action de modération produit un audit.
end note
""",
}


STATE_DIAGRAMS = {
    "01_etats_actions_compte.puml": """
[*] --> PENDING : US-01 / création compte
PENDING --> OTP_SENT : US-04 / envoyer OTP
OTP_SENT --> ACTIVE : US-05 / OTP valide
OTP_SENT --> PENDING : OTP expiré
ACTIVE --> AUTHENTICATED : US-02, US-60 / login
AUTHENTICATED --> AUTHENTICATED : US-03 / rotation refresh token
AUTHENTICATED --> ACTIVE : US-06 / logout
ACTIVE --> SUSPENDED : US-66 / suspension admin
SUSPENDED --> ACTIVE : US-67 / réactivation admin
PENDING --> ACTIVE : US-74 / activation contrôlée
ACTIVE --> [*] : suppression conforme à la politique de rétention
""",
    "02_etats_actions_organisation.puml": """
state Equipe {
  [*] --> CREATED : US-07
  CREATED --> STAFFED : US-09 / ajouter adjoint
  STAFFED --> CREATED : US-10 / retirer adjoint
  CREATED --> ACTIVE : première saison
}
state Joueur {
  [*] --> PENDING_ACTIVATION : US-11
  PENDING_ACTIVATION --> ACTIVE : OTP validé
  ACTIVE --> UPDATED : US-13, US-14, US-15
  UPDATED --> ACTIVE
}
state Saison {
  [*] --> PLANNED : US-17
  PLANNED --> CURRENT : isCurrent=true
  CURRENT --> UPDATED : US-19
  UPDATED --> CURRENT
  CURRENT --> CLOSED : date de fin atteinte
}
""",
    "03_etats_actions_entrainement_proposition.puml": """
state Entrainement {
  [*] --> SCHEDULED : US-20 / créer
  SCHEDULED --> PREPARED : US-21, US-22, US-23
  PREPARED --> IN_PROGRESS : début séance
  IN_PROGRESS --> COMPLETED : clôturer
}
state PropositionExercice {
  [*] --> PENDING : US-24 / proposer
  PENDING --> APPROVED : US-25 / valider
  PENDING --> REJECTED : US-25 / rejeter
}
state FeuillePresence {
  [*] --> DRAFT : US-27
  DRAFT --> VALIDATED : US-28 / transaction commit
  DRAFT --> ROLLED_BACK : erreur / transaction rollback
  VALIDATED --> CONSULTED : US-29, US-30
}
""",
    "04_etats_actions_match.puml": """
[*] --> SCHEDULED : US-31 / créer match
SCHEDULED --> LINEUP_DRAFT : US-32 / composition manuelle
SCHEDULED --> AI_RECOMMENDED : US-34 / calcul IA
AI_RECOMMENDED --> AI_RECOMMENDED : US-37 / recalculer
AI_RECOMMENDED --> LINEUP_CONFIRMED : US-35, US-36 / contrôler et valider
LINEUP_DRAFT --> LINEUP_CONFIRMED : US-32 / confirmer
LINEUP_CONFIRMED --> LIVE : US-33 / démarrer
LIVE --> LIVE : US-38, US-39 / événement et diffusion
LIVE --> FINISHED : US-33 / terminer
FINISHED --> STATS_COMPLETED : US-40
STATS_COMPLETED --> EVALUATED : US-41
EVALUATED --> REPORTED : US-42 / PDF
REPORTED --> [*]
""",
    "05_etats_actions_analyse_notification.puml": """
state Analyse {
  [*] --> REQUESTED : US-43 à US-49, US-55 à US-59
  REQUESTED --> VALIDATED : données suffisantes
  REQUESTED --> REJECTED : données invalides / insuffisantes
  VALIDATED --> COMPUTED : calcul statistique ou IA
  COMPUTED --> DISPLAYED : dashboard / résultat
  DISPLAYED --> EXPORTED : US-48
}
state Notification {
  [*] --> CREATED : US-51
  CREATED --> PERSISTED : transaction DB
  PERSISTED --> DELIVERED : US-50 / FCM ou Socket.IO
  DELIVERED --> READ : US-52
}
state Dashboard {
  [*] --> LOADING : US-71 à US-74
  LOADING --> READY : agrégats autorisés
  LOADING --> ERROR : service indisponible
  ERROR --> LOADING : réessayer
}
""",
}


def wrap_class(filename: str, body: str) -> str:
    lines = header(f"FootTech — Diagramme de classes — {filename.removesuffix('.puml').replace('_', ' ')}")
    normalized_body = []
    for source_line in body.strip().splitlines():
        if source_line.lstrip().startswith("class ") and "{" in source_line and "}" in source_line:
            prefix, remainder = source_line.split("{", 1)
            inner, suffix = remainder.rsplit("}", 1)
            normalized_body.append(prefix.rstrip() + " {")
            for member in inner.strip().replace("|", " / ").split(r"\n"):
                normalized_body.append("  " + member.strip())
            normalized_body.append("}" + suffix)
        else:
            normalized_body.append(source_line)
    lines += [
        "skinparam class {",
        "  BackgroundColor #FFFFFF",
        "  BorderColor #1565C0",
        "  FontColor #263238",
        "  ArrowColor #455A64",
        "}",
        "\n".join(normalized_body),
        "@enduml",
    ]
    return "\n".join(lines)


def wrap_state(filename: str, body: str) -> str:
    lines = header(f"FootTech — Diagramme d'états / actions — {filename.removesuffix('.puml').replace('_', ' ')}")
    lines += [
        "skinparam state {",
        "  BackgroundColor #FFF8E1",
        "  BorderColor #F57F17",
        "  FontColor #4E342E",
        "}",
        body.strip(),
        "@enduml",
    ]
    return "\n".join(lines)


def global_use_case() -> str:
    lines = header("FootTech — Cas d'utilisation global — 74 User Stories")
    lines += [
        "left to right direction",
        'actor "Coach" as COACH #1565C0',
        'actor "Adjoint" as ADJOINT #2E7D32',
        'actor "Joueur" as JOUEUR #EF6C00',
        'actor "Administrateur" as ADMIN #6A1B9A',
        'rectangle "Plateforme FootTech" {',
    ]
    for epic in EPICS:
        first, last = epic["stories"][0]["id"], epic["stories"][-1]["id"]
        lines.append(f'  usecase "Épopée {epic["num"]} — {safe(epic["title"])}\\n{first} à {last}" as E{epic["num"]}')
    lines += ["}"]
    actor_epics = {
        "COACH": [1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12, 13, 15],
        "ADJOINT": [1, 5, 6, 9, 12],
        "JOUEUR": [1, 4, 5, 6, 9, 10, 12, 15],
        "ADMIN": [14, 15],
    }
    for actor, nums in actor_epics.items():
        for num in nums:
            lines.append(f"{actor} --> E{num}")
    lines += ["@enduml"]
    return "\n".join(lines)


def global_class() -> str:
    body = """
class FlutterApplication
class ExpressAPI
class DjangoAdminAPI
class JavaFxAdminClient
class PostgreSQL
class Redis
class LineupRecommendationService
class AIInsightsService
class FirebaseFCM
class TwilioSMS
FlutterApplication --> ExpressAPI : REST + JWT
FlutterApplication --> ExpressAPI : Socket.IO
FlutterApplication --> AIInsightsService : analyses
ExpressAPI --> PostgreSQL : transactions
ExpressAPI --> Redis : cache
ExpressAPI --> LineupRecommendationService : recommandation
ExpressAPI --> FirebaseFCM : push
ExpressAPI --> TwilioSMS : OTP
JavaFxAdminClient --> DjangoAdminAPI : REST + JWT
DjangoAdminAPI --> PostgreSQL : miroir + modération
note bottom
Vue globale des composants responsables des US-01 à US-74.
Les diagrammes de classes détaillés se trouvent dans le même dossier.
end note
"""
    return wrap_class("00_classes_globales.puml", body)


def global_sequence() -> str:
    lines = header("FootTech — Séquence globale — Parcours de saison")
    lines += [
        "hide footbox",
        "autonumber",
        'actor "Coach" as C',
        'actor "Adjoint" as A',
        'actor "Joueur" as J',
        'boundary "Flutter" as F',
        'control "API Express" as API',
        'control "Lineup FastAPI" as L',
        'control "AI Insights" as AI',
        'database "PostgreSQL" as DB',
        "C -> F: US-01/02 S'inscrire et se connecter",
        "F -> API: JWT",
        "C -> F: US-07..19 Équipe, joueurs et saison",
        "F -> API: CRUD métier limité à l'équipe",
        "API -> DB: persister organisation",
        "C -> F: US-20..26 Préparer une séance",
        "A -> F: US-27/28 Saisir les présences",
        "F -> API: lot de présences",
        "API -> DB: transaction atomique",
        "C -> F: US-31..37 Préparer le match et demander l'IA",
        "F -> API: générer recommandation",
        "API -> L: features présence/performance/fatigue",
        "L --> API: scores et rôles",
        "C -> F: valider la composition",
        "A -> F: US-38 événements live",
        "F -> API: Socket.IO / événements",
        "API --> J: US-39 timeline temps réel",
        "C -> F: US-40..49 statistiques, rapport et bilan",
        "C -> AI: US-55..59 analyses IA",
        "AI --> C: tendances, clusters, ton, transcription, OCR",
        "@enduml",
    ]
    return "\n".join(lines)


def global_activity() -> str:
    lines = header("FootTech — Activité globale — Cycle sportif et administratif")
    lines += [
        "start",
        ":Authentification et sélection de l'équipe (US-01..06);",
        ":Configurer équipe, joueurs et saison (US-07..19);",
        "fork",
        "  :Préparer entraînements et exercices (US-20..26);",
        "  :Saisir les présences (US-27..30);",
        "fork again",
        "  :Planifier le match et la composition (US-31..37);",
        "  :Suivre le match puis évaluer (US-38..42);",
        "fork again",
        "  :Notifier et tenir le calendrier (US-50..54);",
        "end fork",
        ":Calculer statistiques et bilan (US-43..49);",
        ":Produire les analyses IA (US-55..59);",
        "fork",
        "  :Consulter les dashboards métier (US-71..72);",
        "fork again",
        "  :Superviser et modérer (US-60..70, US-73..74);",
        "end fork",
        ":Archiver les résultats de la saison;",
        "stop",
        "@enduml",
    ]
    return "\n".join(lines)


def global_state() -> str:
    body = """
[*] --> IDENTIFICATION : US-01..06
IDENTIFICATION --> ORGANISATION : équipe active
ORGANISATION --> PREPARATION : US-07..30
PREPARATION --> MATCH_READY : US-31..37
MATCH_READY --> MATCH_LIVE : US-33
MATCH_LIVE --> POST_MATCH : US-38..42
POST_MATCH --> ANALYSIS : US-43..59
ANALYSIS --> DASHBOARDS : US-71..74
DASHBOARDS --> ORGANISATION : nouvelle séance ou nouveau match
ORGANISATION --> SUSPENDED : US-63 ou US-66
SUSPENDED --> ORGANISATION : US-64 ou US-67
DASHBOARDS --> [*] : clôture de saison
"""
    return wrap_state("00_etats_actions_globaux.puml", body)


def main() -> None:
    all_stories = [item for epic in EPICS for item in epic["stories"]]
    numbers = [int(item["id"].split("-")[1]) for item in all_stories]
    assert numbers == list(range(1, 75)), "Les User Stories doivent couvrir exactement US-01 à US-74."

    write("use_cases/00_use_case_global.puml", global_use_case())
    write("classes/00_classes_globales.puml", global_class())
    write("sequences/00_sequence_globale.puml", global_sequence())
    write("activities/00_activite_globale.puml", global_activity())
    write("states_actions/00_etats_actions_globaux.puml", global_state())

    rows = []
    for epic in EPICS:
        prefix = f"{epic['num']:02d}_{epic['slug']}"
        use_case_file = f"use_cases/{prefix}_use_case.puml"
        sequence_file = f"sequences/{prefix}_sequence.puml"
        activity_file = f"activities/{prefix}_activite.puml"
        class_file = f"classes/{epic['class_file']}"
        state_file = f"states_actions/{epic['state_file']}"
        write(use_case_file, generate_use_case(epic))
        write(sequence_file, generate_sequence(epic))
        write(activity_file, generate_activity(epic))
        for item in epic["stories"]:
            rows.append({
                "user_story": item["id"],
                "epic": f"{epic['num']} — {epic['title']}",
                "actors": " / ".join(item["actors"]),
                "use_case": use_case_file,
                "sequence": sequence_file,
                "activity": activity_file,
                "class": class_file,
                "state_action": state_file,
            })

    for filename, body in CLASS_DIAGRAMS.items():
        write(f"classes/{filename}", wrap_class(filename, body))
    for filename, body in STATE_DIAGRAMS.items():
        write(f"states_actions/{filename}", wrap_state(filename, body))

    csv_path = ROOT / "traceability.csv"
    with csv_path.open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)

    counts = {
        "Cas d'utilisation": 1 + len(EPICS),
        "Séquences": 1 + len(EPICS),
        "Activités": 1 + len(EPICS),
        "Classes": 1 + len(CLASS_DIAGRAMS),
        "États / actions": 1 + len(STATE_DIAGRAMS),
    }
    readme = [
        "# Diagrammes UML FootTech — couverture des 74 User Stories",
        "",
        "Ce dossier contient les sources PlantUML UTF-8. Les diagrammes sont organisés par type et chaque User Story est reliée à cinq vues UML dans `traceability.csv`.",
        "",
        "## Inventaire",
        "",
    ]
    for label, count in counts.items():
        readme.append(f"- {label} : {count} diagrammes")
    readme += [
        f"- Total : {sum(counts.values())} fichiers PlantUML",
        "- Couverture : US-01 à US-74, sans doublon ni omission",
        "",
        "## Arborescence",
        "",
        "- `use_cases/` : diagramme global et un diagramme par épopée.",
        "- `classes/` : vue globale et classes détaillées par domaine.",
        "- `sequences/` : séquence globale et une séquence par épopée, avec un groupe par User Story.",
        "- `activities/` : activité globale et une activité par épopée.",
        "- `states_actions/` : cycles de vie, transitions et actions métier.",
        "- `traceability.csv` : correspondance exacte User Story → cinq diagrammes.",
        "",
        "## Régénération",
        "",
        "1. Exécuter `python generate_all_uml.py` pour reconstruire les sources.",
        "2. Exécuter PlantUML sur le dossier pour produire les PNG : `plantuml -charset UTF-8 -tpng '**/*.puml'`.",
        "",
        "Les diagrammes décrivent le comportement du projet FootTech et non un modèle générique. Ils incluent notamment le contrôle JWT/RBAC, l'isolation par équipe, la transaction atomique des présences, Express/FastAPI/Django, Flutter, JavaFX, Socket.IO, FCM et Twilio.",
    ]
    write("README.md", "\n".join(readme))

    print(f"Generated {sum(counts.values())} PlantUML files covering {len(rows)} User Stories.")


if __name__ == "__main__":
    main()
