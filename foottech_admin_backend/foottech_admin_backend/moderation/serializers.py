from rest_framework import serializers

from core.models import Entrainement, Equipe, Joueur, Match, Utilisateur
from .models import AuditLog


class UtilisateurSerializer(serializers.ModelSerializer):
    role = serializers.CharField(read_only=True)   # property (user_roles/roles)
    actif = serializers.BooleanField(read_only=True)  # property (suspension locale)

    class Meta:
        model = Utilisateur
        fields = ["id_utilisateur", "nom", "prenom", "email", "telephone", "role", "date_creation", "actif"]


class EquipeSerializer(serializers.ModelSerializer):
    coach = UtilisateurSerializer(source="id_coach", read_only=True)
    actif = serializers.BooleanField(read_only=True)  # property (suspension locale)
    nombre_joueurs = serializers.SerializerMethodField()

    class Meta:
        model = Equipe
        fields = ["id_equipe", "nom_equipe", "categorie", "coach", "actif", "nombre_joueurs"]

    def get_nombre_joueurs(self, obj):
        return obj.joueurs.count()


class JoueurAdminSerializer(serializers.ModelSerializer):
    id_joueur = serializers.IntegerField(source="id_utilisateur.id", read_only=True)
    nom = serializers.CharField(source="id_utilisateur.nom", read_only=True)
    prenom = serializers.CharField(source="id_utilisateur.prenom", read_only=True)
    equipe = serializers.CharField(source="id_equipe.nom_equipe", read_only=True, default=None)
    statut_activation = serializers.SerializerMethodField()

    class Meta:
        model = Joueur
        fields = ["id_joueur", "nom", "prenom", "poste", "statut_activation", "equipe"]

    def get_statut_activation(self, obj):
        # L'activation du compte joueur est portée par users.account_status
        # (source de vérité de l'API Express) - jamais par une colonne dédiée.
        return obj.id_utilisateur.account_status == "ACTIVE"


class MatchAdminSerializer(serializers.ModelSerializer):
    equipe = serializers.CharField(source="id_equipe.nom_equipe", read_only=True)

    class Meta:
        model = Match
        fields = ["id_match", "equipe", "adversaire", "date_match", "score_domicile", "score_exterieur", "statut"]


class EntrainementAdminSerializer(serializers.ModelSerializer):
    equipe = serializers.CharField(source="id_equipe.nom_equipe", read_only=True)

    class Meta:
        model = Entrainement
        fields = ["id_entrainement", "equipe", "date_seance", "statut"]


class AuditLogSerializer(serializers.ModelSerializer):
    administrateur_nom = serializers.CharField(source="administrateur.nom_complet", read_only=True, default=None)

    class Meta:
        model = AuditLog
        fields = ["id", "administrateur_nom", "action", "cible_type", "cible_id", "details", "date_action"]


class SuspendSerializer(serializers.Serializer):
    raison = serializers.CharField(required=False, allow_blank=True)


class BroadcastSerializer(serializers.Serializer):
    message = serializers.CharField()
    cible_role = serializers.ChoiceField(choices=["TOUS", "COACH", "ADJOINT", "JOUEUR"], default="TOUS")