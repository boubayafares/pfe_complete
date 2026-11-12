import { query, withTransaction } from '../../config/database.js';
import type{ PoolClient } from 'pg';
import { BaseRepository } from '../../shared/database/BaseRepository.js';
import type{ ParsedPagination } from '../../shared/utils/pagination.js';
import type{
  PlayerRecord,
  PlayerProfile,
  GuardianRecord,
  AddressRecord,
  SchoolInfoRecord,
  SeasonProfileRecord,
  InjuryRecord,
} from './players.interface.js';
import type{ PlayerListFilters } from './players.types.js';
import type{ CreatePlayerDto } from './players.dto.js';
import { ConflictError } from '../../shared/errors/AppError.js';

export class PlayersRepository extends BaseRepository<PlayerRecord> {
  constructor() {
    super('players');
  }

  async findWithFilters(
    filters: PlayerListFilters,
    pagination: ParsedPagination
  ): Promise<{ rows: PlayerProfile[]; total: number }> {
    const conditions: string[] = [];
    const params: unknown[] = [];

    if (filters.teamId) {
      params.push(filters.teamId);
      conditions.push(`p.team_id = $${params.length}`);
    }
    if (filters.playerId) {
      params.push(filters.playerId);
      conditions.push(`p.id = $${params.length}`);
    }

    if (filters.posteP) {
      params.push(filters.posteP);
      conditions.push(`p.poste_principal = $${params.length}`);
    }
    if (filters.search) {
      params.push(`%${filters.search}%`);
      conditions.push(`(u.first_name ILIKE $${params.length} OR u.last_name ILIKE $${params.length})`);
    }

    const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const countResult = await query<{ count: string }>(
      `SELECT COUNT(*) FROM players p INNER JOIN users u ON u.id = p.id ${whereClause}`,
      params
    );

    params.push(pagination.limit, pagination.offset);
    const rowsResult = await query<PlayerProfile>(
      `SELECT p.*, u.first_name, u.last_name, u.phone, u.profile_image, u.account_status
       FROM players p INNER JOIN users u ON u.id = p.id ${whereClause}
       ORDER BY p.numero_maillot NULLS LAST LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );

    return { rows: rowsResult.rows, total: parseInt(countResult.rows[0]?.count ?? '0', 10) };
  }

  async findProfileById(id: number): Promise<PlayerProfile | null> {
    const result = await query<PlayerProfile>(
      `SELECT p.*, u.first_name, u.last_name, u.phone, u.profile_image, u.account_status FROM players p INNER JOIN users u ON u.id = p.id WHERE p.id = $1`,
      [id]
    );
    return result.rows[0] ?? null;
  }

  /** Creates the user shell (INACTIVE, no password — activated via phone OTP) + JOUEUR role + players row. */
  async createPlayer(dto: CreatePlayerDto & { teamId: number }): Promise<PlayerProfile> {
    const existingPhone = await query('SELECT 1 FROM users WHERE phone = $1', [dto.phone]);
    if ((existingPhone.rowCount ?? 0) > 0) {
      throw new ConflictError('An account with this phone number already exists');
    }

    return withTransaction(async (client: PoolClient) => {
      const userResult = await client.query(
        `INSERT INTO users (first_name, last_name, phone, account_status) VALUES ($1, $2, $3, 'INACTIVE') RETURNING id`,
        [dto.firstName, dto.lastName, dto.phone]
      );
      const playerId = userResult.rows[0].id as number;

      const roleResult = await client.query(`SELECT id FROM roles WHERE name = 'JOUEUR'`);
      await client.query(`INSERT INTO user_roles (user_id, role_id) VALUES ($1, $2)`, [playerId, roleResult.rows[0].id]);

      const playerResult = await client.query(
        `INSERT INTO players (id, team_id, date_naissance, poste_principal, poste_secondaire, pied_fort, numero_maillot)
         VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
        [playerId, dto.teamId, dto.dateNaissance ?? null, dto.posteP ?? null, dto.posteS ?? null, dto.piedFort ?? null, dto.numeroMaillot ?? null]
      );

      return {
        ...playerResult.rows[0],
        first_name: dto.firstName,
        last_name: dto.lastName,
        phone: dto.phone,
        profile_image: null,
        account_status: 'INACTIVE',
      } as PlayerProfile;
    });
  }

  // --- Guardians (one row per PERE/MERE/TUTEUR, upserted) ------------------

  async upsertGuardian(playerId: number, data: Record<string, unknown>): Promise<GuardianRecord> {
    const result = await query<GuardianRecord>(
      `INSERT INTO player_guardians (player_id, relation, nom, prenom, date_naissance, tel1, tel2, email)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       ON CONFLICT (player_id, relation) DO UPDATE SET
         nom = EXCLUDED.nom, prenom = EXCLUDED.prenom, date_naissance = EXCLUDED.date_naissance,
         tel1 = EXCLUDED.tel1, tel2 = EXCLUDED.tel2, email = EXCLUDED.email
       RETURNING *`,
      [playerId, data.relation, data.nom ?? null, data.prenom ?? null, data.date_naissance ?? null, data.tel1 ?? null, data.tel2 ?? null, data.email ?? null]
    );
    return result.rows[0]!;
  }

  async listGuardians(playerId: number): Promise<GuardianRecord[]> {
    const result = await query<GuardianRecord>('SELECT * FROM player_guardians WHERE player_id = $1', [playerId]);
    return result.rows;
  }

  // --- Address (1:1) --------------------------------------------------------

  async upsertAddress(playerId: number, data: Record<string, unknown>): Promise<AddressRecord> {
    const result = await query<AddressRecord>(
      `INSERT INTO player_address (player_id, adresse_complete, distance_club_km, moyen_transport, duree_trajet_min)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (player_id) DO UPDATE SET
         adresse_complete = EXCLUDED.adresse_complete, distance_club_km = EXCLUDED.distance_club_km,
         moyen_transport = EXCLUDED.moyen_transport, duree_trajet_min = EXCLUDED.duree_trajet_min
       RETURNING *`,
      [playerId, data.adresse_complete ?? null, data.distance_club_km ?? null, data.moyen_transport ?? null, data.duree_trajet_min ?? null]
    );
    return result.rows[0]!;
  }

  async getAddress(playerId: number): Promise<AddressRecord | null> {
    const result = await query<AddressRecord>('SELECT * FROM player_address WHERE player_id = $1', [playerId]);
    return result.rows[0] ?? null;
  }

  // --- School info (1:1) -----------------------------------------------------

  async upsertSchoolInfo(playerId: number, data: Record<string, unknown>): Promise<SchoolInfoRecord> {
    const result = await query<SchoolInfoRecord>(
      `INSERT INTO player_school_info (player_id, etablissement, distance_club_km, classe, niveau_scolaire)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (player_id) DO UPDATE SET
         etablissement = EXCLUDED.etablissement, distance_club_km = EXCLUDED.distance_club_km,
         classe = EXCLUDED.classe, niveau_scolaire = EXCLUDED.niveau_scolaire
       RETURNING *`,
      [playerId, data.etablissement ?? null, data.distance_club_km ?? null, data.classe ?? null, data.niveau_scolaire ?? null]
    );
    return result.rows[0]!;
  }

  async getSchoolInfo(playerId: number): Promise<SchoolInfoRecord | null> {
    const result = await query<SchoolInfoRecord>('SELECT * FROM player_school_info WHERE player_id = $1', [playerId]);
    return result.rows[0] ?? null;
  }

  // --- Season profile (one row per season, upserted) --------------------------

  async upsertSeasonProfile(playerId: number, data: Record<string, unknown>): Promise<SeasonProfileRecord> {
    const result = await query<SeasonProfileRecord>(
      `INSERT INTO player_season_profile
         (player_id, season, club_niveau, poids_kg, taille_cm, pointure, taille_vetement, poste1, poste2, points_forts, points_a_ameliorer)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
       ON CONFLICT (player_id, season) DO UPDATE SET
         club_niveau = EXCLUDED.club_niveau, poids_kg = EXCLUDED.poids_kg, taille_cm = EXCLUDED.taille_cm,
         pointure = EXCLUDED.pointure, taille_vetement = EXCLUDED.taille_vetement,
         poste1 = EXCLUDED.poste1, poste2 = EXCLUDED.poste2,
         points_forts = EXCLUDED.points_forts, points_a_ameliorer = EXCLUDED.points_a_ameliorer
       RETURNING *`,
      [
        playerId, data.season, data.club_niveau ?? null, data.poids_kg ?? null, data.taille_cm ?? null,
        data.pointure ?? null, data.taille_vetement ?? null, data.poste1 ?? null, data.poste2 ?? null,
        data.points_forts ?? null, data.points_a_ameliorer ?? null,
      ]
    );
    return result.rows[0]!;
  }

  async listSeasonProfiles(playerId: number): Promise<SeasonProfileRecord[]> {
    const result = await query<SeasonProfileRecord>(
      'SELECT * FROM player_season_profile WHERE player_id = $1 ORDER BY season DESC',
      [playerId]
    );
    return result.rows;
  }

  // --- Injuries (plain CRUD, several per player) --------------------------------

  async createInjury(playerId: number, data: Record<string, unknown>): Promise<InjuryRecord> {
    const result = await query<InjuryRecord>(
      `INSERT INTO player_injuries (player_id, date_blessure, description, duree_indisponibilite_jours)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [playerId, data.date_blessure, data.description ?? null, data.duree_indisponibilite_jours ?? null]
    );
    return result.rows[0]!;
  }

  async updateInjury(injuryId: number, playerId: number, data: Record<string, unknown>): Promise<InjuryRecord | null> {
    const columns = Object.keys(data);
    if (columns.length === 0) return null;
    const setClause = columns.map((col, i) => `${col} = $${i + 1}`).join(', ');
    const result = await query<InjuryRecord>(
      `UPDATE player_injuries SET ${setClause} WHERE id = $${columns.length + 1} AND player_id = $${columns.length + 2} RETURNING *`,
      [...Object.values(data), injuryId, playerId]
    );
    return result.rows[0] ?? null;
  }

  async listInjuries(playerId: number): Promise<InjuryRecord[]> {
    const result = await query<InjuryRecord>(
      'SELECT * FROM player_injuries WHERE player_id = $1 ORDER BY date_blessure DESC',
      [playerId]
    );
    return result.rows;
  }

  async deleteInjury(injuryId: number, playerId: number): Promise<boolean> {
    const result = await query('DELETE FROM player_injuries WHERE id = $1 AND player_id = $2', [injuryId, playerId]);
    return (result.rowCount ?? 0) > 0;
  }
}
