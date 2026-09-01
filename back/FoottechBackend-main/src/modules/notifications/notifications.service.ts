import { NotificationsRepository } from './notifications.repository.js';
import type{ CreateNotificationDto, BroadcastNotificationDto } from './notifications.dto.js';
import { emitNotification } from '../../socket/socket.js';
import { ForbiddenError } from '../../shared/errors/AppError.js';
import { sendPushToMultiple } from '../../shared/services/notification.service.js';

export class NotificationsService {
  private readonly repo = new NotificationsRepository();

  async listForUser(userId: number) {
    return this.repo.listForUser(userId);
  }

  async create(teamId: number, dto: CreateNotificationDto) {
    // Prevent staff from notifying users outside their own team.
    const memberIds = await this.repo.getTeamMemberIds(teamId);
    if (!memberIds.map(Number).includes(Number(dto.userId))) {
      throw new ForbiddenError('You can only notify members of your own team');
    }
    const notification = await this.repo.create({
      user_id: dto.userId,
      type: dto.type,
      title: dto.title,
      message: dto.message,
      related_entity_type: dto.relatedEntityType ?? null,
      related_entity_id: dto.relatedEntityId ?? null,
    });
    emitNotification(dto.userId, notification);
    // Best-effort remote push to the recipient's registered devices.
    await this.pushToUser(Number(dto.userId), notification);
    return notification;
  }

  /** Sends the same notification to every player + adjoint on a team (match convocation, new training...). */
  async broadcastToTeam(dto: BroadcastNotificationDto) {
    const memberIds = await this.repo.getTeamMemberIds(dto.teamId);
    const created = [];
    const notifiedTokens: string[] = [];
    for (const userId of memberIds) {
      const notification = await this.repo.create({
        user_id: userId,
        type: dto.type,
        title: dto.title,
        message: dto.message,
        related_entity_type: 'team',
        related_entity_id: dto.teamId,
      });
      emitNotification(userId, notification);
      notifiedTokens.push(...(await this.repo.getPushTokensForUser(userId)));
      created.push(notification);
    }
    if (notifiedTokens.length > 0) {
      await sendPushToMultiple(notifiedTokens, dto.title, dto.message);
    }
    return created;
  }

  async markAsRead(id: number, userId: number) {
    await this.repo.markAsRead(id, userId);
  }

  async markAllAsRead(userId: number) {
    await this.repo.markAllAsRead(userId);
  }

  async registerPushToken(userId: number, token: string, platform?: string) {
    await this.repo.registerPushToken(userId, token, platform);
  }

  private async pushToUser(userId: number, notification: {
    id: number;
    type: string;
    title: string;
    message: string;
  }): Promise<void> {
    const tokens = await this.repo.getPushTokensForUser(userId);
    if (tokens.length === 0) return;
    try {
      await sendPushToMultiple(tokens, notification.title, notification.message, {
        type: notification.type,
        notificationId: String(notification.id),
      });
    } catch (error) {
      // Push is best-effort — do not fail the notification request.
    }
  }
}
