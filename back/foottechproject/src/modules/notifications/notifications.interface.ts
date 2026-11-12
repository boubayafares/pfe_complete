export interface NotificationRecord {
  id: number;
  user_id: number;
  type: 'MATCH_CONVOCATION' | 'NEW_TRAINING' | 'REPORT_AVAILABLE' | 'PLANNING_CHANGE' | 'OTHER';
  title: string;
  message: string;
  related_entity_type: string | null;
  related_entity_id: number | null;
  is_read: boolean;
  created_at: Date;
}
