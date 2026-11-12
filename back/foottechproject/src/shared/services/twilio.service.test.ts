import { describe, expect, it } from 'vitest';
import { hasValidTwilioConfiguration } from './twilio.service.js';

describe('Twilio configuration validation', () => {
  it('rejects the values shipped as placeholders in .env.example', () => {
    expect(hasValidTwilioConfiguration(
      'ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
      'your_auth_token',
      '+1234567890'
    )).toBe(false);
  });

  it('accepts structurally valid Twilio credentials', () => {
    expect(hasValidTwilioConfiguration(
      `AC${'a'.repeat(32)}`,
      'b'.repeat(32),
      '+33612345678'
    )).toBe(true);
  });
});
