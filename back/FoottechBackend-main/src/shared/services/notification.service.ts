import { env } from '../../config/env.js';
import { logger } from '../logger/logger.js';
import { sendOtpViaTwilio } from './twilio.service.js';
import { sendPushNotification, sendBulkPushNotifications } from './firebase.service.js';

export async function sendOtp(
  phone: string,
  code: string,
  channel: 'SMS' | 'WHATSAPP'
): Promise<void> {
  const message =
    `Your Football Team Manager verification code is: ${code}`;

  if (channel === 'SMS') {
    await sendOtpViaTwilio(phone, code);
    return;
  }

  if (channel === 'WHATSAPP') {
    await sendWhatsApp(phone, message);
    return;
  }
}

async function sendWhatsApp(
  phone: string,
  message: string
): Promise<void> {
  if (!env.TWILIO_ACCOUNT_SID) {
    logger.warn('Twilio not configured for WhatsApp', {
      phone: phone.slice(-4),
    });
    return;
  }

  // Twilio WhatsApp API uses the same messaging endpoint with whatsapp: prefix
  const { sendSmsViaTwilio } = await import('./twilio.service.js');
  await sendSmsViaTwilio(`whatsapp:${phone}`, message);
}

export async function sendPushToUser(
  fcmToken: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<void> {
  await sendPushNotification(fcmToken, title, body, data);
}

export async function sendPushToMultiple(
  tokens: string[],
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<void> {
  await sendBulkPushNotifications(tokens, title, body, data);
}
