import type{ Request, Response } from 'express';
import { ExerciseProposalsService } from './exercise-proposals.service.js';
import { AuthRepository } from '../auth/auth.repository.js';
import { sendSuccess, sendCreated } from '../../shared/responses/ApiResponse.js';
import { UnauthorizedError } from '../../shared/errors/AppError.js';

export class ExerciseProposalsController {
  private readonly service = new ExerciseProposalsService();
  private readonly authRepo = new AuthRepository();

  private async resolveTeamId(req: Request): Promise<number> {
    if (!req.user) throw new UnauthorizedError();
    const teamId = await this.authRepo.getTeamIdForUser(req.user.sub, req.user.role);
    if (!teamId) throw new UnauthorizedError('No team associated with this account yet');
    return teamId;
  }

  list = async (req: Request, res: Response): Promise<void> => {
    const filters = {
      ...(req.query.trainingId && { trainingId: Number(req.query.trainingId) }),
      ...(req.query.status && { status: req.query.status as string }),
      ...(req.query.proposedBy && { proposedBy: Number(req.query.proposedBy) }),
    };
    sendSuccess(res, await this.service.list(filters));
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.getById(Number(req.params.id)));
  };

  create = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    sendCreated(res, await this.service.create(req.user.sub, req.body), 'Proposal submitted for review');
  };

  review = async (req: Request, res: Response): Promise<void> => {
    const teamId = await this.resolveTeamId(req);
    sendSuccess(res, await this.service.review(Number(req.params.id), req.user!.sub, teamId, req.body), 'Proposal reviewed');
  };
}
