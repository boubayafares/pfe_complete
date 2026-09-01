import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Local SQLite database for the fully offline FootTech app.
///
/// Replaces the external Express + PostgreSQL backend. Every entity that used
/// to live server-side is now persisted on-device. The database holds the
/// schema for the currently migrated features (users, teams, players and
/// their sub-records). New tables can be added by bumping [version] and
/// extending [_migrations].
class AppDatabase {
  AppDatabase._();

  static Database? _db;

  /// version 2: added player sub-records (guardians, address, school info,
  /// season profiles, injuries) and the unique `code` column on users to
  /// support the offline adjoint/player activation flows.
  ///
  /// version 3: added `users.profile_image` so the profile avatar can be
  /// stored as a local file path (offline-friendly).
  static const int _version = 3;

  /// The authenticated Coach/Adjoint/Player is stored in this table so the
  /// app behaves like the old JWT session cache.
  static const int _sessionUserId = 1;

  static Future<Database> get instance async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'foottech.db');
    return openDatabase(
      path,
      version: _version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _runMigrations(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _runMigrations(db);
        if (oldVersion < 3) {
          await _upgradeTo3(db);
        }
      },
    );
  }

  static Future<void> _upgradeTo3(Database db) async {
    final cols = await db.rawQuery('PRAGMA table_info(users)');
    final hasImage = cols.any((c) => c['name'] == 'profile_image');
    if (!hasImage) {
      await db.execute("ALTER TABLE users ADD COLUMN profile_image TEXT");
    }
  }

  static Future<void> _runMigrations(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        email TEXT,
        password_hash TEXT,
        role TEXT NOT NULL,
        account_status TEXT NOT NULL,
        team_id INTEGER,
        code TEXT,
        profile_image TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS teams (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT,
        logo TEXT,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS players (
        id INTEGER PRIMARY KEY,
        team_id INTEGER NOT NULL,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        account_status TEXT NOT NULL,
        date_naissance TEXT,
        taille_cm REAL,
        poids_kg REAL,
        poste_principal TEXT,
        poste_secondaire TEXT,
        pied_fort TEXT,
        numero_maillot INTEGER,
        FOREIGN KEY (team_id) REFERENCES teams (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS guardians (
        id INTEGER PRIMARY KEY,
        player_id INTEGER NOT NULL,
        relation TEXT NOT NULL,
        nom TEXT,
        prenom TEXT,
        tel1 TEXT,
        tel2 TEXT,
        email TEXT,
        FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS player_addresses (
        player_id INTEGER PRIMARY KEY,
        adresse_complete TEXT,
        distance_club_km REAL,
        moyen_transport TEXT,
        duree_trajet_min INTEGER,
        FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS player_school_info (
        player_id INTEGER PRIMARY KEY,
        etablissement TEXT,
        classe TEXT,
        niveau_scolaire TEXT,
        FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS player_season_profiles (
        id INTEGER PRIMARY KEY,
        player_id INTEGER NOT NULL,
        season TEXT NOT NULL,
        poids_kg REAL,
        taille_cm REAL,
        poste1 TEXT,
        poste2 TEXT,
        points_forts TEXT,
        points_a_ameliorer TEXT,
        UNIQUE(player_id, season),
        FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS player_injuries (
        id INTEGER PRIMARY KEY,
        player_id INTEGER NOT NULL,
        date_blessure TEXT NOT NULL,
        description TEXT,
        duree_indisponibilite_jours INTEGER,
        date_retour TEXT,
        FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<int> get sessionUserId async {
    await instance;
    return _sessionUserId;
  }
}
