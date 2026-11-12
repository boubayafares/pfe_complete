from rest_framework.permissions import BasePermission


class IsSuperAdmin(BasePermission):
    """Restricts an endpoint to SUPER_ADMIN administrators (e.g. creating other admins)."""

    message = "Réservé aux super-administrateurs."

    def has_permission(self, request, view):
        user = request.user
        return bool(user and user.is_authenticated and user.has_full_access())


class CanModerate(BasePermission):
    """Read-only support agents cannot suspend accounts or broadcast messages."""

    message = "Réservé aux modérateurs et super-administrateurs."

    def has_permission(self, request, view):
        user = request.user
        return bool(
            user
            and user.is_authenticated
            and user.role in {user.Role.SUPER_ADMIN, user.Role.MODERATEUR}
        )
