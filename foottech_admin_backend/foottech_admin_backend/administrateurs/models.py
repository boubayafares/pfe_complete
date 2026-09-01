from django.contrib.auth.base_user import AbstractBaseUser, BaseUserManager
from django.contrib.auth.models import PermissionsMixin
from django.db import models


class AdministrateurManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError("L'email est obligatoire")
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        extra_fields.setdefault("role", Administrateur.Role.SUPER_ADMIN)
        return self.create_user(email, password, **extra_fields)


class Administrateur(AbstractBaseUser, PermissionsMixin):
    """
    Dedicated user model for platform administrators. Intentionally separate
    from the `utilisateur` table owned by the Express backend (Coach/Adjoint/
    Joueur) - an Administrateur manages the platform, not a single club.
    """

    class Role(models.TextChoices):
        SUPER_ADMIN = "SUPER_ADMIN", "Super administrateur"
        MODERATEUR = "MODERATEUR", "Modérateur"
        SUPPORT = "SUPPORT", "Support"

    nom = models.CharField(max_length=100)
    prenom = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    role = models.CharField(max_length=20, choices=Role.choices, default=Role.MODERATEUR)

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=True)  # allows access to django admin site
    date_creation = models.DateTimeField(auto_now_add=True)
    derniere_connexion_ip = models.GenericIPAddressField(null=True, blank=True)

    objects = AdministrateurManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["nom", "prenom"]

    class Meta:
        db_table = "administrateur"
        verbose_name = "Administrateur"
        verbose_name_plural = "Administrateurs"

    def __str__(self):
        return f"{self.prenom} {self.nom} ({self.email})"

    @property
    def nom_complet(self):
        return f"{self.prenom} {self.nom}"

    def has_full_access(self):
        return self.role == self.Role.SUPER_ADMIN or self.is_superuser
