import { TeamsRepository } from './teams.repository.js';
import type{ CreateTeamDto, UpdateTeamDto, AddAdjointDto } from './teams.dto.js';
import type{ TeamListFilters } from './teams.types.js';
import type{ ParsedPagination } from '../../shared/utils/pagination.js';
import { NotFoundError, ForbiddenError } from '../../shared/errors/AppError.js';
import { AuthRepository } from '../auth/auth.repository.js';
import { generateOtp, otpExpiryDate } from '../../shared/utils/otp.js';
import { hashActivationCode } from '../../shared/utils/activation-code.js';
import { sendOtpBestEffort } from '../../shared/services/notification.service.js';

export class TeamsService {
  private readonly repo = new TeamsRepository();
  private readonly authRepo = new AuthRepository();

  async list(filters: TeamListFilters, pagination: ParsedPagination) {
    return this.repo.findWithFilters(filters, pagination);
  }

  async getById(id: number) {
    const team = await this.repo.findById(id);
    if (!team) throw new NotFoundError('Team');
    return team;
  }

  async create(coachId: number, dto: CreateTeamDto) {
    return this.repo.create({
      coach_id: coachId,
      name: dto.name,
      category: dto.category ?? null,
      logo: dto.logo ?? null,
      description: dto.description ?? null,
    });
  }

  private async assertOwnedByCoach(teamId: number, coachId: number) {
    const team = await this.repo.findById(teamId);
    if (!team) throw new NotFoundError('Team');
    if (Number(team.coach_id) !== Number(coachId)) throw new ForbiddenError('This team does not belong to you');
    return team;
  }

  async update(id: number, coachId: number, dto: UpdateTeamDto) {
    await this.assertOwnedByCoach(id, coachId);
    const payload: Record<string, unknown> = {};
    if (dto.name !== undefined) payload.name = dto.name;
    if (dto.category !== undefined) payload.category = dto.category;
    if (dto.logo !== undefined) payload.logo = dto.logo;
    if (dto.description !== undefined) payload.description = dto.description;
    return this.repo.update(id, payload);
  }

  async remove(id: number, coachId: number) {
    await this.assertOwnedByCoach(id, coachId);
    await this.repo.delete(id);
  }

  async getStaff(teamId: number) {
    const team = await this.repo.findById(teamId);
    if (!team) throw new NotFoundError('Team');
    return this.repo.getStaff(teamId);
  }

  async addAdjoint(teamId: number, coachId: number, dto: AddAdjointDto) {
    await this.assertOwnedByCoach(teamId, coachId);
    const staff = await this.repo.addAdjoint(teamId, coachId, dto);
    const adjointId = Number(staff.adjoint_id);
    const code = generateOtp();
    await this.authRepo.createActivationCode(
      adjointId,
      hashActivationCode(adjointId, code),
      'SMS',
      otpExpiryDate()
    );
    const delivered = await sendOtpBestEffort(dto.phone, code, 'SMS');
    return { ...staff, activationDelivery: delivered ? 'SENT' as const : 'FAILED' as const };
  }

  async removeAdjoint(teamId: number, coachId: number, adjointId: number) {
    await this.assertOwnedByCoach(teamId, coachId);
    await this.repo.removeAdjoint(teamId, adjointId);
  }
}
