export interface CreateNotificationDto {
  userId: number;
  type: 'MATCH_CONVOCATION' | 'NEW_TRAINING' | 'REPORT_AVAILABLE' | 'PLANNING_CHANGE' | 'OTHER';
  title: string;
  message: string;
  relatedEntityType?: string;
  relatedEntityId?: number;
}

export interface BroadcastNotificationDto {
  teamId: number;
  type: 'MATCH_CONVOCATION' | 'NEW_TRAINING' | 'REPORT_AVAILABLE' | 'PLANNING_CHANGE' | 'OTHER';
  title: string;
  message: string;
  relatedEntityType?: string;
  relatedEntityId?: number;
}

export interface SendConvocationDto {
  teamId: number;
  targetType: 'MATCH' | 'TRAINING';
  targetId: number;
  title?: string;
  message?: string;
  channels?: Array<'APP' | 'EMAIL' | 'SMS'>;
}

export interface RegisterPushTokenDto {
  token: string;
  platform?: string;
}
