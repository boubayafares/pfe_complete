import { query } from '../../config/database.js';
import { BaseRepository } from '../../shared/database/BaseRepository.js';
import type{ SeasonRecord } from './seasons.interface.js';

export class SeasonsRepository extends BaseRepository<SeasonRecord> {
  constructor() {
    super('seasons');
  }

  /** Season names are globally unique (schema constraint) — lookup for conflict checks. */
  async findByName(name: string): Promise<SeasonRecord | null> {
    return this.findOneBy('name', name);
  }

  /** Only one season can be "current" at a time. */
  async setCurrent(id: number): Promise<SeasonRecord | null> {
    await query('UPDATE seasons SET is_current = FALSE WHERE is_current = TRUE');
    return this.update(id, { is_current: true });
  }
}
