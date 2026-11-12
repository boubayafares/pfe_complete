import { z } from 'zod';

const notifType = z.enum(['MATCH_CONVOCATION', 'NEW_TRAINING', 'REPORT_AVAILABLE', 'PLANNING_CHANGE', 'OTHER']);

export const createNotificationSchema = z.object({
  userId: z.coerce.number().int().positive(),
  type: notifType,
  title: z.string().min(1).max(200),
  message: z.string().min(1),
  relatedEntityType: z.string().max(50).optional(),
  relatedEntityId: z.coerce.number().int().positive().optional(),
});

export const broadcastNotificationSchema = z.object({
  type: notifType,
  title: z.string().min(1).max(200),
  message: z.string().min(1),
  relatedEntityType: z.string().max(50).optional(),
  relatedEntityId: z.coerce.number().int().positive().optional(),
});

export const sendConvocationSchema = z.object({
  targetType: z.enum(['MATCH', 'TRAINING']),
  targetId: z.coerce.number().int().positive(),
  title: z.string().min(1).max(200).optional(),
  message: z.string().min(1).optional(),
  channels: z.array(z.enum(['APP', 'EMAIL', 'SMS'])).default(['APP', 'EMAIL', 'SMS']),
});

export const registerPushTokenSchema = z.object({
  token: z.string().min(1),
  platform: z.string().max(20).optional(),
});

export const notificationIdParamSchema = z.object({ id: z.coerce.number().int().positive() });
