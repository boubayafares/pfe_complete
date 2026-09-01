import type{ Request, Response } from 'express';
import { CalendarEventsService } from './calendar-events.service.js';
import { AuthRepository } from '../auth/auth.repository.js';
import { sendSuccess, sendCreated, sendNoContent } from '../../shared/responses/ApiResponse.js';
import { UnauthorizedError, ForbiddenError } from '../../shared/errors/AppError.js';

export class CalendarEventsController {
  private readonly service = new CalendarEventsService();
  private readonly authRepo = new AuthRepository();

  private async resolveTeamId(req: Request): Promise<number> {
    if (!req.user) throw new UnauthorizedError();
    const teamId = await this.authRepo.getTeamIdForUser(req.user.sub, req.user.role);
    if (!teamId) throw new ForbiddenError('User is not assigned to a team');
    return Number(teamId);
  }

  list = async (req: Request, res: Response): Promise<void> => {
    const teamId = await this.resolveTeamId(req);
    const from = req.query.from ? new Date(req.query.from as string) : undefined;
    const to = req.query.to ? new Date(req.query.to as string) : undefined;
    sendSuccess(res, await this.service.list(teamId, req.user!.role, from, to));
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    sendSuccess(res, await this.service.getById(Number(req.params.id), req.user.role));
  };

  create = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    const teamId = await this.resolveTeamId(req);
    sendCreated(res, await this.service.create(req.body, teamId, Number(req.user.sub)), 'Calendar event created');
  };

  update = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.update(Number(req.params.id), req.body), 'Calendar event updated');
  };

  remove = async (req: Request, res: Response): Promise<void> => {
    await this.service.remove(Number(req.params.id));
    sendNoContent(res);
  };
}
