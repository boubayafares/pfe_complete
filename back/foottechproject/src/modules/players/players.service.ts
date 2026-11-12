import { PlayersRepository } from './players.repository.js';
import type{
  CreatePlayerDto,
  UpdatePlayerDto,
  UpsertGuardianDto,
  UpsertAddressDto,
  UpsertSchoolInfoDto,
  UpsertSeasonProfileDto,
  CreateInjuryDto,
  UpdateInjuryDto,
} from './players.dto.js';
import type{ PlayerListFilters } from './players.types.js';
import type{ ParsedPagination } from '../../shared/utils/pagination.js';
import { ForbiddenError, NotFoundError } from '../../shared/errors/AppError.js';
import {
  generateOtp,
  otpExpiryDate,
} from '../../shared/utils/otp.js';
import { sendOtpBestEffort } from '../../shared/services/notification.service.js';
import { AuthRepository } from '../auth/auth.repository.js';
import { hashActivationCode } from '../../shared/utils/activation-code.js';

export class PlayersService {
  private readonly repo = new PlayersRepository();
  private readonly authRepo = new AuthRepository();

  async list(filters: PlayerListFilters, pagination: ParsedPagination, user: { sub: number; role: 'COACH' | 'ADJOINT' | 'JOUEUR'; teamId?: number }) {
    if (user.role === 'JOUEUR') return this.repo.findWithFilters({ ...filters, playerId: user.sub }, pagination);
    const teamId = await this.authRepo.getTeamIdForUser(user.sub, user.role, user.teamId);
    if (!teamId) throw new ForbiddenError('User is not assigned to a team');
    return this.repo.findWithFilters({ ...filters, teamId }, pagination);
  }

  async getProfile(id: number) {
    const profile = await this.repo.findProfileById(id);
    if (!profile) throw new NotFoundError('Player');
    return profile;
  }

  async create(dto: CreatePlayerDto, user: { sub: number; role: 'COACH' | 'ADJOINT' | 'JOUEUR'; teamId?: number }) {
    if (user.role !== 'COACH' && user.role !== 'ADJOINT'){
       throw new ForbiddenError('Insufficient role');
    }
    const teamId = await this.authRepo.getTeamIdForUser(user.sub, user.role, user.teamId);
    if (!teamId){
       throw new ForbiddenError('User is not assigned to a team');
    }
     const player = await this.repo.createPlayer({
    ...dto,
    teamId,
  });
    // Generate + persist an activation OTP so the player can activate via
    // POST /auth/player/verify-otp using the same code the coach saw.
    const code = generateOtp();
    await this.authRepo.createActivationCode(
      player.id,
      hashActivationCode(player.id, code),
      'SMS',
      otpExpiryDate()
    );
    const delivered = await sendOtpBestEffort(dto.phone, code, 'SMS');
    return { ...player, activationDelivery: delivered ? 'SENT' as const : 'FAILED' as const };
  }

  async update(id: number, dto: UpdatePlayerDto) {
    const existing = await this.repo.findById(id);
    if (!existing) throw new NotFoundError('Player');
    const payload: Record<string, unknown> = {};
    if (dto.dateNaissance !== undefined) payload.date_naissance = dto.dateNaissance;
    if (dto.tailleCm !== undefined) payload.taille_cm = dto.tailleCm;
    if (dto.poidsKg !== undefined) payload.poids_kg = dto.poidsKg;
    if (dto.posteP !== undefined) payload.poste_principal = dto.posteP;
    if (dto.posteS !== undefined) payload.poste_secondaire = dto.posteS;
    if (dto.piedFort !== undefined) payload.pied_fort = dto.piedFort;
    if (dto.numeroMaillot !== undefined) payload.numero_maillot = dto.numeroMaillot;
    return this.repo.update(id, payload);
  }

  private async assertExists(id: number) {
    const existing = await this.repo.findById(id);
    if (!existing) throw new NotFoundError('Player');
  }

  // --- Guardians -------------------------------------------------------------

  async upsertGuardian(playerId: number, dto: UpsertGuardianDto) {
    await this.assertExists(playerId);
    return this.repo.upsertGuardian(playerId, {
      relation: dto.relation,
      nom: dto.nom,
      prenom: dto.prenom,
      date_naissance: dto.dateNaissance,
      tel1: dto.tel1,
      tel2: dto.tel2,
      email: dto.email,
    });
  }

  async listGuardians(playerId: number) {
    await this.assertExists(playerId);
    return this.repo.listGuardians(playerId);
  }

  // --- Address ------------------------------------------------------------------

  async upsertAddress(playerId: number, dto: UpsertAddressDto) {
    await this.assertExists(playerId);
    return this.repo.upsertAddress(playerId, {
      adresse_complete: dto.adresseComplete,
      distance_club_km: dto.distanceClubKm,
      moyen_transport: dto.moyenTransport,
      duree_trajet_min: dto.dureeTrajetMin,
    });
  }

  async getAddress(playerId: number) {
    await this.assertExists(playerId);
    return this.repo.getAddress(playerId);
  }

  // --- School info -----------------------------------------------------------------

  async upsertSchoolInfo(playerId: number, dto: UpsertSchoolInfoDto) {
    await this.assertExists(playerId);
    return this.repo.upsertSchoolInfo(playerId, {
      etablissement: dto.etablissement,
      distance_club_km: dto.distanceClubKm,
      classe: dto.classe,
      niveau_scolaire: dto.niveauScolaire,
    });
  }

  async getSchoolInfo(playerId: number) {
    await this.assertExists(playerId);
    return this.repo.getSchoolInfo(playerId);
  }

  // --- Season profile -----------------------------------------------------------------

  async upsertSeasonProfile(playerId: number, dto: UpsertSeasonProfileDto) {
    await this.assertExists(playerId);
    return this.repo.upsertSeasonProfile(playerId, {
      season: dto.season,
      club_niveau: dto.clubNiveau,
      poids_kg: dto.poidsKg,
      taille_cm: dto.tailleCm,
      pointure: dto.pointure,
      taille_vetement: dto.tailleVetement,
      poste1: dto.poste1,
      poste2: dto.poste2,
      points_forts: dto.pointsForts,
      points_a_ameliorer: dto.pointsAAmeliorer,
    });
  }

  async listSeasonProfiles(playerId: number) {
    await this.assertExists(playerId);
    return this.repo.listSeasonProfiles(playerId);
  }

  // --- Injuries -----------------------------------------------------------------------

  async createInjury(playerId: number, dto: CreateInjuryDto) {
    await this.assertExists(playerId);
    return this.repo.createInjury(playerId, {
      date_blessure: dto.dateBlessure,
      description: dto.description,
      duree_indisponibilite_jours: dto.dureeIndisponibiliteJours,
    });
  }

  async updateInjury(playerId: number, injuryId: number, dto: UpdateInjuryDto) {
    await this.assertExists(playerId);
    const payload: Record<string, unknown> = {};
    if (dto.dateRetour !== undefined) payload.date_retour = dto.dateRetour;
    if (dto.description !== undefined) payload.description = dto.description;
    if (dto.dureeIndisponibiliteJours !== undefined) payload.duree_indisponibilite_jours = dto.dureeIndisponibiliteJours;
    const updated = await this.repo.updateInjury(injuryId, playerId, payload);
    if (!updated) throw new NotFoundError('Injury');
    return updated;
  }

  async listInjuries(playerId: number) {
    await this.assertExists(playerId);
    return this.repo.listInjuries(playerId);
  }

  async deleteInjury(playerId: number, injuryId: number) {
    const deleted = await this.repo.deleteInjury(injuryId, playerId);
    if (!deleted) throw new NotFoundError('Injury');
  }
}
