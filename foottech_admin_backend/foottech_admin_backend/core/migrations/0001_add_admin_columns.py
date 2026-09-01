"""
Alignment to the real Express schema (`foottech_v2_schema.sql`).

The historical `core` module mapped Django models onto French-named tables
(`utilisateur`, `equipe`, `joueur`, `adjoint`, `entrainement`, `match`,
`notification`) that never existed in the actual schema - the Express backend
owns English-named tables (`users`, `teams`, ...) with different columns and a
per-user role carried by `user_roles`/`roles`.

`core/models.py` is now rewritten to point at the real tables (managed=False).
This migration (additive, idempotent) additionally creates read-only VIEWS that
re-expose the old French names and columns for any legacy tooling/scripts that
still reference them. No table owned by the Express backend is altered: the
views are pure projections, safe to run against a shared database.

The previous `0001_add_admin_columns` migration (ALTER TABLE utilisateur ...)
always failed at migrate time because that table does not exist; it has been
replaced by this one and was never recorded as applied anywhere.
"""
from django.db import migrations

LEGACY_VIEWS_SQL = """
CREATE OR REPLACE VIEW utilisateur AS
    SELECT u.id                              AS id_utilisateur,
           u.last_name                       AS nom,
           u.first_name                      AS prenom,
           u.email                           AS email,
           u.phone                           AS telephone,
           (SELECT r.name
              FROM platform.user_roles ur
              JOIN platform.roles r ON r.id = ur.role_id
             WHERE ur.user_id = u.id
             LIMIT 1)                        AS role,
           u.account_status                  AS account_status,
           u.created_at                      AS date_creation,
           (u.account_status = 'ACTIVE')     AS actif
      FROM platform.users u;

CREATE OR REPLACE VIEW equipe AS
    SELECT id        AS id_equipe,
           name      AS nom_equipe,
           category  AS categorie,
           coach_id  AS id_coach,
           TRUE      AS actif
      FROM platform.teams;

CREATE OR REPLACE VIEW joueur AS
    SELECT id                AS id_joueur,
           id                AS id_utilisateur,
           team_id           AS id_equipe,
           poste_principal   AS poste,
           TRUE              AS statut_activation
      FROM platform.players;

CREATE OR REPLACE VIEW adjoint AS
    SELECT id          AS id_adjoint,
           adjoint_id  AS id_utilisateur,
           team_id     AS id_equipe
      FROM platform.team_staff;

CREATE OR REPLACE VIEW entrainement AS
    SELECT id       AS id_entrainement,
           team_id  AS id_equipe,
           date     AS date_seance,
           status   AS statut
      FROM platform.trainings;

CREATE OR REPLACE VIEW "match" AS
    SELECT id              AS id_match,
           team_id         AS id_equipe,
           adversaire      AS adversaire,
           date_heure      AS date_match,
           home_score      AS score_domicile,
           away_score      AS score_exterieur,
           match_status    AS statut
      FROM platform.matches;

CREATE OR REPLACE VIEW notification AS
    SELECT id                    AS id_notification,
           user_id               AS id_utilisateur,
           type                  AS type_notification,
           message               AS message,
           created_at            AS date_envoi,
           is_read               AS lu
      FROM platform.notifications;
"""

DROP_VIEWS_SQL = """
DROP VIEW IF EXISTS utilisateur CASCADE;
DROP VIEW IF EXISTS equipe CASCADE;
DROP VIEW IF EXISTS joueur CASCADE;
DROP VIEW IF EXISTS adjoint CASCADE;
DROP VIEW IF EXISTS entrainement CASCADE;
DROP VIEW IF EXISTS "match" CASCADE;
DROP VIEW IF EXISTS notification CASCADE;
"""


class Migration(migrations.Migration):
    initial = True
    dependencies = []

    operations = [
        migrations.RunSQL(sql=LEGACY_VIEWS_SQL, reverse_sql=DROP_VIEWS_SQL),
    ]