import crypto from 'crypto';
import { AuthRepository } from './auth.repository.js';
import type{ RegisterCoachDto, LoginDto, RequestPlayerOtpDto, VerifyPlayerOtpDto, ActivateAdjointByPhoneDto, RequestCoachOtpDto, VerifyCoachOtpDto } from './auth.dto.js';
import type{ AuthTokens, AuthenticatedUser, LoginResult, LoginResponse } from './auth.types.js';
import { hashPassword, comparePassword } from '../../shared/utils/bcrypt.js';
import { signAccessToken, signRefreshToken, verifyRefreshToken } from '../../shared/utils/jwt.js';
import { generateOtp, otpExpiryDate } from '../../shared/utils/otp.js';
import { sendOtp } from '../../shared/services/notification.service.js';
import { BadRequestError, ConflictError, NotFoundError, UnauthorizedError } from '../../shared/errors/AppError.js';
import { env } from '../../config/env.js';

function hashToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}

function msFromDuration(duration: string): number {
  const match = /^(\d+)([smhd])$/.exec(duration);
  if (!match) return 30 * 24 * 60 * 60 * 1000;
  const unitMs = { s: 1000, m: 60000, h: 3600000, d: 86400000 }[match[2]!] ?? 86400000;
  return parseInt(match[1]!, 10) * unitMs;
}

export class AuthService {
  private readonly repo = new AuthRepository();

  private async toAuthenticatedUser(userId: number, role: 'COACH' | 'ADJOINT' | 'JOUEUR'): Promise<AuthenticatedUser> {
    const user = await this.repo.findUserById(userId);
    if (!user) throw new NotFoundError('User');
    const teamId = await this.repo.getTeamIdForUser(userId, role);
    return {
      id: user.id,
      firstName: user.first_name,
      lastName: user.last_name,
      phone: user.phone,
      email: user.email,
      role,
      accountStatus: user.account_status,
      teamId,
    };
  }

  private async issueTokens(userId: number, role: 'COACH' | 'ADJOINT' | 'JOUEUR', teamId: number | null): Promise<AuthTokens> {
    const accessToken = signAccessToken({ sub: userId, role, ...(teamId && { teamId }) });
    const rawRefreshToken = crypto.randomBytes(48).toString('hex');
    const tokenHash = hashToken(rawRefreshToken);
    const expiresAt = new Date(Date.now() + msFromDuration(env.JWT_REFRESH_EXPIRES_IN));
    const stored = await this.repo.storeRefreshToken(userId, tokenHash, expiresAt);
    const refreshToken = signRefreshToken({ sub: userId, tokenId: stored.id });
    return { accessToken, refreshToken: `${refreshToken}.${rawRefreshToken}`, expiresIn: env.JWT_ACCESS_EXPIRES_IN };
  }

  // --- Coach: self-registration, email + password ------------------------

  async registerCoach(dto: RegisterCoachDto): Promise<LoginResult> {
    const existingEmail = await this.repo.findUserByEmail(dto.email);
    if (existingEmail) throw new ConflictError('An account with this email already exists');
    const existingPhone = await this.repo.findUserByPhone(dto.phone);
    if (existingPhone) throw new ConflictError('An account with this phone number already exists');

    const passwordHash = await hashPassword(dto.password);
    const user = await this.repo.createCoach({ ...dto, passwordHash });
    const tokens = await this.issueTokens(user.id, 'COACH', null);
    const authenticatedUser = await this.toAuthenticatedUser(user.id, 'COACH');
    return { user: authenticatedUser, tokens };
  }

  // --- Coach / Adjoint: email + password login ----------------------------

  async login(dto: LoginDto): Promise<LoginResponse> {
    const user = await this.repo.findUserByEmail(dto.email);
    if (!user || !user.password_hash) throw new UnauthorizedError('Invalid credentials');
    const ok = await comparePassword(dto.password, user.password_hash);
    if (!ok) throw new UnauthorizedError('Invalid credentials');
    if (user.account_status === 'BLOCKED') throw new UnauthorizedError('This account has been blocked');

    const role = await this.repo.getUserRole(user.id);
    if (role !== 'COACH' && role !== 'ADJOINT') {
      throw new UnauthorizedError('Use the phone/code login for player accounts');
    }

    // A freshly-registered coach (or a pending adjoint) must confirm via OTP
    // before they can use the app. Signal that instead of returning tokens or
    // an error, so the client can drive the activation flow.
    if (user.account_status === 'INACTIVE') {
      const authenticatedUser = await this.toAuthenticatedUser(user.id, role);
      return { user: authenticatedUser, needsActivation: true };
    }

    const teamId = await this.repo.getTeamIdForUser(user.id, role);
    const tokens = await this.issueTokens(user.id, role, teamId);
    const authenticatedUser = await this.toAuthenticatedUser(user.id, role);
    return { user: authenticatedUser, tokens };
  }

  // --- Adjoint: activation (coach creates the account, adjoint sets a password) --

  async setAdjointPassword(userId: number, password: string): Promise<void> {
    const user = await this.repo.findUserById(userId);
    if (!user) throw new NotFoundError('User');
    const role = await this.repo.getUserRole(userId);
    if (role !== 'ADJOINT') throw new BadRequestError('This account is not an Adjoint account');
    const passwordHash = await hashPassword(password);
    await this.repo.setPassword(userId, passwordHash);
    await this.repo.updateAccountStatus(userId, 'ACTIVE');
  }

  /**
   * Public helper so an Adjoint can activate their account on the device
   * (phone + code) without the Coach being signed in — mirrors the offline
   * prototype UX. The Coach still controls invalids via the /staff route.
   */
  async activateAdjointByPhone(dto: ActivateAdjointByPhoneDto): Promise<void> {
    const user = await this.repo.findUserByPhone(dto.phone);
    if (!user) throw new NotFoundError('Aucun compte adjoint avec ce telephone');
    const role = await this.repo.getUserRole(user.id);
    if (role !== 'ADJOINT') throw new BadRequestError('This account is not an Adjoint account');

    const activation = await this.repo.findLatestActivationCode(user.id);
    if (!activation || activation.used || activation.code !== dto.code) {
      throw new BadRequestError('Code invalide ou deja utilise');
    }
    if (activation.expires_at.getTime() < Date.now()) {
      throw new BadRequestError('Code expiré — demandez un nouveau code');
    }
    await this.repo.markActivationCodeUsed(activation.id);
    const passwordHash = await hashPassword(dto.password);
    await this.repo.setPassword(user.id, passwordHash);
    await this.repo.updateAccountStatus(user.id, 'ACTIVE');
  }

  // --- Joueur: phone + OTP (no password ever) -----------------------------

  async requestPlayerOtp(dto: RequestPlayerOtpDto): Promise<void> {
    const user = await this.repo.findUserByPhone(dto.phone);
    if (!user) throw new NotFoundError('No player account for this phone number');
    const role = await this.repo.getUserRole(user.id);
    if (role !== 'JOUEUR') throw new BadRequestError('Use email/password login for this account');

    const code = generateOtp();
    const channel = dto.channel ?? 'SMS';
    await this.repo.createActivationCode(user.id, code, channel, otpExpiryDate());
    await sendOtp(dto.phone, code, channel);
  }

  async verifyPlayerOtp(dto: VerifyPlayerOtpDto): Promise<LoginResult> {
    const user = await this.repo.findUserByPhone(dto.phone);
    if (!user) throw new NotFoundError('No player account for this phone number');

    const activation = await this.repo.findLatestActivationCode(user.id);
    if (!activation || activation.used || activation.code !== dto.code) {
      throw new BadRequestError('Invalid or already used code');
    }
    if (activation.expires_at.getTime() < Date.now()) {
      throw new BadRequestError('Code expired — request a new one');
    }
    if (user.account_status === 'BLOCKED') throw new UnauthorizedError('This account has been blocked');

    await this.repo.markActivationCodeUsed(activation.id);
    if (user.account_status === 'INACTIVE') {
      await this.repo.updateAccountStatus(user.id, 'ACTIVE');
    }

    const teamId = await this.repo.getTeamIdForUser(user.id, 'JOUEUR');
    const tokens = await this.issueTokens(user.id, 'JOUEUR', teamId);
    const authenticatedUser = await this.toAuthenticatedUser(user.id, 'JOUEUR');
    return { user: authenticatedUser, tokens };
  }

  // --- Coach / Adjoint: email + password login requires OTP confirmation ----

  private async findStaffByEmail(email: string): Promise<{ user: NonNullable<Awaited<ReturnType<AuthRepository['findUserByEmail']>>>, role: 'COACH' | 'ADJOINT' }> {
    const user = await this.repo.findUserByEmail(email);
    if (!user) throw new NotFoundError('No account with this email');
    const role = await this.repo.getUserRole(user.id);
    if (role !== 'COACH' && role !== 'ADJOINT') {
      throw new BadRequestError('Use phone/code login for player accounts');
    }
    return { user, role };
  }

  async requestCoachOtp(dto: RequestCoachOtpDto): Promise<void> {
    const { user } = await this.findStaffByEmail(dto.email);
    const code = generateOtp();
    const channel = dto.channel ?? 'SMS';
    await this.repo.createActivationCode(user.id, code, channel, otpExpiryDate());
    await sendOtp(user.phone, code, channel);
  }

  async verifyCoachOtp(dto: VerifyCoachOtpDto): Promise<LoginResult> {
    const { user, role } = await this.findStaffByEmail(dto.email);

    const activation = await this.repo.findLatestActivationCode(user.id);
    if (!activation || activation.used || activation.code !== dto.code) {
      throw new BadRequestError('Invalid or already used code');
    }
    if (activation.expires_at.getTime() < Date.now()) {
      throw new BadRequestError('Code expired — request a new one');
    }
    if (user.account_status === 'BLOCKED') throw new UnauthorizedError('This account has been blocked');

    await this.repo.markActivationCodeUsed(activation.id);
    if (user.account_status === 'INACTIVE') {
      await this.repo.updateAccountStatus(user.id, 'ACTIVE');
    }

    const teamId = await this.repo.getTeamIdForUser(user.id, role);
    const tokens = await this.issueTokens(user.id, role, teamId);
    const authenticatedUser = await this.toAuthenticatedUser(user.id, role);
    return { user: authenticatedUser, tokens };
  }

  // --- Shared: refresh / logout ---------------------------------------------

  async refresh(refreshToken: string): Promise<AuthTokens> {
    const idx = refreshToken.lastIndexOf('.');
    if (idx <= 0) throw new UnauthorizedError('Malformed refresh token');
    const jwtPart = refreshToken.slice(0, idx);
    const rawPart = refreshToken.slice(idx + 1);
    if (!rawPart) throw new UnauthorizedError('Malformed refresh token');

    let payload;
    try {
      payload = verifyRefreshToken(jwtPart);
    } catch {
      throw new UnauthorizedError('Invalid or expired refresh token');
    }

    const tokenHash = hashToken(rawPart);
    const stored = await this.repo.findRefreshTokenByHash(tokenHash);
    if (!stored || stored.revoked || stored.id !== payload.tokenId || stored.user_id !== payload.sub) {
      throw new UnauthorizedError('Refresh token has been revoked');
    }
    if (stored.expires_at.getTime() < Date.now()) {
      throw new UnauthorizedError('Refresh token expired');
    }

    await this.repo.revokeRefreshToken(stored.id);

    const user = await this.repo.findUserById(payload.sub);
    if (!user) throw new NotFoundError('User');
    const role = await this.repo.getUserRole(user.id);
    if (!role) throw new NotFoundError('Role');
    const teamId = await this.repo.getTeamIdForUser(user.id, role);
    return this.issueTokens(user.id, role, teamId);
  }

  async logout(userId: number): Promise<void> {
    await this.repo.revokeAllUserRefreshTokens(userId);
  }

  async me(userId: number, role: 'COACH' | 'ADJOINT' | 'JOUEUR'): Promise<AuthenticatedUser> {
    return this.toAuthenticatedUser(userId, role);
  }
}
