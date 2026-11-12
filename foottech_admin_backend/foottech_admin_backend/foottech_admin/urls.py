from django.contrib import admin
from django.db import connection
from django.http import JsonResponse
from django.urls import include, path


def health(request):
    """Container readiness probe: Django is running and PostgreSQL is reachable."""
    with connection.cursor() as cursor:
        cursor.execute("SELECT 1")
        cursor.fetchone()
    return JsonResponse({"status": "ok", "database": "connected"})


urlpatterns = [
    path("health/", health, name="health"),
    path("admin-site/", admin.site.urls),  # Django's built-in admin site (internal ops)
    path("api/admin/auth/", include("administrateurs.urls")),
    path("api/admin/", include("moderation.urls")),
]
