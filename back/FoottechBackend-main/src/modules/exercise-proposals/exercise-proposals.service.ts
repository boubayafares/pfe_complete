import { ExerciseProposalsRepository } from './exercise-proposals.repository.js';
import type{ CreateProposalDto, ReviewProposalDto } from './exercise-proposals.dto.js';
import { NotFoundError, BadRequestError, ForbiddenError } from '../../shared/errors/AppError.js';
import { query } from '../../config/database.js';

export class ExerciseProposalsService {
  private readonly repo = new ExerciseProposalsRepository();

  async list(filters: { trainingId?: number; status?: string; proposedBy?: number }) {
    return this.repo.findWithFilters(filters);
  }

  async getById(id: number) {
    const proposal = await this.repo.findById(id);
    if (!proposal) throw new NotFoundError('Exercise proposal');
    return proposal;
  }

  async create(proposedBy: number, dto: CreateProposalDto) {
    return this.repo.create({
      training_id: dto.trainingId ?? null,
      proposed_by: proposedBy,
      titre: dto.titre,
      description: dto.description ?? null,
    });
  }

  async review(id: number, reviewedBy: number, teamId: number, dto: ReviewProposalDto) {
    const proposal = await this.repo.findById(id);
    if (!proposal) throw new NotFoundError('Exercise proposal');
    if (proposal.status !== 'PENDING') throw new BadRequestError('This proposal has already been reviewed');

    if (proposal.training_id !== null) {
      const result = await query<{ team_id: number }>(
        'SELECT team_id FROM trainings WHERE id = $1 LIMIT 1',
        [proposal.training_id]
      );
      const training = result.rows[0];
      if (!training || training.team_id !== teamId) {
        throw new ForbiddenError('You can only review proposals from your own team');
      }
    }

    return this.repo.review(id, dto.status, reviewedBy, dto.reviewComment);
  }
}
