import { beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({
  targetBelongsToTeam: vi.fn(),
  getTeamMemberContacts: vi.fn(),
  getTeamMemberIds: vi.fn(),
  create: vi.fn(),
  getPushTokensForUser: vi.fn(),
  sendPushToMultiple: vi.fn(),
  sendBulkEmailsViaSmtp: vi.fn(),
  sendBulkSmsViaTwilio: vi.fn(),
  emitNotification: vi.fn(),
}));

vi.mock('./notifications.repository.js', () => ({
  NotificationsRepository: class {
    targetBelongsToTeam = mocks.targetBelongsToTeam;
    getTeamMemberContacts = mocks.getTeamMemberContacts;
    getTeamMemberIds = mocks.getTeamMemberIds;
    create = mocks.create;
    getPushTokensForUser = mocks.getPushTokensForUser;
  },
}));

vi.mock('../../socket/socket.js', () => ({ emitNotification: mocks.emitNotification }));
vi.mock('../../shared/services/notification.service.js', () => ({
  sendPushToMultiple: mocks.sendPushToMultiple,
}));
vi.mock('../../shared/services/email.service.js', () => ({
  sendBulkEmailsViaSmtp: mocks.sendBulkEmailsViaSmtp,
}));
vi.mock('../../shared/services/twilio.service.js', () => ({
  sendBulkSmsViaTwilio: mocks.sendBulkSmsViaTwilio,
}));

import { NotificationsService } from './notifications.service.js';

describe('NotificationsService convocation ownership', () => {
  beforeEach(() => vi.clearAllMocks());

  it('rejects a target outside the authenticated team before delivery', async () => {
    mocks.targetBelongsToTeam.mockResolvedValue(false);

    await expect(new NotificationsService().sendConvocation({
      teamId: 7,
      targetType: 'MATCH',
      targetId: 99,
      channels: ['APP', 'EMAIL', 'SMS'],
    })).rejects.toMatchObject({ statusCode: 404 });

    expect(mocks.getTeamMemberContacts).not.toHaveBeenCalled();
    expect(mocks.sendBulkEmailsViaSmtp).not.toHaveBeenCalled();
    expect(mocks.sendBulkSmsViaTwilio).not.toHaveBeenCalled();
    expect(mocks.emitNotification).not.toHaveBeenCalled();
  });
});
