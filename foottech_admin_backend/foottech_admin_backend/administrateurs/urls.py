from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from . import views

urlpatterns = [
    path("login/", views.AdminLoginView.as_view(), name="admin-login"),
    path("refresh/", TokenRefreshView.as_view(), name="admin-token-refresh"),
    path("me/", views.MeView.as_view(), name="admin-me"),
    path("change-password/", views.ChangePasswordView.as_view(), name="admin-change-password"),
]
