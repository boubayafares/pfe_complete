import type{ Request, Response } from 'express';
import { TrainingsService } from './trainings.service.js';
import { AuthRepository } from '../auth/auth.repository.js';
import { sendSuccess, sendCreated, sendNoContent } from '../../shared/responses/ApiResponse.js';
import { UnauthorizedError } from '../../shared/errors/AppError.js';

export class TrainingsController {
  private readonly service = new TrainingsService();
  private readonly authRepo = new AuthRepository();

  private async resolveTeamId(req: Request): Promise<number> {
    if (!req.user) throw new UnauthorizedError();
    const teamId = await this.authRepo.getTeamIdForUser(req.user.sub, req.user.role);
    if (!teamId) throw new UnauthorizedError('No team associated with this account yet');
    return teamId;
  }

  list = async (req: Request, res: Response): Promise<void> => {
    const teamId = req.user && (req.user.role === 'COACH' || req.user.role === 'ADJOINT')
      ? (await this.authRepo.getTeamIdForUser(req.user.sub, req.user.role)) ?? undefined
      : undefined;
    const from = req.query.from ? new Date(req.query.from as string) : undefined;
    const to = req.query.to ? new Date(req.query.to as string) : undefined;
    sendSuccess(res, await this.service.list(teamId, from, to));
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.getById(Number(req.params.id)));
  };

  create = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    const teamId = await this.resolveTeamId(req);
    sendCreated(res, await this.service.create(req.body, req.user.sub, teamId), 'Training created');
  };

  update = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.update(Number(req.params.id), req.body), 'Training updated');
  };

  remove = async (req: Request, res: Response): Promise<void> => {
    await this.service.remove(Number(req.params.id));
    sendNoContent(res);
  };

  upsertSheet = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    sendSuccess(res, await this.service.upsertSheet(Number(req.params.id), req.body, req.user.sub), 'Sheet saved');
  };

  getSheet = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.getSheet(Number(req.params.id)));
  };

  createSituation = async (req: Request, res: Response): Promise<void> => {
    sendCreated(res, await this.service.createSituation(Number(req.params.id), req.body), 'Situation added');
  };

  updateSituation = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.updateSituation(Number(req.params.id), Number(req.params.situationId), req.body), 'Situation updated');
  };

  listSituations = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.listSituations(Number(req.params.id)));
  };

  deleteSituation = async (req: Request, res: Response): Promise<void> => {
    await this.service.deleteSituation(Number(req.params.id), Number(req.params.situationId));
    sendNoContent(res);
  };

  saveDrawing = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    sendCreated(res, await this.service.saveDrawing(Number(req.params.id), Number(req.params.situationId), req.body, req.user.sub), 'Drawing saved');
  };

  getDrawing = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.getLatestDrawing(Number(req.params.id), Number(req.params.situationId)));
  };
}
