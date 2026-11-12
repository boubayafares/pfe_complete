import type{ Request, Response } from 'express';
import { SeasonsService } from './seasons.service.js';
import { sendSuccess, sendCreated, sendNoContent } from '../../shared/responses/ApiResponse.js';
import { requireTeamId } from '../../shared/services/team-resolver.service.js';
import { UnauthorizedError } from '../../shared/errors/AppError.js';

export class SeasonsController {
  private readonly service = new SeasonsService();

  private async teamId(req: Request): Promise<number> {
    if (!req.user) throw new UnauthorizedError('Authentication required');
    return requireTeamId(req.user);
  }

  list = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.list(await this.teamId(req)));
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.getById(Number(req.params.id), await this.teamId(req)));
  };

  create = async (req: Request, res: Response): Promise<void> => {
    sendCreated(res, await this.service.create(req.body, await this.teamId(req)));
  };

  update = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.update(Number(req.params.id), req.body, await this.teamId(req)), 'Season updated');
  };

  remove = async (req: Request, res: Response): Promise<void> => {
    await this.service.remove(Number(req.params.id), await this.teamId(req));
    sendNoContent(res);
  };
}
