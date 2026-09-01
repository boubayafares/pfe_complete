from django.contrib.auth import password_validation
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from .models import Administrateur


class AdminTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Login serializer: authenticates by email, embeds role/name in the JWT claims."""

    username_field = "email"

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token["nom"] = user.nom
        token["prenom"] = user.prenom
        token["role"] = user.role
        return token

    def validate(self, attrs):
        data = super().validate(attrs)
        data["administrateur"] = AdministrateurSerializer(self.user).data
        return data


class AdministrateurSerializer(serializers.ModelSerializer):
    class Meta:
        model = Administrateur
        fields = ["id", "nom", "prenom", "email", "role", "is_active", "date_creation"]
        read_only_fields = ["id", "date_creation"]


class CreateAdministrateurSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)

    class Meta:
        model = Administrateur
        fields = ["id", "nom", "prenom", "email", "role", "password"]

    def validate_password(self, value):
        password_validation.validate_password(value)
        return value

    def create(self, validated_data):
        password = validated_data.pop("password")
        return Administrateur.objects.create_user(password=password, **validated_data)


class ChangePasswordSerializer(serializers.Serializer):
    ancien_mot_de_passe = serializers.CharField()
    nouveau_mot_de_passe = serializers.CharField(min_length=8)

    def validate_nouveau_mot_de_passe(self, value):
        password_validation.validate_password(value)
        return value
