import { beforeEach, describe, expect, it, vi } from 'vitest';
import { env } from '../../config/env.js';

const { sendOtpViaTwilio } = vi.hoisted(() => ({
  sendOtpViaTwilio: vi.fn(),
}));

vi.mock('./twilio.service.js', () => ({
  sendOtpViaTwilio,
}));

import { sendOtp, sendOtpBestEffort } from './notification.service.js';

describe('sendOtpBestEffort', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    env.OTP_DEV_CODE = '';
  });

  it('bypasses the provider only when a local development OTP is explicitly enabled', async () => {
    const previousNodeEnv = env.NODE_ENV;
    env.NODE_ENV = 'development';
    env.OTP_DEV_CODE = '123456';

    try {
      await expect(sendOtp('+33600000000', '123456', 'SMS')).resolves.toBeUndefined();
      expect(sendOtpViaTwilio).not.toHaveBeenCalled();
    } finally {
      env.NODE_ENV = previousNodeEnv;
      env.OTP_DEV_CODE = '';
    }
  });

  it('reports successful delivery', async () => {
    sendOtpViaTwilio.mockResolvedValue(undefined);
    await expect(sendOtpBestEffort('+33600000000', '123456', 'SMS')).resolves.toBe(true);
  });

  it('does not convert an already-created resource into an HTTP 500 on provider failure', async () => {
    sendOtpViaTwilio.mockRejectedValue(new Error('provider unavailable'));
    await expect(sendOtpBestEffort('+33600000000', '123456', 'SMS')).resolves.toBe(false);
  });

  it('maps an OTP provider outage to a retryable 503 on explicit delivery requests', async () => {
    sendOtpViaTwilio.mockRejectedValue(new Error('provider unavailable'));
    await expect(sendOtp('+33600000000', '123456', 'SMS')).rejects.toMatchObject({
      statusCode: 503,
    });
  });
});
