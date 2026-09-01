from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import Administrateur


@admin.register(Administrateur)
class AdministrateurAdmin(UserAdmin):
    model = Administrateur
    list_display = ("email", "nom_complet", "role", "is_active", "is_staff", "date_creation")
    list_filter = ("role", "is_active", "is_staff")
    search_fields = ("email", "nom", "prenom")
    ordering = ("-date_creation",)
    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Identité", {"fields": ("nom", "prenom", "role")}),
        ("Permissions", {"fields": ("is_active", "is_staff", "is_superuser", "groups", "user_permissions")}),
        ("Dates", {"fields": ("last_login",)}),
    )
    add_fieldsets = (
        (None, {
            "classes": ("wide",),
            "fields": ("email", "nom", "prenom", "role", "password1", "password2"),
        }),
    )
