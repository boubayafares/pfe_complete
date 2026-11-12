export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: string;
}

export interface AuthenticatedUser {
  id: number;
  firstName: string;
  lastName: string;
  phone: string;
  email: string | null;
  role: 'COACH' | 'ADJOINT' | 'JOUEUR';
  accountStatus: string;
  teamId?: number | null;
}

export interface LoginResult {
  user: AuthenticatedUser;
  tokens: AuthTokens;
}

/**
 * A successful login for an account that still needs OTP confirmation
 * (e.g. a brand-new INACTIVE Coach). No tokens are issued — the client must
 * call the coach OTP verify flow to activate the account and get tokens.
 */
export interface LoginNeedsActivation {
  user: AuthenticatedUser;
  needsActivation: true;
}

export type LoginResponse = LoginResult | LoginNeedsActivation;
