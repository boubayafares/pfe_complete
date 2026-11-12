from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [("moderation", "0003_alter_suspension_administrateur")]

    operations = [
        migrations.AddField(
            model_name="suspension",
            name="previous_account_status",
            field=models.CharField(blank=True, max_length=30, null=True),
        ),
    ]
