import { AuthRepository } from '../../modules/auth/auth.repository.js';
import type { AccessTokenPayload } from '../utils/jwt.js';
import { ForbiddenError, UnauthorizedError } from '../errors/AppError.js';

const authRepo = new AuthRepository();

/**
 * Resolves a user's current team id straight from the database rather than
 * trusting the (potentially stale) `teamId` claim embedded in the JWT at
 * login/refresh time. The JWT claim can be `null` or outdated — for example
 * a Coach who registers and immediately creates their first team still holds
 * an access token that says `teamId: undefined` until the token is refreshed.
 * Re-querying keeps authorization correct without forcing every client to
 * proactively refresh tokens after every team mutation.
 */
export async function resolveTeamId(user: AccessTokenPayload): Promise<number | null> {
  return authRepo.getTeamIdForUser(user.sub, user.role);
}

/** Like [resolveTeamId] but throws `ForbiddenError` when no team is found. */
export async function requireTeamId(user: AccessTokenPayload): Promise<number> {
  if (!user) throw new UnauthorizedError('Authentication required');
  const teamId = await resolveTeamId(user);
  if (!teamId) throw new ForbiddenError('User is not assigned to a team');
  return teamId;
}
