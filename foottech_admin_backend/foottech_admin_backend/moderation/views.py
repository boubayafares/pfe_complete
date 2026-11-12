from collections import Counter
from datetime import date

from django.db import connection, transaction
from django.db.models import Count, Exists, OuterRef
from django.utils import timezone
from django_filters import rest_framework as django_filters
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters, generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from core.models import Entrainement, Equipe, Joueur, Match, Utilisateur
from .models import AuditLog, Suspension
from .serializers import (
    AuditLogSerializer,
    BroadcastSerializer,
    EntrainementAdminSerializer,
    EquipeSerializer,
    JoueurAdminSerializer,
    MatchAdminSerializer,
    SuspendSerializer,
    UtilisateurSerializer,
)
from administrateurs.permissions import CanModerate


def _suspended_qs(model_field, entite_type):
    """Exists(...) annotable pour filtrer les entités actives/suspendues.

    La suspension est portée par la table locale `moderation_suspension`,
    jamais par une colonne ajoutée aux tables Express (users/teams).
    """
    return Exists(
        Suspension.objects.filter(entite_type=entite_type, entite_id=OuterRef(model_field))
    )


def _log_action(request, action, cible_type, cible_id, details=None):
    AuditLog.objects.create(
        administrateur=request.user,
        action=action,
        cible_type=cible_type,
        cible_id=cible_id,
        details=details or {},
    )


class UtilisateurFilter(django_filters.FilterSet):
    actif = django_filters.BooleanFilter(method="filter_actif")
    role = django_filters.CharFilter(field_name="role_joints__role__name", lookup_expr="iexact")

    class Meta:
        model = Utilisateur
        fields = ["role", "actif"]

    @staticmethod
    def filter_actif(queryset, name, value):
        susp = _suspended_qs("id_utilisateur", "utilisateur")
        return queryset.filter(~susp) if value else queryset.filter(susp)


class EquipeFilter(django_filters.FilterSet):
    actif = django_filters.BooleanFilter(method="filter_actif")

    class Meta:
        model = Equipe
        fields = ["actif", "categorie"]

    @staticmethod
    def filter_actif(queryset, name, value):
        susp = _suspended_qs("id_equipe", "equipe")
        return queryset.filter(~susp) if value else queryset.filter(susp)


class DashboardStatsView(APIView):
    """GET /api/admin/dashboard/ - platform-wide KPIs across every club."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        today = date.today()
        month_start = today.replace(day=1)

        eq_susp = _suspended_qs("id_equipe", "equipe")
        usr_susp = _suspended_qs("id_utilisateur", "utilisateur")

        role_totals = Counter(
            u.role for u in Utilisateur.objects.prefetch_related("role_joints__role")
        )
        par_role = [{"role": role, "total": count} for role, count in sorted(role_totals.items())]

        stats = {
            "equipes": {
                "total": Equipe.objects.count(),
                "actives": Equipe.objects.filter(~eq_susp).count(),
                "suspendues": Equipe.objects.filter(eq_susp).count(),
            },
            "utilisateurs": {
                "total": Utilisateur.objects.count(),
                "par_role": par_role,
                "actifs": Utilisateur.objects.filter(~usr_susp).count(),
                "suspendus": Utilisateur.objects.filter(usr_susp).count(),
            },
            "joueurs": {
                "total": Joueur.objects.count(),
                "comptes_actives": Joueur.objects.filter(id_utilisateur__account_status="ACTIVE").count(),
                "en_attente_activation": Joueur.objects.filter(id_utilisateur__account_status="INACTIVE").count(),
            },
            "activite": {
                "matchs_ce_mois": Match.objects.filter(date_match__gte=month_start).count(),
                "entrainements_a_venir": Entrainement.objects.filter(date_seance__gte=today).count(),
            },
        }
        return Response(stats)


class EquipeListView(generics.ListAPIView):
    """GET /api/admin/teams/?search=&actif=true - list every club on the platform."""

    serializer_class = EquipeSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_class = EquipeFilter
    search_fields = ["nom_equipe", "id_coach__nom", "id_coach__prenom", "id_coach__email"]
    queryset = Equipe.objects.select_related("id_coach").annotate(
        est_suspendue=_suspended_qs("id_equipe", "equipe")
    ).order_by("nom_equipe")


class EquipeDetailView(generics.RetrieveAPIView):
    serializer_class = EquipeSerializer
    permission_classes = [IsAuthenticated]
    queryset = Equipe.objects.select_related("id_coach").annotate(
        est_suspendue=_suspended_qs("id_equipe", "equipe")
    )
    lookup_url_kwarg = "id_equipe"
    lookup_field = "id_equipe"


class EquipeJoueursView(generics.ListAPIView):
    """GET /api/admin/teams/<id>/players/ - roster of a given club."""

    serializer_class = JoueurAdminSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Joueur.objects.select_related("id_utilisateur", "id_equipe").filter(
            id_equipe_id=self.kwargs["id_equipe"]
        )


class SuspendMixin:
    def _get_entite(self, entite):
        raise NotImplementedError

    def _apply(self, request, entite_id, actif, serializer):
        entite = self._get_entite(entite_id)
        cible_type, entite_type_name = self.ENTITE_TYPE
        with transaction.atomic():
            suspension = Suspension.objects.filter(
                entite_type=entite_type_name, entite_id=entite_id
            ).first()
            if actif:
                if entite_type_name == "utilisateur":
                    restore_status = (suspension.previous_account_status if suspension else None) or "INACTIVE"
                    Utilisateur.objects.filter(id_utilisateur=entite_id).update(account_status=restore_status)
                if suspension:
                    suspension.delete()
                action = self.ACTION_ACTIVER
            else:
                previous_status = entite.account_status if entite_type_name == "utilisateur" else None
                if suspension:
                    suspension.raison = serializer.validated_data.get("raison", "")
                    suspension.administrateur = request.user
                    suspension.save(update_fields=["raison", "administrateur"])
                else:
                    Suspension.objects.create(
                        entite_type=entite_type_name,
                        entite_id=entite_id,
                        raison=serializer.validated_data.get("raison", ""),
                        administrateur=request.user,
                        previous_account_status=previous_status,
                    )
                if entite_type_name == "utilisateur":
                    Utilisateur.objects.filter(id_utilisateur=entite_id).update(account_status="BLOCKED")
                action = self.ACTION_SUSPENDRE
            _log_action(
                request,
                action,
                cible_type,
                entite_id,
                {"raison": serializer.validated_data.get("raison", "")},
            )
        return entite


class EquipeSuspendView(SuspendMixin, APIView):
    """POST /api/admin/teams/<id>/suspend/ and /activate/"""

    ENTITE_TYPE = ("equipe", "equipe")
    ACTION_SUSPENDRE = AuditLog.Action.SUSPEND_TEAM
    ACTION_ACTIVER = AuditLog.Action.ACTIVATE_TEAM

    permission_classes = [CanModerate]

    def _get_entite(self, entite_id):
        return generics.get_object_or_404(Equipe, id_equipe=entite_id)

    def post(self, request, id_equipe, actif):
        serializer = SuspendSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        equipe = self._apply(request, id_equipe, actif, serializer)
        return Response(EquipeSerializer(equipe).data)


class UtilisateurListView(generics.ListAPIView):
    """GET /api/admin/users/?search=&role=&actif=true - every user across every club."""

    serializer_class = UtilisateurSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_class = UtilisateurFilter
    search_fields = ["nom", "prenom", "email", "telephone"]
    queryset = Utilisateur.objects.prefetch_related("role_joints__role").order_by("-date_creation")


class UtilisateurSuspendView(SuspendMixin, APIView):
    """POST /api/admin/users/<id>/suspend/ and /activate/"""

    ENTITE_TYPE = ("utilisateur", "utilisateur")
    ACTION_SUSPENDRE = AuditLog.Action.SUSPEND_USER
    ACTION_ACTIVER = AuditLog.Action.ACTIVATE_USER

    permission_classes = [CanModerate]

    def _get_entite(self, entite_id):
        return generics.get_object_or_404(Utilisateur, id_utilisateur=entite_id)

    def post(self, request, id_utilisateur, actif):
        serializer = SuspendSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = self._apply(request, id_utilisateur, actif, serializer)
        return Response(UtilisateurSerializer(user).data)


class MatchListView(generics.ListAPIView):
    """GET /api/admin/matches/ - read-only oversight of matches across every club."""

    serializer_class = MatchAdminSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ["statut", "id_equipe"]
    queryset = Match.objects.select_related("id_equipe").all().order_by("-date_match")


class EntrainementListView(generics.ListAPIView):
    """GET /api/admin/trainings/ - read-only oversight of training sessions."""

    serializer_class = EntrainementAdminSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ["statut", "id_equipe"]
    queryset = Entrainement.objects.select_related("id_equipe").all().order_by("-date_seance")


class BroadcastNotificationView(APIView):
    """
    POST /api/admin/broadcast/ - sends a platform notification to every active
    user (optionally filtered by role) by inserting directly into the shared
    `notifications` table (same one the Express backend reads from).
    """

    permission_classes = [CanModerate]

    def post(self, request):
        serializer = BroadcastSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        message = serializer.validated_data["message"]
        cible_role = serializer.validated_data["cible_role"]

        usr_susp = _suspended_qs("id_utilisateur", "utilisateur")
        qs = Utilisateur.objects.filter(account_status="ACTIVE").filter(~usr_susp)
        if cible_role != "TOUS":
            qs = qs.filter(role_joints__role__name=cible_role)
        user_ids = list(qs.values_list("id_utilisateur", flat=True))

        now = timezone.now()
        with connection.cursor() as cursor, transaction.atomic():
            cursor.executemany(
                """INSERT INTO platform.notifications (user_id, type, title, message, is_read, created_at)
                   VALUES (%s, 'OTHER', 'Annonce plateforme', %s, FALSE, %s)""",
                [(uid, message, now) for uid in user_ids],
            )

        _log_action(
            request,
            AuditLog.Action.BROADCAST_NOTIFICATION,
            "utilisateur",
            None,
            {"cible_role": cible_role, "nombre_destinataires": len(user_ids), "message": message},
        )
        return Response({"success": True, "destinataires": len(user_ids)}, status=status.HTTP_201_CREATED)


class AuditLogListView(generics.ListAPIView):
    """GET /api/admin/audit-logs/ - moderation history."""

    serializer_class = AuditLogSerializer
    permission_classes = [CanModerate]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ["action", "cible_type", "administrateur"]
    queryset = AuditLog.objects.select_related("administrateur").all()
