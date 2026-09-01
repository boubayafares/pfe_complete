import { initializeApp, cert } from 'firebase-admin/app';
import { getMessaging, type MulticastMessage } from 'firebase-admin/messaging';
import { env } from '../../config/env.js';
import { logger } from '../logger/logger.js';

let initialized = false;

export function initFirebase(): void {
  if (initialized) return;

  if (!env.FIREBASE_PROJECT_ID || !env.FIREBASE_PRIVATE_KEY || !env.FIREBASE_CLIENT_EMAIL) {
    logger.warn('Firebase not configured — push notifications will be logged only');
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
    logger.info('Push notification (dev mode)', { title, body: body.slice(0, 50) });
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
      token: fcmToken.slice(0, 10) + '...',
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
    logger.info('Bulk push notification (dev mode)', {
      title,
      recipientCount: tokens.length,
    });
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
