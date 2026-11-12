import type{ Request, Response } from 'express';
import { UsersService } from './users.service.js';
import { sendSuccess } from '../../shared/responses/ApiResponse.js';
import { BadRequestError } from '../../shared/errors/AppError.js';

export class UsersController {
  private readonly service = new UsersService();

  getById = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.getById(Number(req.params.id)));
  };

  update = async (req: Request, res: Response): Promise<void> => {
    sendSuccess(res, await this.service.update(Number(req.params.id), req.body), 'User updated');
  };

  uploadAvatar = async (req: Request, res: Response): Promise<void> => {
    if (!req.file) throw new BadRequestError('No file uploaded (expected multipart field "avatar")');
    const publicUrl = `/uploads/${req.file.filename}`;
    sendSuccess(res, await this.service.updateAvatar(Number(req.params.id), publicUrl), 'Avatar updated');
  };
}
