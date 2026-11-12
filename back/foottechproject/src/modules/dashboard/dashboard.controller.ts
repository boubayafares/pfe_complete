import type{ Request, Response } from 'express';
import { DashboardService } from './dashboard.service.js';
import { AuthRepository } from '../auth/auth.repository.js';
import { sendSuccess } from '../../shared/responses/ApiResponse.js';
import { UnauthorizedError } from '../../shared/errors/AppError.js';

export class DashboardController {
  private readonly service = new DashboardService();
  private readonly authRepo = new AuthRepository();

  getMyDashboard = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    const teamId = await this.authRepo.getTeamIdForUser(req.user.sub, req.user.role, req.user.teamId);
    const dashboard = await this.service.getDashboard(req.user.sub, req.user.role, teamId);
    sendSuccess(res, dashboard);
  };

  getSeasonBilan = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    const userTeamId = await this.authRepo.getTeamIdForUser(req.user.sub, req.user.role, req.user.teamId);
    if (!userTeamId) throw new UnauthorizedError('No team associated with this account yet');
    const seasonId = req.query.seasonId ? Number(req.query.seasonId) : undefined;
    sendSuccess(res, await this.service.getSeasonBilan(userTeamId, seasonId));
  };
}
