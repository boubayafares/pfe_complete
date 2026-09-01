from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("admin-site/", admin.site.urls),  # Django's built-in admin site (internal ops)
    path("api/admin/auth/", include("administrateurs.urls")),
    path("api/admin/", include("moderation.urls")),
]
