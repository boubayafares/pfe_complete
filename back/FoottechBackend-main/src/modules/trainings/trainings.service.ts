import { TrainingsRepository } from './trainings.repository.js';
import type{
  CreateTrainingDto,
  UpdateTrainingDto,
  UpsertTrainingSheetDto,
  CreateSituationDto,
  UpdateSituationDto,
  SaveTacticalDrawingDto,
} from './trainings.dto.js';
import { NotFoundError, ConflictError, ForbiddenError } from '../../shared/errors/AppError.js';

export class TrainingsService {
  private readonly repo = new TrainingsRepository();

  async list(teamId?: number, from?: Date, to?: Date) {
    return this.repo.findWithFilters(teamId, from, to);
  }

  async getById(id: number) {
    const training = await this.repo.findById(id);
    if (!training) throw new NotFoundError('Training');
    return training;
  }

  async create(dto: CreateTrainingDto, createdBy: number, teamId?: number) {
    if (!teamId) throw new ForbiddenError('User is not assigned to a team');
    try {
      return await this.repo.create({
        team_id: teamId,
        date: dto.date,
        start_time: dto.startTime,
        end_time: dto.endTime,
        location: dto.location ?? null,
        created_by: createdBy,
      });
    } catch (error) {
      const pgError = error as { code?: string };
      if (pgError.code === '23505') throw new ConflictError('A training already exists for this team at that date/time');
      throw error;
    }
  }

  async update(id: number, dto: UpdateTrainingDto) {
    const existing = await this.repo.findById(id);
    if (!existing) throw new NotFoundError('Training');
    const payload: Record<string, unknown> = {};
    if (dto.date !== undefined) payload.date = dto.date;
    if (dto.startTime !== undefined) payload.start_time = dto.startTime;
    if (dto.endTime !== undefined) payload.end_time = dto.endTime;
    if (dto.location !== undefined) payload.location = dto.location;
    if (dto.status !== undefined) payload.status = dto.status;
    return this.repo.update(id, payload);
  }

  async remove(id: number) {
    const deleted = await this.repo.delete(id);
    if (!deleted) throw new NotFoundError('Training');
  }

  private async assertTrainingExists(id: number) {
    const training = await this.repo.findById(id);
    if (!training) throw new NotFoundError('Training');
  }

  // --- Sheet ---

  async upsertSheet(trainingId: number, dto: UpsertTrainingSheetDto, createdBy: number) {
    await this.assertTrainingExists(trainingId);
    return this.repo.upsertSheet(trainingId, { objectifs: dto.objectifs, effectif: dto.effectif, created_by: createdBy });
  }

  async getSheet(trainingId: number) {
    await this.assertTrainingExists(trainingId);
    const sheet = await this.repo.findSheetByTrainingId(trainingId);
    if (!sheet) throw new NotFoundError('Training sheet');
    return sheet;
  }

  private async assertSheetExists(trainingId: number) {
    const sheet = await this.repo.findSheetByTrainingId(trainingId);
    if (!sheet) throw new NotFoundError('Training sheet — create it first via PUT /trainings/:id/sheet');
    return sheet;
  }

  private async assertSituationInTraining(situationId: number, trainingId: number) {
    const situation = await this.repo.findSituationById(situationId);
    if (!situation) throw new NotFoundError('Situation');
    const sheet = await this.repo.findSheetByTrainingId(trainingId);
    if (!sheet || situation.training_sheet_id !== sheet.id) {
      throw new NotFoundError('Situation');
    }
  }

  // --- Situations ---

  async createSituation(trainingId: number, dto: CreateSituationDto) {
    const sheet = await this.assertSheetExists(trainingId);
    const existing = await this.repo.listSituations(sheet.id);
    return this.repo.createSituation(sheet.id, {
      ordre: dto.ordre ?? existing.length + 1,
      titre: dto.titre,
      description: dto.description,
      duree_travail: dto.dureeTravail,
      duree_recuperation: dto.dureeRecuperation,
      duree_minutes: dto.dureeMinutes,
      criteres_reussite: dto.criteresReussite,
    });
  }

  async updateSituation(trainingId: number, situationId: number, dto: UpdateSituationDto) {
    await this.assertSituationInTraining(situationId, trainingId);
    const payload: Record<string, unknown> = {};
    if (dto.ordre !== undefined) payload.ordre = dto.ordre;
    if (dto.titre !== undefined) payload.titre = dto.titre;
    if (dto.description !== undefined) payload.description = dto.description;
    if (dto.dureeTravail !== undefined) payload.duree_travail = dto.dureeTravail;
    if (dto.dureeRecuperation !== undefined) payload.duree_recuperation = dto.dureeRecuperation;
    if (dto.dureeMinutes !== undefined) payload.duree_minutes = dto.dureeMinutes;
    if (dto.criteresReussite !== undefined) payload.criteres_reussite = dto.criteresReussite;
    const updated = await this.repo.updateSituation(situationId, payload);
    if (!updated) throw new NotFoundError('Situation');
    return updated;
  }

  async listSituations(trainingId: number) {
    const sheet = await this.assertSheetExists(trainingId);
    return this.repo.listSituations(sheet.id);
  }

  async deleteSituation(trainingId: number, situationId: number) {
    await this.assertSituationInTraining(situationId, trainingId);
    const deleted = await this.repo.deleteSituation(situationId);
    if (!deleted) throw new NotFoundError('Situation');
  }

  // --- Tactical drawing ---

  async saveDrawing(trainingId: number, situationId: number, dto: SaveTacticalDrawingDto, createdBy: number) {
    await this.assertSituationInTraining(situationId, trainingId);
    return this.repo.saveDrawingForSituation(situationId, dto.canvasData, createdBy);
  }

  async getLatestDrawing(trainingId: number, situationId: number) {
    await this.assertSituationInTraining(situationId, trainingId);
    return this.repo.findLatestDrawingForSituation(situationId);
  }
}
