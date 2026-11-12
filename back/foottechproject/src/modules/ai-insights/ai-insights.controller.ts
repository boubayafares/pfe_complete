import type { Request, Response } from 'express';
import { sendSuccess } from '../../shared/responses/ApiResponse.js';
import { UnauthorizedError } from '../../shared/errors/AppError.js';
import { requireTeamId } from '../../shared/services/team-resolver.service.js';
import { AiInsightsService } from './ai-insights.service.js';

export class AiInsightsController {
  private readonly service = new AiInsightsService();

  playerTrend = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.getPlayerTrend(Number(req.params.id)));
  };

  teamClusters = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    const teamId = await requireTeamId(req.user);
    sendSuccess(res, await this.service.getTeamClusters(teamId, Number(req.query.nClusters ?? 3)));
  };

  analyzeTone = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.analyzeTone(req.body.comment));
  };

  expertProjectModel = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    const teamId = await requireTeamId(req.user);
    sendSuccess(res, await this.service.getExpertProjectModel(teamId));
  };
}
