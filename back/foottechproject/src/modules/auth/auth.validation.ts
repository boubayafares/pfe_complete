import { z } from 'zod';

const phoneSchema = z.string().min(8).max(30);

export const registerCoachSchema = z.object({
  firstName: z.string().min(1).max(100),
  lastName: z.string().min(1).max(100),
  phone: phoneSchema,
  email: z.string().email(),
  password: z.string().min(8).max(128),
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

export const requestPlayerOtpSchema = z.object({
  phone: phoneSchema,
  channel: z.enum(['SMS', 'WHATSAPP']).optional(),
});

export const requestAdjointOtpSchema = requestPlayerOtpSchema;

export const verifyPlayerOtpSchema = z.object({
  phone: phoneSchema,
  code: z.string().min(4).max(10),
});

export const requestCoachOtpSchema = z.object({
  email: z.string().email(),
  channel: z.enum(['SMS', 'WHATSAPP']).optional(),
});

export const verifyCoachOtpSchema = z.object({
  email: z.string().email(),
  code: z.string().min(4).max(10),
});

export const refreshSchema = z.object({
  refreshToken: z.string().min(1),
});

export const selectTeamSchema = z.object({
  teamId: z.coerce.number().int().positive(),
});

export const setAdjointPasswordSchema = z.object({
  userId: z.coerce.number().int().positive(),
  password: z.string().min(8).max(128),
});

export const activateAdjointByPhoneSchema = z.object({
  phone: phoneSchema,
  code: z.string().min(4).max(10),
  password: z.string().min(8).max(128),
});
