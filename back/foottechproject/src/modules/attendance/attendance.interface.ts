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

/**
 * Roster row returned by the attendance sheet. A player who has not been
 * marked yet still belongs on the sheet, hence the nullable persistence
 * fields and the UI-only UNMARKED status.
 */
export interface AttendanceRosterEntry {
  id: number | null;
  training_id: number;
  player_id: number;
  status: AttendanceRecord['status'] | 'UNMARKED';
  comment: string | null;
  created_at: Date | null;
  first_name: string;
  last_name: string;
  numero_maillot: number | null;
}
