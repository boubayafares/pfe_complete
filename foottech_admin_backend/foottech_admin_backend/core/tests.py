from django.test import SimpleTestCase

from .models import Adjoint, RoleJointure


class ExpressSchemaMappingTests(SimpleTestCase):
    def test_user_roles_uses_the_real_composite_primary_key(self):
        self.assertEqual(RoleJointure._meta.pk.field_names, ("user", "role"))

    def test_team_staff_primary_key_maps_to_id_column(self):
        self.assertEqual(Adjoint._meta.pk.column, "id")
