import jwt from 'jsonwebtoken';
import type{ SignOptions } from 'jsonwebtoken';
import { env } from '../../config/env.js';

export interface AccessTokenPayload {
  sub: number;
  role: 'COACH' | 'ADJOINT' | 'JOUEUR';
  teamId?: number;
}

export interface RefreshTokenPayload {
  sub: number;
  tokenId: number;
  teamId?: number;
}

export function signAccessToken(payload: AccessTokenPayload): string {
  return jwt.sign(payload, env.JWT_ACCESS_SECRET, {
    algorithm: 'HS256',
    expiresIn: env.JWT_ACCESS_EXPIRES_IN,
    issuer: env.JWT_ISSUER,
    audience: env.JWT_AUDIENCE,
  } as SignOptions);
}

export function signRefreshToken(payload: RefreshTokenPayload): string {
  return jwt.sign(payload, env.JWT_REFRESH_SECRET, {
    algorithm: 'HS256',
    expiresIn: env.JWT_REFRESH_EXPIRES_IN,
    issuer: env.JWT_ISSUER,
    audience: env.JWT_AUDIENCE,
  } as SignOptions);
}

export function verifyAccessToken(token: string): AccessTokenPayload {
  const payload = jwt.verify(token, env.JWT_ACCESS_SECRET, {
    algorithms: ['HS256'],
    issuer: env.JWT_ISSUER,
    audience: env.JWT_AUDIENCE,
  });
  if (typeof payload === 'string' || typeof payload.sub !== 'number' || !['COACH', 'ADJOINT', 'JOUEUR'].includes(payload.role)) {
    throw new Error('Invalid access token payload');
  }
  return {
    sub: payload.sub,
    role: payload.role as AccessTokenPayload['role'],
    ...(typeof payload.teamId === 'number' && { teamId: payload.teamId }),
  };
}

export function verifyRefreshToken(token: string): RefreshTokenPayload {
  const payload = jwt.verify(token, env.JWT_REFRESH_SECRET, {
    algorithms: ['HS256'],
    issuer: env.JWT_ISSUER,
    audience: env.JWT_AUDIENCE,
  });
  if (typeof payload === 'string' || typeof payload.sub !== 'number' || typeof payload.tokenId !== 'number') {
    throw new Error('Invalid refresh token payload');
  }
  return {
    sub: payload.sub,
    tokenId: payload.tokenId,
    ...(typeof payload.teamId === 'number' && { teamId: payload.teamId }),
  };
}
