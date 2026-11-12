export interface SeasonRecord {
  id: number;
  /** Null only for read-only seasons created before team isolation was introduced. */
  team_id: number | null;
  name: string;
  start_date: Date;
  end_date: Date;
  is_current: boolean;
}
