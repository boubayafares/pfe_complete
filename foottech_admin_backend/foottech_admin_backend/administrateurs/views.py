from django.contrib.auth import update_session_auth_hash
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import Administrateur
from .permissions import IsSuperAdmin
from .serializers import (
    AdminTokenObtainPairSerializer,
    AdministrateurSerializer,
    ChangePasswordSerializer,
    CreateAdministrateurSerializer,
)


class AdminLoginView(TokenObtainPairView):
    """POST /api/admin/auth/login/ - obtains an access/refresh token pair."""

    serializer_class = AdminTokenObtainPairSerializer

    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        # Track last login IP for basic security auditing.
        if response.status_code == 200:
            ip = request.META.get("HTTP_X_FORWARDED_FOR", request.META.get("REMOTE_ADDR"))
            email = request.data.get("email")
            Administrateur.objects.filter(email=email).update(derniere_connexion_ip=ip)
        return response


class MeView(generics.RetrieveUpdateAPIView):
    """GET/PATCH /api/admin/auth/me/ - current administrator's profile."""

    serializer_class = AdministrateurSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user


class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = request.user
        if not user.check_password(serializer.validated_data["ancien_mot_de_passe"]):
            return Response({"error": "Ancien mot de passe incorrect"}, status=status.HTTP_400_BAD_REQUEST)
        user.set_password(serializer.validated_data["nouveau_mot_de_passe"])
        user.save()
        update_session_auth_hash(request, user)
        return Response({"success": True})


class AdministrateurListCreateView(generics.ListCreateAPIView):
    """
    GET  /api/admin/administrateurs/  - list platform admins
    POST /api/admin/administrateurs/  - create a new admin (super-admin only)
    """

    queryset = Administrateur.objects.all().order_by("nom")

    def get_serializer_class(self):
        return CreateAdministrateurSerializer if self.request.method == "POST" else AdministrateurSerializer

    def get_permissions(self):
        if self.request.method == "POST":
            return [IsSuperAdmin()]
        return [IsAuthenticated()]
