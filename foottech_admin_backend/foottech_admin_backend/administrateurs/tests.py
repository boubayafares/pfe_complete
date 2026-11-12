from django.test import SimpleTestCase

from .models import Administrateur
from .permissions import CanModerate
from .serializers import AdministrateurSerializer


class AdministratorSecurityTests(SimpleTestCase):
    def test_profile_serializer_never_accepts_role_or_active_flag(self):
        serializer = AdministrateurSerializer()
        self.assertTrue(serializer.fields["role"].read_only)
        self.assertTrue(serializer.fields["is_active"].read_only)

    def test_support_cannot_moderate(self):
        permission = CanModerate()
        support = Administrateur(role=Administrateur.Role.SUPPORT)
        moderator = Administrateur(role=Administrateur.Role.MODERATEUR)
        request_type = type("Request", (), {})
        support_request = request_type()
        support_request.user = support
        moderator_request = request_type()
        moderator_request.user = moderator
        self.assertFalse(permission.has_permission(support_request, None))
        self.assertTrue(permission.has_permission(moderator_request, None))
