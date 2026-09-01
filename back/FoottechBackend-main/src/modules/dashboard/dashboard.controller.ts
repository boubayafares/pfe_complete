import type{ Request, Response } from 'express';
import { DashboardService } from './dashboard.service.js';
import { AuthRepository } from '../auth/auth.repository.js';
import { sendSuccess } from '../../shared/responses/ApiResponse.js';
import { UnauthorizedError, ForbiddenError } from '../../shared/errors/AppError.js';

export class DashboardController {
  private readonly service = new DashboardService();
  private readonly authRepo = new AuthRepository();

  getMyDashboard = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    // Resolved fresh rather than trusting req.user.teamId: a coach who
    // creates their team after the token was issued would otherwise see a
    // stale null until their next refresh.
    const teamId = await this.authRepo.getTeamIdForUser(req.user.sub, req.user.role);
    const dashboard = await this.service.getDashboard(req.user.sub, req.user.role, teamId);
    sendSuccess(res, dashboard);
  };

  getSeasonBilan = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    // Resolve the user's team fresh rather than trusting the token claim, and
    // reject requests for a different team to prevent cross-team data leaks.
    const userTeamId = await this.authRepo.getTeamIdForUser(req.user.sub, req.user.role);
    if (!userTeamId) throw new UnauthorizedError('No team associated with this account yet');
    const requestedTeamId = Number(req.query.teamId);
    // userTeamId comes from the DB (bigint -> string) while requestedTeamId is
    // coerced above; compare numerically.
    if (requestedTeamId !== Number(userTeamId)) {
      throw new ForbiddenError('You do not have access to this team');
    }
    const seasonId = req.query.seasonId ? Number(req.query.seasonId) : undefined;
    sendSuccess(res, await this.service.getSeasonBilan(userTeamId, seasonId));
  };
}
