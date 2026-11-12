import type{ Request, Response } from 'express';
import { TeamsService } from './teams.service.js';
import { sendSuccess, sendCreated, sendNoContent } from '../../shared/responses/ApiResponse.js';
import { parsePagination, buildPaginationMeta } from '../../shared/utils/pagination.js';
import { ForbiddenError, UnauthorizedError } from '../../shared/errors/AppError.js';

export class TeamsController {
  private readonly service = new TeamsService();

  list = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    const pagination = parsePagination(req.query);
    if (req.user.role !== 'COACH' && !req.user.teamId) {
      throw new ForbiddenError('User is not assigned to a team');
    }
    const filters = {
      ...(req.user.role === 'COACH' ? { coachId: req.user.sub } : { id: Number(req.user.teamId) }),
      category: req.query.category as string ,
      search: req.query.search as string ,
    };
    const { rows, total } = await this.service.list(filters, pagination);
    sendSuccess(res, rows, undefined, 200, buildPaginationMeta(pagination.page, pagination.limit, total));
  };

  getById = async (req: Request, res: Response): Promise<void> => {
    const team = await this.service.getById(Number(req.params.id));
    sendSuccess(res, team);
  };

  create = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    const team = await this.service.create(req.user.sub, req.body);
    sendCreated(res, team, 'Team created');
  };

  update = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    const team = await this.service.update(Number(req.params.id), req.user.sub, req.body);
    sendSuccess(res, team, 'Team updated');
  };

  remove = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    await this.service.remove(Number(req.params.id), req.user.sub);
    sendNoContent(res);
  };

  getStaff = async (req: Request, res: Response): Promise<void> => {
    const staff = await this.service.getStaff(Number(req.params.id));
    sendSuccess(res, staff);
  };

  addAdjoint = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    const staff = await this.service.addAdjoint(Number(req.params.id), req.user.sub, req.body);
    sendCreated(res, staff, 'Adjoint added — an activation SMS/email step is still needed');
  };

  removeAdjoint = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    await this.service.removeAdjoint(Number(req.params.id), req.user.sub, Number(req.params.adjointId));
    sendNoContent(res);
  };
}
