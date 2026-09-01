import type{ Request, Response } from 'express';
import { AuthService } from './auth.service.js';
import { sendCreated, sendSuccess } from '../../shared/responses/ApiResponse.js';
import { UnauthorizedError } from '../../shared/errors/AppError.js';

export class AuthController {
  private readonly service = new AuthService();

  registerCoach = async (req: Request, res: Response): Promise<void> => {
    const result = await this.service.registerCoach(req.body);
    sendCreated(res, result, 'Coach account created');
  };

  login = async (req: Request, res: Response): Promise<void> => {
    const result = await this.service.login(req.body);
    sendSuccess(res, result, 'Login successful');
  };

  setAdjointPassword = async (req: Request, res: Response): Promise<void> => {
    await this.service.setAdjointPassword(req.body.userId, req.body.password);
    sendSuccess(res, null, 'Password set — account activated');
  };

  activateAdjointByPhone = async (req: Request, res: Response): Promise<void> => {
    await this.service.activateAdjointByPhone(req.body);
    sendSuccess(res, null, 'Password set — account activated');
  };

  requestPlayerOtp = async (req: Request, res: Response): Promise<void> => {
    await this.service.requestPlayerOtp(req.body);
    sendSuccess(res, null, 'Code sent');
  };

  verifyPlayerOtp = async (req: Request, res: Response): Promise<void> => {
    const result = await this.service.verifyPlayerOtp(req.body);
    sendSuccess(res, result, 'Login successful');
  };

  requestCoachOtp = async (req: Request, res: Response): Promise<void> => {
    await this.service.requestCoachOtp(req.body);
    sendSuccess(res, null, 'Code sent');
  };

  verifyCoachOtp = async (req: Request, res: Response): Promise<void> => {
    const result = await this.service.verifyCoachOtp(req.body);
    sendSuccess(res, result, 'Login successful');
  };

  refresh = async (req: Request, res: Response): Promise<void> => {
    const tokens = await this.service.refresh(req.body.refreshToken);
    sendSuccess(res, tokens, 'Token refreshed');
  };

  logout = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    await this.service.logout(req.user.sub);
    sendSuccess(res, null, 'Logged out successfully');
  };

  me = async (req: Request, res: Response): Promise<void> => {
    if (!req.user) throw new UnauthorizedError();
    const user = await this.service.me(req.user.sub, req.user.role);
    sendSuccess(res, user);
  };
}
