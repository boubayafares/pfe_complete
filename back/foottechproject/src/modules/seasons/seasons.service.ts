import { SeasonsRepository } from './seasons.repository.js';
import type{ CreateSeasonDto, UpdateSeasonDto } from './seasons.dto.js';
import { BadRequestError, ConflictError, ForbiddenError, NotFoundError } from '../../shared/errors/AppError.js';

export class SeasonsService {
  private readonly repo = new SeasonsRepository();

  async list(teamId: number) {
    return this.repo.findAccessible(teamId);
  }

  async getById(id: number, teamId: number) {
    const season = await this.repo.findAccessibleById(id, teamId);
    if (!season) throw new NotFoundError('Season');
    return season;
  }

  async create(dto: CreateSeasonDto, teamId: number) {
    const existing = await this.repo.findByName(dto.name, teamId);
    if (existing) throw new ConflictError('A season with this name already exists');
    const season = await this.repo.create({
      team_id: teamId,
      name: dto.name,
      start_date: dto.startDate,
      end_date: dto.endDate,
      is_current: dto.isCurrent ?? false,
    });
    if (dto.isCurrent) return (await this.repo.setCurrent(season.id, teamId)) ?? season;
    return season;
  }

  async update(id: number, dto: UpdateSeasonDto, teamId: number) {
    const accessible = await this.repo.findAccessibleById(id, teamId);
    if (!accessible) throw new NotFoundError('Season');
    const existing = await this.repo.findOwnedById(id, teamId);
    if (!existing) throw new ForbiddenError('Legacy shared seasons are read-only');
    const startDate = new Date(dto.startDate ?? existing.start_date);
    const endDate = new Date(dto.endDate ?? existing.end_date);
    if (endDate <= startDate) throw new BadRequestError('endDate must be after startDate');
    if (dto.name !== undefined) {
      const nameTaken = await this.repo.findByName(dto.name, teamId);
      if (nameTaken && nameTaken.id !== id) throw new ConflictError('A season with this name already exists');
    }
    const payload: Record<string, unknown> = {};
    if (dto.name !== undefined) payload.name = dto.name;
    if (dto.startDate !== undefined) payload.start_date = dto.startDate;
    if (dto.endDate !== undefined) payload.end_date = dto.endDate;
    if (dto.isCurrent === false) payload.is_current = false;

    const updated = await this.repo.update(id, payload);
    if (dto.isCurrent !== undefined && dto.isCurrent) {
      return (await this.repo.setCurrent(id, teamId)) ?? updated;
    }
    return updated;
  }

  async remove(id: number, teamId: number) {
    const accessible = await this.repo.findAccessibleById(id, teamId);
    if (!accessible) throw new NotFoundError('Season');
    const owned = await this.repo.findOwnedById(id, teamId);
    if (!owned) throw new ForbiddenError('Legacy shared seasons are read-only');
    const deleted = await this.repo.delete(id);
    if (!deleted) throw new NotFoundError('Season');
  }
}
