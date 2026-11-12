import { NotificationsRepository } from './notifications.repository.js';
import type {
  CreateNotificationDto,
  BroadcastNotificationDto,
  SendConvocationDto,
} from './notifications.dto.js';
import { emitNotification } from '../../socket/socket.js';
import { ForbiddenError, NotFoundError } from '../../shared/errors/AppError.js';
import { sendPushToMultiple } from '../../shared/services/notification.service.js';
import { sendBulkEmailsViaSmtp } from '../../shared/services/email.service.js';
import { sendBulkSmsViaTwilio } from '../../shared/services/twilio.service.js';

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
        related_entity_type: dto.relatedEntityType ?? 'team',
        related_entity_id: dto.relatedEntityId ?? dto.teamId,
      });
      emitNotification(userId, notification);
      notifiedTokens.push(...(await this.repo.getPushTokensForUser(userId)));
      created.push(notification);
    }
    if (notifiedTokens.length > 0) {
      try {
        await sendPushToMultiple(notifiedTokens, dto.title, dto.message);
      } catch {
        // Database notifications and socket events are already committed.
        // A remote provider outage must not invite a duplicate broadcast.
      }
    }
    return created;
  }

  async sendConvocation(dto: SendConvocationDto) {
    if (!(await this.repo.targetBelongsToTeam(dto.targetType, dto.targetId, dto.teamId))) {
      throw new NotFoundError(dto.targetType === 'MATCH' ? 'Match' : 'Training');
    }
    const targetLabel = dto.targetType === 'MATCH' ? 'match' : 'entrainement';
    const type = dto.targetType === 'MATCH' ? 'MATCH_CONVOCATION' : 'NEW_TRAINING';
    const title = dto.title ?? `Convocation ${targetLabel}`;
    const message = dto.message ?? `Vous etes convoque pour le ${targetLabel} #${dto.targetId}.`;
    const contacts = await this.repo.getTeamMemberContacts(dto.teamId);
    const channels = new Set(dto.channels ?? ['APP', 'EMAIL', 'SMS']);
    const notifications = channels.has('APP')
      ? await this.broadcastToTeam({
          teamId: dto.teamId,
          type,
          title,
          message,
          relatedEntityType: dto.targetType.toLowerCase(),
          relatedEntityId: dto.targetId,
        })
      : [];
    const emailRecipients = channels.has('EMAIL')
      ? contacts
          .filter((contact): contact is typeof contact & { email: string } => Boolean(contact.email))
          .map((contact) => ({ email: contact.email, subject: title, message }))
      : [];
    const smsRecipients = channels.has('SMS')
      ? contacts
          .filter((contact) => Boolean(contact.phone))
          .map((contact) => ({ phone: contact.phone, message }))
      : [];
    const [emailResults, smsResults] = await Promise.all([
      emailRecipients.length > 0 ? sendBulkEmailsViaSmtp(emailRecipients) : Promise.resolve([]),
      smsRecipients.length > 0 ? sendBulkSmsViaTwilio(smsRecipients) : Promise.resolve([]),
    ]);

    return {
      notifications,
      deliveryPlan: {
        app: notifications.length,
        email: emailRecipients.length,
        sms: smsRecipients.length,
      },
      deliveryResults: {
        email: emailResults,
        sms: smsResults,
      },
      status: 'PROCESSED',
      note: 'APP notifications are persisted and pushed in realtime. Email/SMS are sent best-effort when SMTP/Twilio are configured.',
    };
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
