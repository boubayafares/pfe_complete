export interface MarkAttendanceDto {
  playerId: number;
  status: 'PRESENT' | 'ABSENT' | 'LATE' | 'INJURED';
  comment?: string;
}

export interface BulkMarkAttendanceDto {
  entries: MarkAttendanceDto[];
}
