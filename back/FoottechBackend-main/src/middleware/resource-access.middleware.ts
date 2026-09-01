import type { NextFunction, Request, Response } from 'express';
import { query } from '../config/database.js';
import { ForbiddenError, UnauthorizedError } from '../shared/errors/AppError.js';
import { requireTeamId } from '../shared/services/team-resolver.service.js';

async function assertTeamUser(req: Request): Promise<{ teamId: number; role: string; sub: number }> {
  if (!req.user) throw new UnauthorizedError('Authentication required');
  // Re-resolve the team from the DB rather than trusting the stale JWT claim.
  const teamId = await requireTeamId(req.user);
  return { teamId, role: req.user.role, sub: req.user.sub };
}

export function requirePlayerAccess(param = 'id') {
  return async (req: Request, _res: Response, next: NextFunction): Promise<void> => {
    if (!req.user) throw new UnauthorizedError('Authentication required');
    const { role, sub } = req.user;
    const playerId = Number(req.params[param]);
    const result = await query<{ team_id: number | null }>('SELECT team_id FROM players WHERE id = $1 LIMIT 1', [playerId]);
    const player = result.rows[0];
    if (!player) throw new ForbiddenError('Access denied');
    if (role === 'JOUEUR') {
      if (Number(sub) !== playerId) throw new ForbiddenError('You can only access your own player profile');
      next();
      return;
    }
    const teamId = await requireTeamId(req.user);
    if (player.team_id !== teamId) {
      throw new ForbiddenError('You do not have access to this player');
    }
    next();
  };
}

export function requireTrainingAccess(param = 'id') {
  return async (req: Request, _res: Response, next: NextFunction): Promise<void> => {
    const { teamId } = await assertTeamUser(req);
    const id = Number(req.params[param]);
    const result = await query<{ team_id: number }>('SELECT team_id FROM trainings WHERE id = $1 LIMIT 1', [id]);
    if (!result.rows[0] || result.rows[0].team_id !== teamId) throw new ForbiddenError('You do not have access to this training');
    next();
  };
}

export function requireMatchAccess(param = 'id') {
  return async (req: Request, _res: Response, next: NextFunction): Promise<void> => {
    const { teamId } = await assertTeamUser(req);
    const id = Number(req.params[param]);
    const result = await query<{ team_id: number }>('SELECT team_id FROM matches WHERE id = $1 LIMIT 1', [id]);
    if (!result.rows[0] || result.rows[0].team_id !== teamId) throw new ForbiddenError('You do not have access to this match');
    next();
  };
}

export function requireWeeklyPlanningAccess(param = 'id') {
  return async (req: Request, _res: Response, next: NextFunction): Promise<void> => {
    const { teamId } = await assertTeamUser(req);
    const id = Number(req.params[param]);
    const result = await query<{ team_id: number }>('SELECT team_id FROM weekly_plannings WHERE id = $1 LIMIT 1', [id]);
    if (!result.rows[0] || result.rows[0].team_id !== teamId) throw new ForbiddenError('You do not have access to this weekly planning');
    next();
  };
}

export function requireCalendarEventAccess(param = 'id') {
  return async (req: Request, _res: Response, next: NextFunction): Promise<void> => {
    const { teamId } = await assertTeamUser(req);
    const id = Number(req.params[param]);
    const result = await query<{ team_id: number }>('SELECT team_id FROM calendar_events WHERE id = $1 LIMIT 1', [id]);
    if (!result.rows[0] || result.rows[0].team_id !== teamId) throw new ForbiddenError('You do not have access to this calendar event');
    next();
  };
}

