import { WeeklyPlanningsRepository } from './weekly-plannings.repository.js';
import type{ CreateWeeklyPlanningDto, UpdateWeeklyPlanningDto, UpsertSlotDto } from './weekly-plannings.dto.js';
import { BadRequestError, NotFoundError, ForbiddenError } from '../../shared/errors/AppError.js';
import { SeasonsRepository } from '../seasons/seasons.repository.js';

export class WeeklyPlanningsService {
  private readonly repo = new WeeklyPlanningsRepository();
  private readonly seasonsRepo = new SeasonsRepository();

  async list(teamId?: number, seasonId?: number) {
    return this.repo.findWithFilters(teamId, seasonId);
  }

  async getById(id: number) {
    const planning = await this.repo.findById(id);
    if (!planning) throw new NotFoundError('Weekly planning');
    return planning;
  }

  async create(dto: CreateWeeklyPlanningDto, teamId?: number) {
    if (!teamId) throw new ForbiddenError('User is not assigned to a team');
    if (dto.seasonId !== undefined && !(await this.seasonsRepo.isAccessible(dto.seasonId, teamId))) {
      throw new ForbiddenError('The selected season is not available to this team');
    }
    return this.repo.create({
      team_id: teamId,
      season_id: dto.seasonId ?? null,
      semaine_numero: dto.semaineNumero ?? null,
      date_debut: dto.dateDebut,
      date_fin: dto.dateFin,
      nombre_seances: dto.nombreSeances ?? null,
      intensite: dto.intensite ?? null,
      volume: dto.volume ?? null,
      match_prevu: dto.matchPrevu ?? false,
    });
  }

  async update(id: number, dto: UpdateWeeklyPlanningDto) {
    const existing = await this.repo.findById(id);
    if (!existing) throw new NotFoundError('Weekly planning');
    const startDate = new Date(dto.dateDebut ?? existing.date_debut);
    const endDate = new Date(dto.dateFin ?? existing.date_fin);
    if (endDate < startDate) {
      throw new BadRequestError('dateFin must be on or after dateDebut');
    }
    if (
      dto.seasonId !== undefined
      && !(await this.seasonsRepo.isAccessible(dto.seasonId, Number(existing.team_id)))
    ) {
      throw new ForbiddenError('The selected season is not available to this team');
    }
    const payload: Record<string, unknown> = {};
    if (dto.seasonId !== undefined) payload.season_id = dto.seasonId;
    if (dto.semaineNumero !== undefined) payload.semaine_numero = dto.semaineNumero;
    if (dto.dateDebut !== undefined) payload.date_debut = dto.dateDebut;
    if (dto.dateFin !== undefined) payload.date_fin = dto.dateFin;
    if (dto.nombreSeances !== undefined) payload.nombre_seances = dto.nombreSeances;
    if (dto.intensite !== undefined) payload.intensite = dto.intensite;
    if (dto.volume !== undefined) payload.volume = dto.volume;
    if (dto.matchPrevu !== undefined) payload.match_prevu = dto.matchPrevu;
    return this.repo.update(id, payload);
  }

  async remove(id: number) {
    const deleted = await this.repo.delete(id);
    if (!deleted) throw new NotFoundError('Weekly planning');
  }

  async upsertSlot(weeklyPlanningId: number, dto: UpsertSlotDto) {
    const existing = await this.repo.findById(weeklyPlanningId);
    if (!existing) throw new NotFoundError('Weekly planning');
    if (
      dto.trainingId !== undefined
      && !(await this.repo.trainingBelongsToTeam(dto.trainingId, Number(existing.team_id)))
    ) {
      throw new ForbiddenError('The selected training must belong to the planning team');
    }
    return this.repo.upsertSlot(weeklyPlanningId, {
      jour: dto.jour,
      moment: dto.moment,
      training_id: dto.trainingId,
      description: dto.description,
    });
  }

  async listSlots(weeklyPlanningId: number) {
    const existing = await this.repo.findById(weeklyPlanningId);
    if (!existing) throw new NotFoundError('Weekly planning');
    return this.repo.listSlots(weeklyPlanningId);
  }
}
