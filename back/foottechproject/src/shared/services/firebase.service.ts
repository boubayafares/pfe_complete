import { initializeApp, cert } from 'firebase-admin/app';
import { getMessaging, type MulticastMessage } from 'firebase-admin/messaging';
import { env } from '../../config/env.js';
import { logger } from '../logger/logger.js';

let initialized = false;

export function hasValidFirebaseConfiguration(
  projectId = env.FIREBASE_PROJECT_ID,
  privateKey = env.FIREBASE_PRIVATE_KEY,
  clientEmail = env.FIREBASE_CLIENT_EMAIL
): boolean {
  const normalizedKey = privateKey.replace(/\\n/g, '\n').trim();
  const keyBody = normalizedKey
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');

  return /^[a-z0-9][a-z0-9-]{4,28}[a-z0-9]$/.test(projectId)
    && !projectId.includes('xxxxx')
    && /^firebase-adminsdk-[^@]+@[^@]+\.iam\.gserviceaccount\.com$/.test(clientEmail)
    && !clientEmail.includes('xxxxx')
    && normalizedKey.startsWith('-----BEGIN PRIVATE KEY-----')
    && normalizedKey.endsWith('-----END PRIVATE KEY-----')
    && !normalizedKey.includes('...')
    && keyBody.length >= 100;
}

export function initFirebase(): void {
  if (initialized) return;

  if (!hasValidFirebaseConfiguration()) {
    logger.warn('Firebase is missing or invalid — push notifications are unavailable');
    return;
  }

  try {
    initializeApp({
      credential: cert({
        projectId: env.FIREBASE_PROJECT_ID,
        privateKey: env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        clientEmail: env.FIREBASE_CLIENT_EMAIL,
      }),
    });

    initialized = true;
    logger.info('Firebase Admin initialized');
  } catch (error) {
    logger.error('Failed to initialize Firebase', {
      error: error instanceof Error ? error.message : error,
    });
  }
}

export async function sendPushNotification(
  fcmToken: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<string | null> {
  if (!initialized) {
    // Notification contents can contain private team or medical information.
    logger.info('Push notification skipped — Firebase unavailable');
    return null;
  }

  try {
    const result = await getMessaging().send({
      token: fcmToken,
      notification: { title, body },
      ...(data ? { data } : {}),
      android: {
        priority: 'high',
        notification: {
          channelId: 'foottech-default',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            sound: 'default',
            badge: 1,
          },
        },
      },
    });

    logger.info('Push notification sent', { messageId: result });
    return result;
  } catch (error) {
    logger.error('Push notification failed', {
      error: error instanceof Error ? error.message : error,
    });
    throw error;
  }
}

export async function sendBulkPushNotifications(
  tokens: string[],
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<{ successCount: number; failureCount: number }> {
  if (!initialized || tokens.length === 0) {
    logger.info('Bulk push skipped — Firebase unavailable', { recipientCount: tokens.length });
    return { successCount: 0, failureCount: 0 };
  }

  try {
    const message: MulticastMessage = {
      tokens,
      notification: { title, body },
      ...(data ? { data } : {}),
      android: {
        priority: 'high',
        notification: {
          channelId: 'foottech-default',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    const response = await getMessaging().sendEachForMulticast(message);

    logger.info('Bulk push sent', {
      successCount: response.successCount,
      failureCount: response.failureCount,
    });

    return {
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  } catch (error) {
    logger.error('Bulk push failed', {
      error: error instanceof Error ? error.message : error,
    });
    throw error;
  }
}

export function isFirebaseInitialized(): boolean {
  return initialized;
}
