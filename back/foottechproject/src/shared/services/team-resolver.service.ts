import { AuthRepository } from '../../modules/auth/auth.repository.js';
import type { AccessTokenPayload } from '../utils/jwt.js';
import { ForbiddenError, UnauthorizedError } from '../errors/AppError.js';

const authRepo = new AuthRepository();

/**
 * Resolves the selected team from the signed JWT and revalidates that
 * membership against the database on every request. Without an explicit
 * selection (for example just after first-team creation), the repository
 * returns the user's deterministic default team.
 */
export async function resolveTeamId(user: AccessTokenPayload): Promise<number | null> {
  const teamId = await authRepo.getTeamIdForUser(user.sub, user.role, user.teamId);
  return teamId === null ? null : Number(teamId);
}

/** Like [resolveTeamId] but throws `ForbiddenError` when no team is found. */
export async function requireTeamId(user: AccessTokenPayload): Promise<number> {
  if (!user) throw new UnauthorizedError('Authentication required');
  const teamId = await resolveTeamId(user);
  if (!teamId) throw new ForbiddenError('User is not assigned to a team');
  return teamId;
}
