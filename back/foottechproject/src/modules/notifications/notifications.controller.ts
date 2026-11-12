import type{ Request, Response } from 'express';
import { NotificationsService } from './notifications.service.js';
import { AuthRepository } from '../auth/auth.repository.js';
import { sendSuccess, sendCreated } from '../../shared/responses/ApiResponse.js';
import { UnauthorizedError } from '../../shared/errors/AppError.js';

export class NotificationsController {
  private readonly service = new NotificationsService();
  private readonly authRepo = new AuthRepository();

  private async resolveTeamId(req: Request): Promise<number> {
    if (!req.user) throw new UnauthorizedError();
    const teamId = await this.authRepo.getTeamIdForUser(req.user.sub, req.user.role, req.user.teamId);
    if (!teamId) throw new UnauthorizedError('No team associated with this account yet');
    return teamId;
  }

  listMine = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    sendSuccess(res, await this.service.listForUser(req.user.sub));
  };

  create = async (req: Request, res: Response): Promise<void> => {
    const teamId = await this.resolveTeamId(req);
    sendCreated(res, await this.service.create(teamId, req.body), 'Notification sent');
  };

  broadcast = async (req: Request, res: Response): Promise<void> => {
    const teamId = await this.resolveTeamId(req);
    sendCreated(res, await this.service.broadcastToTeam({ ...req.body, teamId }), 'Notification broadcast to team');
  };

  sendConvocation = async (req: Request, res: Response): Promise<void> => {
    const teamId = await this.resolveTeamId(req);
    sendCreated(res, await this.service.sendConvocation({ ...req.body, teamId }), 'Convocation prepared and sent');
  };

  markAsRead = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    await this.service.markAsRead(Number(req.params.id), req.user.sub);
    sendSuccess(res, null, 'Marked as read');
  };

  markAllAsRead = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    await this.service.markAllAsRead(req.user.sub);
    sendSuccess(res, null, 'All notifications marked as read');
  };

  registerPushToken = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    await this.service.registerPushToken(req.user.sub, req.body.token, req.body.platform);
    sendSuccess(res, null, 'Push token registered');
  };
}
