import { describe, expect, it } from 'vitest';
import { hasValidFirebaseConfiguration } from './firebase.service.js';

describe('Firebase configuration validation', () => {
  it('rejects the placeholder values shipped in .env.example', () => {
    expect(hasValidFirebaseConfiguration(
      'foottech-xxxxx',
      '-----BEGIN PRIVATE KEY-----\\n...\\n-----END PRIVATE KEY-----',
      'firebase-adminsdk-xxxxx@foottech-xxxxx.iam.gserviceaccount.com'
    )).toBe(false);
  });

  it('accepts structurally valid service-account values', () => {
    expect(hasValidFirebaseConfiguration(
      'foottech-production',
      `-----BEGIN PRIVATE KEY-----\n${'A'.repeat(128)}\n-----END PRIVATE KEY-----`,
      'firebase-adminsdk-runtime@foottech-production.iam.gserviceaccount.com'
    )).toBe(true);
  });
});
