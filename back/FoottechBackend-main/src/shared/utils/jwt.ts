import jwt from 'jsonwebtoken';
import type{ SignOptions } from 'jsonwebtoken';
//import type{ env } from '../../config/env.js';

export interface AccessTokenPayload {
  sub: number;
  role: 'COACH' | 'ADJOINT' | 'JOUEUR';
  teamId?: number;
}

export interface RefreshTokenPayload {
  sub: number;
  tokenId: number;
}

export function signAccessToken(payload: AccessTokenPayload): string {
  return jwt.sign(payload, process.env.JWT_ACCESS_SECRET as string, { expiresIn: process.env.JWT_ACCESS_EXPIRES_IN } as SignOptions);
}

export function signRefreshToken(payload: RefreshTokenPayload): string {
  return jwt.sign(payload, process.env.JWT_REFRESH_SECRET as string, { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN } as SignOptions);
}

export function verifyAccessToken(token: string): AccessTokenPayload {
  return jwt.verify(token, process.env.JWT_ACCESS_SECRET as string) as unknown as AccessTokenPayload;
}

export function verifyRefreshToken(token: string): RefreshTokenPayload {
  return jwt.verify(token, process.env.JWT_REFRESH_SECRET as string) as unknown as RefreshTokenPayload;
}
