import type{ Request, Response } from 'express';
import { PlayersService } from './players.service.js';
import { sendSuccess, sendCreated } from '../../shared/responses/ApiResponse.js';
import { UnauthorizedError } from '../../shared/errors/AppError.js';
import { parsePagination, buildPaginationMeta } from '../../shared/utils/pagination.js';

export class PlayersController {
  private readonly service = new PlayersService();

  list = async (req: Request, res: Response): Promise<void> => {
    const pagination = parsePagination(req.query);
    const filters: { posteP?: string; search?: string } = {
      posteP: req.query.posteP as string ,
      search: req.query.search as string ,
    };
    if (!req.user) throw new UnauthorizedError();
    const { rows, total } = await this.service.list(filters, pagination, req.user);
    sendSuccess(res, rows, undefined, 200, buildPaginationMeta(pagination.page, pagination.limit, total));
  };

  getProfile = async (req: Request, res: Response): Promise<void> => {
    const profile = await this.service.getProfile(Number(req.params.id));
    sendSuccess(res, profile);
  };

  create = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    const profile = await this.service.create(req.body, req.user);
    sendCreated(res, profile, 'Player created — send them the phone activation code to log in');
  };

  update = async (req: Request, res: Response): Promise<void> => {
    const profile = await this.service.update(Number(req.params.id), req.body);
    sendSuccess(res, profile, 'Player updated');
  };

  // --- Guardians ---

  upsertGuardian = async (req: Request, res: Response): Promise<void> => {
    const guardian = await this.service.upsertGuardian(Number(req.params.id), req.body);
    sendSuccess(res, guardian, 'Guardian saved');
  };

  listGuardians = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.listGuardians(Number(req.params.id)));
  };

  // --- Address ---

  upsertAddress = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.upsertAddress(Number(req.params.id), req.body), 'Address saved');
  };

  getAddress = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.getAddress(Number(req.params.id)));
  };

  // --- School info ---

  upsertSchoolInfo = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.upsertSchoolInfo(Number(req.params.id), req.body), 'School info saved');
  };

  getSchoolInfo = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.getSchoolInfo(Number(req.params.id)));
  };

  // --- Season profile ---

  upsertSeasonProfile = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.upsertSeasonProfile(Number(req.params.id), req.body), 'Season profile saved');
  };

  listSeasonProfiles = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.listSeasonProfiles(Number(req.params.id)));
  };

  // --- Injuries ---

  createInjury = async (req: Request, res: Response): Promise<void> => {
    const injury = await this.service.createInjury(Number(req.params.id), req.body);
    sendCreated(res, injury, 'Injury recorded');
  };

  updateInjury = async (req: Request, res: Response): Promise<void> => {
    const injury = await this.service.updateInjury(Number(req.params.id), Number(req.params.injuryId), req.body);
    sendSuccess(res, injury, 'Injury updated');
  };

  listInjuries = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.listInjuries(Number(req.params.id)));
  };

  deleteInjury = async (req: Request, res: Response): Promise<void> => {
    await this.service.deleteInjury(Number(req.params.id), Number(req.params.injuryId));
    sendSuccess(res, null, 'Injury deleted');
  };
}
