import type { NextFunction, Request, Response } from 'express';
import { query } from '../config/database.js';
import { ForbiddenError, UnauthorizedError } from '../shared/errors/AppError.js';
import { resolveTeamId } from '../shared/services/team-resolver.service.js';

export async function requireTeamAccess(req: Request, _res: Response, next: NextFunction): Promise<void> {
  if (!req.user) throw new UnauthorizedError('Authentication required');
  // Re-resolve the team from the DB: the JWT `teamId` claim can be stale (e.g.
  // a Coach who just created their first team still holds a token free of a
  // teamId claim until it is refreshed).
  const teamId = await resolveTeamId(req.user);
  if (!teamId) throw new ForbiddenError('User is not assigned to a team');
  const targetTeamId = Number(req.params.id);
  const result = await query<{ id: number }>('SELECT id FROM teams WHERE id = $1 LIMIT 1', [targetTeamId]);
  if (!result.rows[0] || Number(result.rows[0].id) !== Number(teamId)) throw new ForbiddenError('You do not have access to this team');
  next();
}
