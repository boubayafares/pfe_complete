from django.conf import settings
from django.db import models


class Suspension(models.Model):
    """
    Bannissement géré par le backend d'administration.

    Les tables `users`/`teams` appartiennent à l'API Express (source de vérité)
    et ne sont pas modifiées structurellement par ce module. Le statut
    "activé/suspendu" affiché par l'admin est donc une lecture de cette table
    locale, pas une colonne ajoutée aux tables Express.
    """

    class EntiteType(models.TextChoices):
        EQUIPE = "equipe", "Équipe"
        UTILISATEUR = "utilisateur", "Utilisateur"

    administrateur = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="suspensions"
    )
    entite_type = models.CharField(max_length=20, choices=EntiteType.choices)
    entite_id = models.BigIntegerField()
    raison = models.TextField(blank=True, default="")
    cree_le = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "moderation_suspension"
        constraints = [
            models.UniqueConstraint(fields=["entite_type", "entite_id"], name="uniq_suspension_entite")
        ]
        ordering = ["-cree_le"]
        verbose_name = "Suspension"
        verbose_name_plural = "Suspensions"

    def __str__(self):
        return f"{self.entite_type} #{self.entite_id} ({self.cree_le:%Y-%m-%d})"


class AuditLog(models.Model):
    """Every moderation action taken by an administrator (suspend, reactivate, broadcast...)."""

    class Action(models.TextChoices):
        SUSPEND_TEAM = "SUSPEND_TEAM", "Suspension d'équipe"
        ACTIVATE_TEAM = "ACTIVATE_TEAM", "Réactivation d'équipe"
        SUSPEND_USER = "SUSPEND_USER", "Suspension d'utilisateur"
        ACTIVATE_USER = "ACTIVATE_USER", "Réactivation d'utilisateur"
        BROADCAST_NOTIFICATION = "BROADCAST_NOTIFICATION", "Notification diffusée"
        CREATE_ADMIN = "CREATE_ADMIN", "Création d'administrateur"

    administrateur = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="actions"
    )
    action = models.CharField(max_length=40, choices=Action.choices)
    cible_type = models.CharField(max_length=30)  # "equipe" | "utilisateur" | ...
    cible_id = models.IntegerField(null=True, blank=True)
    details = models.JSONField(null=True, blank=True)
    date_action = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "admin_audit_log"
        ordering = ["-date_action"]
        verbose_name = "Action d'audit"
        verbose_name_plural = "Journal d'audit"

    def __str__(self):
        return f"{self.action} #{self.cible_id} par {self.administrateur}"
