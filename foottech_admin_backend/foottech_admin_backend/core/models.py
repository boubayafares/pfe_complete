"""
Read/manage mirror of the tables owned by the Express backend
(foottech_v2_schema.sql). `managed = False` on every model: Django will NOT
create, alter or drop these tables via migrations - they already exist and are
authored by the Express codebase.

Real-schema mapping of this admin module:

    utilisateur -> users            (role read through user_roles/roles)
    equipe      -> teams            (coach = users.id)
    joueur      -> players          (1:1, pk = users.id)
    adjoint     -> team_staff       (adjoint_id = users.id, team_id = teams.id)
    entrainement-> trainings
    match       -> matches
    notification-> notifications

This replaces a previous mapping that pointed at French-named tables
(`utilisateur`, `equipe`, ...) which never existed in the real schema. See
core/migrations/0002_align_to_express_schema for the additive legacy SQL views
and QA_REPORT.md for the full write-up.
"""
from collections.abc import Iterable

from django.db import models


class Utilisateur(models.Model):
    """Mirror of `users` (platform account: Coach / Adjoint / Joueur)."""

    class Role(models.TextChoices):
        COACH = "COACH", "Coach"
        ADJOINT = "ADJOINT", "Adjoint"
        JOUEUR = "JOUEUR", "Joueur"

    id_utilisateur = models.BigAutoField(db_column="id", primary_key=True)
    nom = models.CharField(max_length=100, db_column="last_name")
    prenom = models.CharField(max_length=100, db_column="first_name")
    email = models.EmailField(max_length=255, db_column="email", unique=True)
    telephone = models.CharField(max_length=30, db_column="phone", unique=True)
    date_creation = models.DateTimeField(db_column="created_at")
    account_status = models.CharField(
        max_length=30, db_column="account_status", null=True, blank=True
    )
    # `actif` is a projection (account_status == 'ACTIVE'); managed=False means
    # it is only ever read here, never written to the Express-owned `users` table.

    class Meta:
        managed = False
        db_table = "users"
        verbose_name = "Utilisateur"
        verbose_name_plural = "Utilisateurs"

    @property
    def role(self):
        role_joint = self.role_joints.select_related("role").first()
        return role_joint.role.name if role_joint else None

    @property
    def actif(self):
        return self.account_status == "ACTIVE"

    def __str__(self):
        return f"{self.prenom} {self.nom}"


class Role(models.Model):
    """Mirror of the `roles` lookup table (COACH / ADJOINT / JOUEUR)."""

    id = models.BigAutoField(primary_key=True)
    name = models.CharField(max_length=20, unique=True)

    class Meta:
        managed = False
        db_table = "roles"

    def __str__(self):
        return self.name


class RoleJointure(models.Model):
    """Join rows of `user_roles` (many-to-many user <-> role)."""

    pk = models.CompositePrimaryKey("user", "role")

    user = models.ForeignKey(
        Utilisateur, db_column="user_id", on_delete=models.DO_NOTHING, related_name="role_joints"
    )
    role = models.ForeignKey(
        Role, db_column="role_id", on_delete=models.DO_NOTHING, related_name="user_joints"
    )

    class Meta:
        managed = False
        db_table = "user_roles"
        verbose_name = "Affectation de rôle"

    def __str__(self):
        return f"user {self.user_id} → {self.role_id}"


class Equipe(models.Model):
    """Mirror of `teams`."""

    id_equipe = models.BigAutoField(db_column="id", primary_key=True)
    nom_equipe = models.CharField(max_length=150, db_column="name")
    categorie = models.CharField(max_length=80, db_column="category", null=True, blank=True)
    id_coach = models.ForeignKey(
        Utilisateur, db_column="coach_id", on_delete=models.DO_NOTHING, related_name="equipes_coachees"
    )

    class Meta:
        managed = False
        db_table = "teams"
        verbose_name = "Équipe"
        verbose_name_plural = "Équipes"

    def __str__(self):
        return self.nom_equipe


class Joueur(models.Model):
    """Mirror of `players` (1:1 with users.id)."""

    id_utilisateur = models.OneToOneField(
        Utilisateur,
        db_column="id",
        on_delete=models.DO_NOTHING,
        parent_link=False,
        primary_key=True,
        related_name="joueur",
    )
    id_equipe = models.ForeignKey(
        Equipe, db_column="team_id", null=True, on_delete=models.DO_NOTHING, related_name="joueurs"
    )
    poste = models.CharField(max_length=10, db_column="poste_principal", null=True, blank=True)

    class Meta:
        managed = False
        db_table = "players"
        verbose_name = "Joueur"
        verbose_name_plural = "Joueurs"

    def __str__(self):
        return f"{self.id_utilisateur}"


class Adjoint(models.Model):
    """Mirror of `team_staff` (one row per adjoint attribution to a team)."""

    id_adjoint = models.BigAutoField(db_column="id", primary_key=True)
    id_equipe = models.ForeignKey(
        Equipe, db_column="team_id", on_delete=models.DO_NOTHING, related_name="adjoints"
    )
    id_utilisateur = models.ForeignKey(
        Utilisateur, db_column="adjoint_id", on_delete=models.DO_NOTHING, related_name="affectations_adjoint"
    )

    class Meta:
        managed = False
        db_table = "team_staff"
        verbose_name = "Adjoint"
        verbose_name_plural = "Adjoints"

    def __str__(self):
        return f"Adjoint {self.id_utilisateur_id} → {self.id_equipe_id}"


class Entrainement(models.Model):
    """Mirror of `trainings`."""

    id_entrainement = models.BigAutoField(db_column="id", primary_key=True)
    id_equipe = models.ForeignKey(
        Equipe, db_column="team_id", on_delete=models.DO_NOTHING, related_name="entrainements"
    )
    date_seance = models.DateField(db_column="date")
    statut = models.CharField(max_length=30, db_column="status", default="SCHEDULED")

    class Meta:
        managed = False
        db_table = "trainings"
        verbose_name = "Entrainement"
        verbose_name_plural = "Entrainements"

    def __str__(self):
        return f"Équipe {self.id_equipe_id} — {self.date_seance}"


class Match(models.Model):
    """Mirror of `matches`."""

    id_match = models.BigAutoField(db_column="id", primary_key=True)
    id_equipe = models.ForeignKey(
        Equipe, db_column="team_id", on_delete=models.DO_NOTHING, related_name="matchs"
    )
    adversaire = models.CharField(max_length=150, db_column="adversaire")
    date_match = models.DateTimeField(db_column="date_heure")
    score_domicile = models.SmallIntegerField(db_column="home_score", null=True)
    score_exterieur = models.SmallIntegerField(db_column="away_score", null=True)
    statut = models.CharField(max_length=30, db_column="match_status", default="SCHEDULED")

    class Meta:
        managed = False
        db_table = "matches"
        verbose_name = "Match"
        verbose_name_plural = "Matchs"

    def __str__(self):
        return f"{self.adversaire} ({self.date_match})"


class Notification(models.Model):
    """Mirror of `notifications`."""

    id_notification = models.BigAutoField(db_column="id", primary_key=True)
    id_utilisateur = models.ForeignKey(
        Utilisateur, db_column="user_id", on_delete=models.DO_NOTHING, related_name="notifications"
    )
    type_notification = models.CharField(max_length=50, db_column="type", null=True, blank=True)
    message = models.TextField(db_column="message")
    date_envoi = models.DateTimeField(db_column="created_at")
    lu = models.BooleanField(db_column="is_read", default=False)

    class Meta:
        managed = False
        db_table = "notifications"
        verbose_name = "Notification"
        verbose_name_plural = "Notifications"

    def __str__(self):
        return f"Notification #{self.id_notification} → user {self.id_utilisateur_id}"
