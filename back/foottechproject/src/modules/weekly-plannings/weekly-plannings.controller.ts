import type{ Request, Response } from 'express';
import { WeeklyPlanningsService } from './weekly-plannings.service.js';
import { AuthRepository } from '../auth/auth.repository.js';
import { sendSuccess, sendCreated, sendNoContent } from '../../shared/responses/ApiResponse.js';
import { UnauthorizedError } from '../../shared/errors/AppError.js';

export class WeeklyPlanningsController {
  private readonly service = new WeeklyPlanningsService();
  private readonly authRepo = new AuthRepository();

  private async resolveTeamId(req: Request): Promise<number> {
    if (!req.user) throw new UnauthorizedError();
    const teamId = await this.authRepo.getTeamIdForUser(req.user.sub, req.user.role, req.user.teamId);
    if (!teamId) throw new UnauthorizedError('No team associated with this account yet');
    return teamId;
  }

  list = async (req: Request, res: Response): Promise<void> => {
    const teamId = await this.resolveTeamId(req);
    const seasonId = req.query.seasonId ? Number(req.query.seasonId) : undefined;
    sendSuccess(res, await this.service.list(teamId, seasonId));
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.getById(Number(req.params.id)));
  };

  create = async (req: Request, res: Response): Promise<void> => {
    const teamId = await this.resolveTeamId(req);
    sendCreated(res, await this.service.create(req.body, teamId), 'Weekly planning created');
  };

  update = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.update(Number(req.params.id), req.body), 'Weekly planning updated');
  };

  remove = async (req: Request, res: Response): Promise<void> => {
    await this.service.remove(Number(req.params.id));
    sendNoContent(res);
  };

  upsertSlot = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.upsertSlot(Number(req.params.id), req.body), 'Slot saved');
  };

  listSlots = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.listSlots(Number(req.params.id)));
  };
}
