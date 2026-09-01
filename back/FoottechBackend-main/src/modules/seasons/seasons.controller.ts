import type{ Request, Response } from 'express';
import { SeasonsService } from './seasons.service.js';
import { sendSuccess, sendCreated, sendNoContent } from '../../shared/responses/ApiResponse.js';

export class SeasonsController {
  private readonly service = new SeasonsService();

  list = async (_req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.list());
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.getById(Number(req.params.id)));
  };

  create = async (req: Request, res: Response): Promise<void> => {
    sendCreated(res, await this.service.create(req.body));
  };

  update = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.update(Number(req.params.id), req.body), 'Season updated');
  };

  remove = async (req: Request, res: Response): Promise<void> => {
    await this.service.remove(Number(req.params.id));
    sendNoContent(res);
  };
}
