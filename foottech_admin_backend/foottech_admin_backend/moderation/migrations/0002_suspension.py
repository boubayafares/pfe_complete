"""Suspension table: moderation-held state (never touches Express-owned tables)."""
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    dependencies = [
        ("moderation", "0001_initial"),
    ]

    operations = [
        migrations.CreateModel(
            name="Suspension",
            fields=[
                (
                    "id",
                    models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID"),
                ),
                (
                    "entite_type",
                    models.CharField(
                        choices=[("equipe", "Équipe"), ("utilisateur", "Utilisateur")], max_length=20
                    ),
                ),
                ("entite_id", models.BigIntegerField()),
                ("raison", models.TextField(blank=True, default="")),
                ("administrateur", models.ForeignKey(
                    on_delete=django.db.models.deletion.SET_NULL,
                    related_name="suspensions",
                    to="administrateurs.administrateur",
                    blank=True,
                    null=True,
                )),
                ("cree_le", models.DateTimeField(auto_now_add=True)),
            ],
            options={
                "verbose_name": "Suspension",
                "verbose_name_plural": "Suspensions",
                "db_table": "moderation_suspension",
                "ordering": ["-cree_le"],
            },
        ),
        migrations.AddConstraint(
            model_name="suspension",
            constraint=models.UniqueConstraint(
                fields=("entite_type", "entite_id"), name="uniq_suspension_entite"
            ),
        ),
    ]