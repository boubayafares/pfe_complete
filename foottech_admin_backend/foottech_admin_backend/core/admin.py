from django.contrib import admin

from .models import Adjoint, Entrainement, Equipe, Joueur, Match, Notification, Utilisateur


@admin.register(Utilisateur)
class UtilisateurAdmin(admin.ModelAdmin):
    list_display = ("id_utilisateur", "nom", "prenom", "email", "role", "actif", "date_creation")
    list_filter = ("account_status",)
    search_fields = ("nom", "prenom", "email", "telephone")

    def has_add_permission(self, request):
        return False  # accounts are created by the Express backend, not here


@admin.register(Equipe)
class EquipeAdmin(admin.ModelAdmin):
    list_display = ("id_equipe", "nom_equipe", "categorie", "id_coach")
    list_filter = ("categorie",)
    search_fields = ("nom_equipe",)

    def has_add_permission(self, request):
        return False


admin.site.register(Joueur)
admin.site.register(Adjoint)
admin.site.register(Entrainement)
admin.site.register(Match)
admin.site.register(Notification)