from django.urls import path

from . import views

urlpatterns = [
    path("dashboard/", views.DashboardStatsView.as_view(), name="admin-dashboard"),

    path("teams/", views.EquipeListView.as_view(), name="admin-teams"),
    path("teams/<int:id_equipe>/", views.EquipeDetailView.as_view(), name="admin-team-detail"),
    path("teams/<int:id_equipe>/players/", views.EquipeJoueursView.as_view(), name="admin-team-players"),
    path(
        "teams/<int:id_equipe>/suspend/",
        views.EquipeSuspendView.as_view(),
        {"actif": False},
        name="admin-team-suspend",
    ),
    path(
        "teams/<int:id_equipe>/activate/",
        views.EquipeSuspendView.as_view(),
        {"actif": True},
        name="admin-team-activate",
    ),

    path("users/", views.UtilisateurListView.as_view(), name="admin-users"),
    path(
        "users/<int:id_utilisateur>/suspend/",
        views.UtilisateurSuspendView.as_view(),
        {"actif": False},
        name="admin-user-suspend",
    ),
    path(
        "users/<int:id_utilisateur>/activate/",
        views.UtilisateurSuspendView.as_view(),
        {"actif": True},
        name="admin-user-activate",
    ),

    path("matches/", views.MatchListView.as_view(), name="admin-matches"),
    path("trainings/", views.EntrainementListView.as_view(), name="admin-trainings"),

    path("broadcast/", views.BroadcastNotificationView.as_view(), name="admin-broadcast"),
    path("audit-logs/", views.AuditLogListView.as_view(), name="admin-audit-logs"),
]
