-- ==============================================================================
-- FOOTTECH — MPD v2 (base simplifiee Coach / Adjoint / Joueur)
-- Aligne sur le cahier des charges simplifie + enrichi avec les documents reels
-- du club : fiche de renseignement joueur, planning hebdomadaire type, fiche
-- d'entrainement (situations/schemas), bilan de saison.
-- Fonctionnalites cibles equivalentes a mycoachsport.com (gestion effectif,
-- planning, suivi joueur) + tacticalpad.com (editeur tactique, fiches seance).
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE SCHEMA IF NOT EXISTS platform;
SET search_path TO platform;

-- ------------------------------------------------------------------------------
-- ENUMS
-- ------------------------------------------------------------------------------

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'account_status_enum') THEN
        CREATE TYPE account_status_enum AS ENUM ('ACTIVE','INACTIVE','BLOCKED');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'activation_channel_enum') THEN
        CREATE TYPE activation_channel_enum AS ENUM ('SMS','WHATSAPP');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'training_status_enum') THEN
        CREATE TYPE training_status_enum AS ENUM ('SCHEDULED','COMPLETED','CANCELLED');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'planning_moment_enum') THEN
        CREATE TYPE planning_moment_enum AS ENUM ('MATIN','APRES_MIDI','SOIR');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'proposal_status_enum') THEN
        CREATE TYPE proposal_status_enum AS ENUM ('PENDING','VALIDATED','REJECTED');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'attendance_status_enum') THEN
        CREATE TYPE attendance_status_enum AS ENUM ('PRESENT','ABSENT','LATE','INJURED');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'match_status_enum') THEN
        CREATE TYPE match_status_enum AS ENUM ('SCHEDULED','LIVE','FINISHED','CANCELLED','POSTPONED');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'lineup_status_enum') THEN
        CREATE TYPE lineup_status_enum AS ENUM ('STARTER','SUBSTITUTE','NOT_SELECTED');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'match_event_type_enum') THEN
        CREATE TYPE match_event_type_enum AS ENUM
            ('GOAL','ASSIST','YELLOW_CARD','RED_CARD','SUBSTITUTION_IN','SUBSTITUTION_OUT','INJURY');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'niveau_scolaire_enum') THEN
        CREATE TYPE niveau_scolaire_enum AS ENUM ('FAIBLE','MOYEN','BIEN','TRES_BIEN');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'pied_fort_enum') THEN
        CREATE TYPE pied_fort_enum AS ENUM ('DROIT','GAUCHE','AMBIDEXTRE');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'guardian_relation_enum') THEN
        CREATE TYPE guardian_relation_enum AS ENUM ('PERE','MERE','TUTEUR');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type_enum') THEN
        CREATE TYPE notification_type_enum AS ENUM
            ('MATCH_CONVOCATION','NEW_TRAINING','REPORT_AVAILABLE','PLANNING_CHANGE','OTHER');
    END IF;
END $$;

-- ------------------------------------------------------------------------------
-- TRIGGER : mise a jour automatique de updated_at
-- ------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS
$$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------------------------------
-- MODULE : AUTHENTICATION / COMPTES
-- Le joueur s'active par code SMS/WhatsApp (pas de mot de passe initial) ;
-- coach/adjoint s'authentifient par email + mot de passe.
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS users (
    id              BIGSERIAL PRIMARY KEY,
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    phone           VARCHAR(30) NOT NULL UNIQUE,
    email           VARCHAR(255) UNIQUE,
    password_hash   TEXT,
    profile_image   VARCHAR(500),
    account_status  account_status_enum NOT NULL DEFAULT 'INACTIVE',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(account_status);

DROP TRIGGER IF EXISTS trg_users_updated ON users;
CREATE TRIGGER trg_users_updated
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TABLE IF NOT EXISTS roles (
    id   BIGSERIAL PRIMARY KEY,
    name VARCHAR(20) NOT NULL UNIQUE  -- COACH | ADJOINT | JOUEUR
);
INSERT INTO roles (name) VALUES ('COACH'), ('ADJOINT'), ('JOUEUR')
    ON CONFLICT (name) DO NOTHING;

CREATE TABLE IF NOT EXISTS user_roles (
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

-- Code d'activation envoye par SMS/WhatsApp lors de la creation d'un profil joueur.
CREATE TABLE IF NOT EXISTS activation_codes (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code        VARCHAR(10) NOT NULL,
    channel     activation_channel_enum NOT NULL DEFAULT 'SMS',
    expires_at  TIMESTAMPTZ NOT NULL,
    used        BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_activation_user ON activation_codes(user_id);

CREATE TABLE IF NOT EXISTS refresh_tokens (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  TEXT NOT NULL UNIQUE,
    expires_at  TIMESTAMPTZ NOT NULL,
    revoked     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id);

CREATE TABLE IF NOT EXISTS push_tokens (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token       TEXT NOT NULL UNIQUE,
    platform    VARCHAR(20),  -- ANDROID | IOS | WEB
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_pushtokens_user ON push_tokens(user_id);

-- ------------------------------------------------------------------------------
-- MODULE : SEASONS / TEAMS
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS seasons (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(20) NOT NULL UNIQUE,  -- ex "2024/2025"
    start_date  DATE NOT NULL,
    end_date    DATE NOT NULL,
    is_current  BOOLEAN NOT NULL DEFAULT FALSE,
    CHECK (end_date > start_date)
);

CREATE TABLE IF NOT EXISTS teams (
    id          BIGSERIAL PRIMARY KEY,
    coach_id    BIGINT NOT NULL REFERENCES users(id),
    name        VARCHAR(150) NOT NULL,        -- ex "Cadet A"
    category    VARCHAR(80),                  -- ex "Cadet"
    logo        VARCHAR(500),
    description TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_teams_coach ON teams(coach_id);

-- Adjoints affectes a une equipe par le coach.
CREATE TABLE IF NOT EXISTS team_staff (
    id          BIGSERIAL PRIMARY KEY,
    team_id     BIGINT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    adjoint_id  BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    added_by    BIGINT REFERENCES users(id),
    added_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (team_id, adjoint_id)
);

-- ------------------------------------------------------------------------------
-- MODULE : JOUEURS (fiche complete inspiree du document club)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS players (
    id                BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    team_id           BIGINT REFERENCES teams(id),
    date_naissance    DATE,
    taille_cm         NUMERIC(5,1),
    poids_kg          NUMERIC(5,1),
    poste_principal   VARCHAR(10),
    poste_secondaire  VARCHAR(10),
    pied_fort         pied_fort_enum,
    numero_maillot    INTEGER CHECK (numero_maillot BETWEEN 1 AND 99)
);
CREATE INDEX IF NOT EXISTS idx_players_team ON players(team_id);

-- Renseignements papa/maman/tuteur (bloc "RENSEIGNEMENTS SUR LE PAPA/LA MAMAN").
CREATE TABLE IF NOT EXISTS player_guardians (
    id            BIGSERIAL PRIMARY KEY,
    player_id     BIGINT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    relation      guardian_relation_enum NOT NULL,
    nom           VARCHAR(100),
    prenom        VARCHAR(100),
    date_naissance DATE,
    tel1          VARCHAR(30),
    tel2          VARCHAR(30),
    email         VARCHAR(255),
    UNIQUE (player_id, relation)
);

-- Adresse / trajet (bloc "ADRESSE COMPLETE / DISTANCE / MOYEN / DUREE").
CREATE TABLE IF NOT EXISTS player_address (
    player_id             BIGINT PRIMARY KEY REFERENCES players(id) ON DELETE CASCADE,
    adresse_complete       TEXT,
    distance_club_km       NUMERIC(6,2),
    moyen_transport         VARCHAR(80),
    duree_trajet_min        INTEGER
);

-- Scolarite (bloc "RENSEIGNEMENT SCOLAIRE").
CREATE TABLE IF NOT EXISTS player_school_info (
    player_id         BIGINT PRIMARY KEY REFERENCES players(id) ON DELETE CASCADE,
    etablissement      VARCHAR(200),
    distance_club_km    NUMERIC(6,2),
    classe             VARCHAR(50),
    niveau_scolaire    niveau_scolaire_enum
);

-- Evolution annuelle morphologie/parcours (bloc "PARCOURS SPORTIFS" 15/16 -> 24/25).
CREATE TABLE IF NOT EXISTS player_season_profile (
    id                    BIGSERIAL PRIMARY KEY,
    player_id             BIGINT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    season                VARCHAR(20) NOT NULL,   -- ex "24/25"
    club_niveau           VARCHAR(200),           -- "PARCOURS SPORTIFS - CLUB - NIVEAU"
    poids_kg              NUMERIC(5,1),
    taille_cm             NUMERIC(5,1),
    pointure              NUMERIC(4,1),
    taille_vetement       VARCHAR(10),
    poste1                VARCHAR(10),
    poste2                VARCHAR(10),
    points_forts          TEXT,
    points_a_ameliorer    TEXT,
    UNIQUE (player_id, season)
);
CREATE INDEX IF NOT EXISTS idx_playerseasonprofile_player ON player_season_profile(player_id);

-- Blessures (bloc "RENSEIGNEMENTS MEDICAUX").
CREATE TABLE IF NOT EXISTS player_injuries (
    id                        BIGSERIAL PRIMARY KEY,
    player_id                 BIGINT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    date_blessure              DATE NOT NULL,
    description                TEXT,
    duree_indisponibilite_jours INTEGER CHECK (duree_indisponibilite_jours >= 0),
    date_retour                 DATE,
    CHECK (date_retour IS NULL OR date_retour >= date_blessure)
);
CREATE INDEX IF NOT EXISTS idx_playerinjuries_player ON player_injuries(player_id);

-- ------------------------------------------------------------------------------
-- MODULE : PLANNING HEBDOMADAIRE (document "PLANNING TYPE")
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS weekly_plannings (
    id              BIGSERIAL PRIMARY KEY,
    team_id         BIGINT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    season_id       BIGINT REFERENCES seasons(id),
    semaine_numero  INTEGER,
    date_debut      DATE NOT NULL,
    date_fin        DATE NOT NULL,
    nombre_seances  INTEGER,
    intensite       VARCHAR(50),
    volume          VARCHAR(50),
    match_prevu     BOOLEAN NOT NULL DEFAULT FALSE,
    CHECK (date_fin >= date_debut),
    UNIQUE (team_id, date_debut)
);
CREATE INDEX IF NOT EXISTS idx_weeklyplanning_team ON weekly_plannings(team_id);

-- Une case du planning (jour x matin/apres-midi), reliee a une seance reelle
-- une fois celle-ci creee dans le module Entrainement.
CREATE TABLE IF NOT EXISTS weekly_planning_slots (
    id                  BIGSERIAL PRIMARY KEY,
    weekly_planning_id   BIGINT NOT NULL REFERENCES weekly_plannings(id) ON DELETE CASCADE,
    jour                 DATE NOT NULL,
    moment                planning_moment_enum NOT NULL,
    training_id            BIGINT,  -- FK ajoutee plus bas (trainings est defini apres)
    description            VARCHAR(255),
    UNIQUE (weekly_planning_id, jour, moment)
);
CREATE INDEX IF NOT EXISTS idx_planningslots_planning ON weekly_planning_slots(weekly_planning_id);

-- ------------------------------------------------------------------------------
-- MODULE : ENTRAINEMENT & FICHE TECHNIQUE (document "FICHE D'ENTRAINEMENT")
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS trainings (
    id          BIGSERIAL PRIMARY KEY,
    team_id     BIGINT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    date        DATE NOT NULL,
    start_time  TIME NOT NULL,
    end_time    TIME NOT NULL,
    location    VARCHAR(255),
    status      training_status_enum NOT NULL DEFAULT 'SCHEDULED',
    created_by  BIGINT REFERENCES users(id),
    CHECK (end_time > start_time),
    UNIQUE (team_id, date, start_time)
);
CREATE INDEX IF NOT EXISTS idx_trainings_team_date ON trainings(team_id, date);

ALTER TABLE weekly_planning_slots
    ADD CONSTRAINT fk_planningslot_training
    FOREIGN KEY (training_id) REFERENCES trainings(id) ON DELETE SET NULL;

-- Fiche technique de la seance : objectifs + effectif (entete du document).
CREATE TABLE IF NOT EXISTS training_sheets (
    id          BIGSERIAL PRIMARY KEY,
    training_id BIGINT NOT NULL UNIQUE REFERENCES trainings(id) ON DELETE CASCADE,
    objectifs   TEXT,
    effectif    VARCHAR(100),   -- ex "20 j + 2 GB"
    created_by  BIGINT REFERENCES users(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Chaque situation/exercice de la fiche (plusieurs par seance, ordonnees).
CREATE TABLE IF NOT EXISTS training_situations (
    id                   BIGSERIAL PRIMARY KEY,
    training_sheet_id     BIGINT NOT NULL REFERENCES training_sheets(id) ON DELETE CASCADE,
    ordre                  INTEGER NOT NULL DEFAULT 1,
    titre                  VARCHAR(150),        -- ex "Situation 1", "Echauffement"
    description             TEXT,                -- contenu de l'exercice
    duree_travail            VARCHAR(20),          -- ex "2*4'"
    duree_recuperation       VARCHAR(20),          -- ex "1'30"
    duree_minutes             INTEGER,              -- duree totale en minutes (pour les totaux de planning)
    criteres_reussite        TEXT[],               -- liste de criteres (bullet points)
    UNIQUE (training_sheet_id, ordre)
);
CREATE INDEX IF NOT EXISTS idx_trainingsituations_sheet ON training_situations(training_sheet_id);

-- Schema tactique / editeur terrain (equivalent TacticalPad) : positions des
-- joueurs, fleches, formes, stockees en JSON pour un rendu canvas cote client.
-- Reutilisable pour une situation d'entrainement OU une preparation de match.
CREATE TABLE IF NOT EXISTS tactical_drawings (
    id                     BIGSERIAL PRIMARY KEY,
    training_situation_id  BIGINT REFERENCES training_situations(id) ON DELETE CASCADE,
    match_id                BIGINT,  -- FK ajoutee plus bas (matches est defini apres)
    canvas_data              JSONB NOT NULL,   -- { players: [...], arrows: [...], shapes: [...] }
    created_by                BIGINT REFERENCES users(id),
    created_at                 TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (training_situation_id IS NOT NULL OR match_id IS NOT NULL)
);
CREATE INDEX IF NOT EXISTS idx_tacticaldrawings_situation ON tactical_drawings(training_situation_id);
CREATE INDEX IF NOT EXISTS idx_tacticaldrawings_match ON tactical_drawings(match_id);

-- Workflow de validation : l'adjoint propose un exercice, le coach valide/refuse.
CREATE TABLE IF NOT EXISTS exercise_proposals (
    id               BIGSERIAL PRIMARY KEY,
    training_id       BIGINT REFERENCES trainings(id) ON DELETE CASCADE,
    proposed_by        BIGINT NOT NULL REFERENCES users(id),  -- adjoint
    titre               VARCHAR(150) NOT NULL,
    description          TEXT,
    status                proposal_status_enum NOT NULL DEFAULT 'PENDING',
    reviewed_by            BIGINT REFERENCES users(id),  -- coach
    reviewed_at             TIMESTAMPTZ,
    review_comment           TEXT,
    created_at                TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_exerciseproposals_training ON exercise_proposals(training_id);
CREATE INDEX IF NOT EXISTS idx_exerciseproposals_status ON exercise_proposals(status);

-- ------------------------------------------------------------------------------
-- MODULE : PRESENCE
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS attendances (
    id          BIGSERIAL PRIMARY KEY,
    training_id BIGINT NOT NULL REFERENCES trainings(id) ON DELETE CASCADE,
    player_id   BIGINT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    status      attendance_status_enum NOT NULL,
    comment     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (training_id, player_id)
);
CREATE INDEX IF NOT EXISTS idx_attendance_player ON attendances(player_id);

-- ------------------------------------------------------------------------------
-- MODULE : MATCHS (pre-match / live / post-match)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS matches (
    id            BIGSERIAL PRIMARY KEY,
    team_id       BIGINT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    season_id     BIGINT REFERENCES seasons(id),
    adversaire    VARCHAR(150) NOT NULL,
    date_heure    TIMESTAMPTZ NOT NULL,
    lieu          VARCHAR(255),
    is_home       BOOLEAN NOT NULL DEFAULT TRUE,
    formation     VARCHAR(20),   -- ex "4-3-3"
    home_score    INTEGER NOT NULL DEFAULT 0 CHECK (home_score >= 0),
    away_score    INTEGER NOT NULL DEFAULT 0 CHECK (away_score >= 0),
    match_status  match_status_enum NOT NULL DEFAULT 'SCHEDULED',
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_matches_team ON matches(team_id);
CREATE INDEX IF NOT EXISTS idx_matches_season ON matches(season_id);
CREATE INDEX IF NOT EXISTS idx_matches_status ON matches(match_status);

ALTER TABLE tactical_drawings
    ADD CONSTRAINT fk_tacticaldrawing_match
    FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE;

-- Selection pre-match : titulaire / remplacant / non retenu.
CREATE TABLE IF NOT EXISTS match_lineups (
    id                BIGSERIAL PRIMARY KEY,
    match_id           BIGINT NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    player_id           BIGINT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    status                lineup_status_enum NOT NULL DEFAULT 'NOT_SELECTED',
    position_terrain       VARCHAR(10),
    selected_by              BIGINT REFERENCES users(id),
    UNIQUE (match_id, player_id)
);
CREATE INDEX IF NOT EXISTS idx_matchlineups_match ON match_lineups(match_id);

-- Score de recommandation IA (presence / performance / fatigue -> score final).
CREATE TABLE IF NOT EXISTS ai_lineup_recommendations (
    id                  BIGSERIAL PRIMARY KEY,
    match_id             BIGINT NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    player_id             BIGINT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    presence_score          NUMERIC(4,3) CHECK (presence_score BETWEEN 0 AND 1),
    performance_score        NUMERIC(4,3) CHECK (performance_score BETWEEN 0 AND 1),
    fatigue_score              NUMERIC(4,3) CHECK (fatigue_score BETWEEN 0 AND 1),
    final_score                  NUMERIC(4,3) CHECK (final_score BETWEEN 0 AND 1),
    recommended_status              lineup_status_enum,
    generated_at                      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (match_id, player_id)
);
CREATE INDEX IF NOT EXISTS idx_airecommendations_match ON ai_lineup_recommendations(match_id);

-- Timeline live saisie par l'adjoint pendant le match (but/carton/changement/blessure).
CREATE TABLE IF NOT EXISTS match_events (
    id                   BIGSERIAL PRIMARY KEY,
    match_id              BIGINT NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    event_type             match_event_type_enum NOT NULL,
    minute                    INTEGER NOT NULL CHECK (minute >= 0),
    player_id                  BIGINT REFERENCES players(id),
    related_player_id            BIGINT REFERENCES players(id),  -- passeur, ou joueur remplace
    comment                       VARCHAR(255),
    created_by                     BIGINT REFERENCES users(id),   -- adjoint qui saisit
    created_at                       TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_matchevents_match ON match_events(match_id, minute);

-- Stats agregees par joueur/match (alimente le bilan de saison, cf. XLSX club).
CREATE TABLE IF NOT EXISTS match_player_stats (
    id                BIGSERIAL PRIMARY KEY,
    match_id           BIGINT NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    player_id           BIGINT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    minutes_played        INTEGER NOT NULL DEFAULT 0,
    goals                   INTEGER NOT NULL DEFAULT 0,
    assists                   INTEGER NOT NULL DEFAULT 0,
    goals_conceded              INTEGER NOT NULL DEFAULT 0,   -- pertinent pour les gardiens
    yellow_cards                  SMALLINT NOT NULL DEFAULT 0,
    red_cards                       SMALLINT NOT NULL DEFAULT 0,
    UNIQUE (match_id, player_id)
);
CREATE INDEX IF NOT EXISTS idx_matchplayerstats_player ON match_player_stats(player_id);

-- Evaluation post-match (note + commentaire, coach et/ou adjoint).
CREATE TABLE IF NOT EXISTS match_evaluations (
    id             BIGSERIAL PRIMARY KEY,
    match_id        BIGINT NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    player_id        BIGINT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    note               NUMERIC(3,1) CHECK (note BETWEEN 0 AND 10),
    commentaire          TEXT,
    evaluated_by           BIGINT NOT NULL REFERENCES users(id),
    evaluated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (match_id, player_id, evaluated_by)
);
CREATE INDEX IF NOT EXISTS idx_matchevaluations_match ON match_evaluations(match_id);

-- Rapport de match genere (PDF).
CREATE TABLE IF NOT EXISTS match_reports (
    id            BIGSERIAL PRIMARY KEY,
    match_id       BIGINT NOT NULL UNIQUE REFERENCES matches(id) ON DELETE CASCADE,
    pdf_url          VARCHAR(500),
    generated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------------------------
-- MODULE : NOTIFICATIONS
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS notifications (
    id                  BIGSERIAL PRIMARY KEY,
    user_id              BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type                   notification_type_enum NOT NULL,
    title                    VARCHAR(200) NOT NULL,
    message                    TEXT NOT NULL,
    related_entity_type          VARCHAR(50),   -- ex 'match', 'training'
    related_entity_id              BIGINT,
    is_read                          BOOLEAN NOT NULL DEFAULT FALSE,
    created_at                         TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id) WHERE is_read = FALSE;

-- ------------------------------------------------------------------------------
-- VUE : BILAN DE SAISON PAR JOUEUR
-- Reproduit directement la structure du fichier "Bilan_Cadet_A.xlsx" du club :
-- matchs joues, temps de jeu, note moyenne, buts, passes, buts encaisses.
-- ------------------------------------------------------------------------------

CREATE OR REPLACE VIEW player_season_bilan AS
SELECT
    p.id                                                  AS player_id,
    u.first_name,
    u.last_name,
    p.poste_principal,
    p.poste_secondaire,
    m.season_id,
    COUNT(DISTINCT mps.match_id) FILTER (WHERE mps.minutes_played > 0)  AS nombre_matchs_joues,
    COALESCE(SUM(mps.minutes_played), 0)                                AS temps_de_jeu_minutes,
    ROUND(AVG(me.note), 2)                                              AS moyenne_note,
    COALESCE(SUM(mps.goals), 0)                                         AS total_buts,
    COALESCE(SUM(mps.assists), 0)                                       AS total_passes_decisives,
    COALESCE(SUM(mps.goals_conceded), 0)                                AS total_buts_encaisses
FROM players p
INNER JOIN users u ON u.id = p.id
LEFT JOIN match_player_stats mps ON mps.player_id = p.id
LEFT JOIN matches m ON m.id = mps.match_id
LEFT JOIN match_evaluations me ON me.match_id = mps.match_id AND me.player_id = p.id
GROUP BY p.id, u.first_name, u.last_name, p.poste_principal, p.poste_secondaire, m.season_id;

-- ==============================================================================
-- MODULE : CALENDRIER PARTAGE
-- Un seul calendrier partage pour tous les membres d'une equipe (coach, adjoint,
-- joueurs). Permission: joueur = lecture seule (titre seulement), adjoint =
-- creation/mise a jour, coach = CRUD complet.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS calendar_events (
    id            BIGSERIAL PRIMARY KEY,
    team_id       BIGINT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    title         VARCHAR(200) NOT NULL,
    description   TEXT,
    start_time    TIMESTAMPTZ NOT NULL,
    end_time      TIMESTAMPTZ,
    all_day       BOOLEAN NOT NULL DEFAULT FALSE,
    location      VARCHAR(255),
    color         VARCHAR(20),
    created_by    BIGINT REFERENCES users(id),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (end_time IS NULL OR end_time >= start_time)
);
CREATE INDEX IF NOT EXISTS idx_calendarevents_team ON calendar_events(team_id);
CREATE INDEX IF NOT EXISTS idx_calendarevents_team_start ON calendar_events(team_id, start_time);

-- ==============================================================================
-- FIN DU SCRIPT
-- ==============================================================================
