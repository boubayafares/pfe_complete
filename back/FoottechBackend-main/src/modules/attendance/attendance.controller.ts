import type{ Request, Response } from 'express';
import { AttendanceService } from './attendance.service.js';
import { sendSuccess, sendCreated } from '../../shared/responses/ApiResponse.js';

export class AttendanceController {
  private readonly service = new AttendanceService();

  mark = async (req: Request, res: Response): Promise<void> => {
    sendCreated(res, await this.service.mark(Number(req.params.id), req.body), 'Attendance marked');
  };

  bulkMark = async (req: Request, res: Response): Promise<void> => {
    sendCreated(res, await this.service.bulkMark(Number(req.params.id), req.body.entries), 'Attendance marked for all entries');
  };

  listByTraining = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.listByTraining(Number(req.params.id)));
  };

  listByPlayer = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.listByPlayer(Number(req.params.playerId)));
  };
}
