import { SeasonsRepository } from './seasons.repository.js';
import type{ CreateSeasonDto, UpdateSeasonDto } from './seasons.dto.js';
import { ConflictError, NotFoundError } from '../../shared/errors/AppError.js';

export class SeasonsService {
  private readonly repo = new SeasonsRepository();

  async list() {
    return this.repo.findAll();
  }

  async getById(id: number) {
    const season = await this.repo.findById(id);
    if (!season) throw new NotFoundError('Season');
    return season;
  }

  async create(dto: CreateSeasonDto) {
    const existing = await this.repo.findByName(dto.name);
    if (existing) throw new ConflictError('A season with this name already exists');
    const season = await this.repo.create({
      name: dto.name,
      start_date: dto.startDate,
      end_date: dto.endDate,
      is_current: dto.isCurrent ?? false,
    });
    if (dto.isCurrent) return (await this.repo.setCurrent(season.id)) ?? season;
    return season;
  }

  async update(id: number, dto: UpdateSeasonDto) {
    const existing = await this.repo.findById(id);
    if (!existing) throw new NotFoundError('Season');
    if (dto.name !== undefined) {
      const nameTaken = await this.repo.findByName(dto.name);
      if (nameTaken && nameTaken.id !== id) throw new ConflictError('A season with this name already exists');
    }
    const payload: Record<string, unknown> = {};
    if (dto.name !== undefined) payload.name = dto.name;
    if (dto.startDate !== undefined) payload.start_date = dto.startDate;
    if (dto.endDate !== undefined) payload.end_date = dto.endDate;

    const updated = await this.repo.update(id, payload);
    if (dto.isCurrent !== undefined && dto.isCurrent) {
      return (await this.repo.setCurrent(id)) ?? updated;
    }
    return updated;
  }

  async remove(id: number) {
    const deleted = await this.repo.delete(id);
    if (!deleted) throw new NotFoundError('Season');
  }
}
