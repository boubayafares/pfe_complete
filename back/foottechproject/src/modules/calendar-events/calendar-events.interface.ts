export interface CalendarEventRecord {
  id: number;
  team_id: number;
  title: string;
  description: string | null;
  start_time: Date;
  end_time: Date | null;
  all_day: boolean;
  location: string | null;
  color: string | null;
  created_by: number | null;
  created_at: Date;
  updated_at: Date;
}

/** Title-only projection served to JOUEUR members (read-only "lire just title"). */
export interface CalendarEventLite {
  id: number;
  title: string;
  start_time: Date;
  end_time: Date | null;
  all_day: boolean;
  color: string | null;
}
