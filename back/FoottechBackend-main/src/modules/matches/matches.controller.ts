import type{ Request, Response } from 'express';
import { MatchesService } from './matches.service.js';
import { AuthRepository } from '../auth/auth.repository.js';
import { sendSuccess, sendCreated, sendNoContent } from '../../shared/responses/ApiResponse.js';
import { UnauthorizedError } from '../../shared/errors/AppError.js';
import { emitMatchUpdate } from '../../socket/socket.js';

export class MatchesController {
  private readonly service = new MatchesService();
  private readonly authRepo = new AuthRepository();

  private async resolveTeamId(req: Request): Promise<number> {
    if (!req.user) throw new UnauthorizedError();
    const teamId = await this.authRepo.getTeamIdForUser(req.user.sub, req.user.role);
    if (!teamId) throw new UnauthorizedError('No team associated with this account yet');
    return teamId;
  }

  list = async (req: Request, res: Response): Promise<void> => {
    let teamId: number | undefined;
    if (req.user?.role === 'COACH' || req.user?.role === 'ADJOINT') {
      const t = await this.authRepo.getTeamIdForUser(req.user.sub, req.user.role);
      teamId = t ?? undefined;
    }
    const filters = {
      ...(teamId !== undefined && { teamId }),
      ...(req.query.seasonId && { seasonId: Number(req.query.seasonId) }),
      ...(req.query.status && { status: req.query.status as string }),
    };
    sendSuccess(res, await this.service.list(filters));
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.getById(Number(req.params.id)));
  };

  create = async (req: Request, res: Response): Promise<void> => {
    const teamId = await this.resolveTeamId(req);
    sendCreated(res, await this.service.create(req.body, teamId), 'Match created');
  };

  updateStatus = async (req: Request, res: Response): Promise<void> => {
    const matchId = Number(req.params.id);
    const match = await this.service.updateStatus(matchId, req.body.matchStatus);
    emitMatchUpdate(matchId, { type: 'STATUS', match });
    sendSuccess(res, match, 'Match status updated');
  };

  remove = async (req: Request, res: Response): Promise<void> => {
    await this.service.remove(Number(req.params.id));
    sendNoContent(res);
  };

  setLineup = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    const matchId = Number(req.params.id);
    const lineup = await this.service.setLineup(matchId, req.body, req.user.sub);
    emitMatchUpdate(matchId, { type: 'LINEUP', lineup });
    sendSuccess(res, lineup, 'Lineup saved');
  };

  getLineup = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.getLineup(Number(req.params.id)));
  };

  generateRecommendations = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.generateRecommendations(Number(req.params.id), req.body.playerIds), 'AI recommendations generated');
  };

  getRecommendations = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.getRecommendations(Number(req.params.id)));
  };

  createEvent = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    const matchId = Number(req.params.id);
    const event = await this.service.createEvent(matchId, req.body, req.user.sub);
    emitMatchUpdate(matchId, { type: 'EVENT', event });
    sendCreated(res, event, 'Event recorded');
  };

  listEvents = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.listEvents(Number(req.params.id)));
  };

  upsertPlayerStat = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.upsertPlayerStat(Number(req.params.id), req.body), 'Player stat saved');
  };

  listPlayerStats = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.listPlayerStats(Number(req.params.id)));
  };

  upsertEvaluation = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    sendSuccess(res, await this.service.upsertEvaluation(Number(req.params.id), req.user.sub, req.body), 'Evaluation saved');
  };

  listEvaluations = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.listEvaluations(Number(req.params.id)));
  };

  saveReport = async (req: Request, res: Response): Promise<void> => {
    sendCreated(res, await this.service.saveReport(Number(req.params.id), req.body.pdfUrl), 'Report saved');
  };

  generateReport = async (req: Request, res: Response): Promise<void> => {
    sendCreated(res, await this.service.generateReport(Number(req.params.id)), 'Report generated');
  };

  getReport = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.getReport(Number(req.params.id)));
  };
}
