import crypto from 'crypto';
import { env } from '../../config/env.js';

export function generateOtp(): string {
  const max = 10 ** env.OTP_LENGTH;
  const code = crypto.randomInt(0, max);

  return code.toString().padStart(env.OTP_LENGTH, '0');
}

export function otpExpiryDate(): Date {
  return new Date(
    Date.now() + env.OTP_EXPIRES_MIN * 60 * 1000
  );
}