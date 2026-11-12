import nodemailer from 'nodemailer';
import { env } from '../../config/env.js';
import { logger } from '../logger/logger.js';

let transporter: nodemailer.Transporter | null = null;
let invalidConfigurationWarningLogged = false;

export function hasValidSmtpConfiguration(): boolean {
  return Boolean(env.SMTP_HOST && env.SMTP_FROM);
}

function getTransporter(): nodemailer.Transporter | null {
  if (transporter) return transporter;

  if (!hasValidSmtpConfiguration()) {
    if (!invalidConfigurationWarningLogged) {
      logger.warn('SMTP is missing — email convocations are unavailable');
      invalidConfigurationWarningLogged = true;
    }
    return null;
  }

  transporter = nodemailer.createTransport({
    host: env.SMTP_HOST,
    port: env.SMTP_PORT,
    secure: env.SMTP_SECURE,
    auth: env.SMTP_USER
      ? {
          user: env.SMTP_USER,
          pass: env.SMTP_PASSWORD,
        }
      : undefined,
  });
  return transporter;
}

export async function sendEmailViaSmtp(
  to: string,
  subject: string,
  text: string
): Promise<{ messageId: string } | null> {
  const smtp = getTransporter();
  if (!smtp) {
    if (env.NODE_ENV === 'production') {
      throw new Error('Email provider is not configured');
    }
    logger.info('Email convocation skipped (dev mode)', { to });
    return null;
  }

  const result = await smtp.sendMail({
    from: env.SMTP_FROM,
    to,
    subject,
    text,
  });

  logger.info('Email convocation sent', {
    messageId: result.messageId,
    to,
  });

  return { messageId: result.messageId };
}

export async function sendBulkEmailsViaSmtp(
  recipients: Array<{ email: string; subject: string; message: string }>
): Promise<Array<{ email: string; messageId: string | null; error?: string }>> {
  const results: Array<{
    email: string;
    messageId: string | null;
    error?: string;
  }> = [];

  for (const recipient of recipients) {
    try {
      const result = await sendEmailViaSmtp(
        recipient.email,
        recipient.subject,
        recipient.message
      );
      results.push({ email: recipient.email, messageId: result?.messageId ?? null });
    } catch (error) {
      results.push({
        email: recipient.email,
        messageId: null,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }

  return results;
}
