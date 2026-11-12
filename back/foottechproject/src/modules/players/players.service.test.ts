import { beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({
  getTeamIdForUser: vi.fn(),
  createActivationCode: vi.fn(),
  createPlayer: vi.fn(),
  sendOtpBestEffort: vi.fn(),
}));

vi.mock('./players.repository.js', () => ({
  PlayersRepository: class {
    createPlayer = mocks.createPlayer;
  },
}));

vi.mock('../auth/auth.repository.js', () => ({
  AuthRepository: class {
    getTeamIdForUser = mocks.getTeamIdForUser;
    createActivationCode = mocks.createActivationCode;
  },
}));

vi.mock('../../shared/services/notification.service.js', () => ({
  sendOtpBestEffort: mocks.sendOtpBestEffort,
}));

import { PlayersService } from './players.service.js';
import { activationCodeMatches } from '../../shared/utils/activation-code.js';

describe('PlayersService.create', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.getTeamIdForUser.mockResolvedValue(7);
    mocks.createPlayer.mockResolvedValue({ id: 42, team_id: 7 });
    mocks.createActivationCode.mockResolvedValue({ id: 1 });
    mocks.sendOtpBestEffort.mockResolvedValue(false);
  });

  it('stores a keyed OTP digest and returns the committed player when delivery fails', async () => {
    const service = new PlayersService();
    const result = await service.create(
      { firstName: 'Test', lastName: 'Player', phone: '+33600000000' },
      { sub: 1, role: 'COACH' }
    );

    const deliveredCode = mocks.sendOtpBestEffort.mock.calls[0]?.[1] as string;
    const storedDigest = mocks.createActivationCode.mock.calls[0]?.[1] as string;

    expect(storedDigest).not.toBe(deliveredCode);
    expect(activationCodeMatches(42, deliveredCode, storedDigest)).toBe(true);
    expect(result).toMatchObject({ id: 42, activationDelivery: 'FAILED' });
  });
});
