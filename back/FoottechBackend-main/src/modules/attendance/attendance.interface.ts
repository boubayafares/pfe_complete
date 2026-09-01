export interface AttendanceRecord {
  id: number;
  training_id: number;
  player_id: number;
  status: 'PRESENT' | 'ABSENT' | 'LATE' | 'INJURED';
  comment: string | null;
  created_at: Date;
}

export interface AttendanceWithPlayer extends AttendanceRecord {
  first_name: string;
  last_name: string;
  numero_maillot: number | null;
}
