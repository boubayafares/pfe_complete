import type { AccessTokenPayload } from '../utils/jwt.js';
import { query } from '../../config/database.js';
import { ForbiddenError, UnauthorizedError } from '../errors/AppError.js';
import { resolveTeamId } from './team-resolver.service.js';

async function isModerationSuspended(entityType: 'utilisateur' | 'equipe', entityId: number): Promise<boolean> {
  try {
    const result = await query(
      `SELECT 1 FROM public.moderation_suspension
       WHERE entite_type = $1 AND entite_id = $2
       LIMIT 1`,
      [entityType, entityId]
    );
    return (result.rowCount ?? 0) > 0;
  } catch (error) {
    // The administration service is optional in local/test deployments. If
    // its migration has never been installed, no suspension can exist yet.
    if ((error as { code?: string }).code === '42P01') return false;
    throw error;
  }
}

/** Revalidates mutable account/role/team state instead of trusting JWT claims. */
export async function validateAuthenticatedUser(payload: AccessTokenPayload): Promise<AccessTokenPayload> {
  const accountResult = await query<{ account_status: string; has_role: boolean }>(
    `SELECT u.account_status,
            EXISTS (
              SELECT 1 FROM user_roles ur
              INNER JOIN roles r ON r.id = ur.role_id
              WHERE ur.user_id = u.id AND r.name = $2
            ) AS has_role
     FROM users u
     WHERE u.id = $1
     LIMIT 1`,
    [payload.sub, payload.role]
  );
  const account = accountResult.rows[0];
  if (!account || account.account_status !== 'ACTIVE' || !account.has_role) {
    throw new UnauthorizedError('Account is not active');
  }
  if (await isModerationSuspended('utilisateur', payload.sub)) {
    throw new ForbiddenError('Account is suspended');
  }

  const teamId = await resolveTeamId(payload);
  if (teamId && await isModerationSuspended('equipe', Number(teamId))) {
    throw new ForbiddenError('Team is suspended');
  }

  return {
    sub: Number(payload.sub),
    role: payload.role,
    ...(teamId && { teamId: Number(teamId) }),
  };
}
