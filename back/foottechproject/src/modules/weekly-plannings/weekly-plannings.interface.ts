export interface WeeklyPlanningRecord {
  id: number;
  team_id: number;
  season_id: number | null;
  semaine_numero: number | null;
  date_debut: Date;
  date_fin: Date;
  nombre_seances: number | null;
  intensite: string | null;
  volume: string | null;
  match_prevu: boolean;
}

export interface WeeklyPlanningSlotRecord {
  id: number;
  weekly_planning_id: number;
  jour: Date;
  moment: 'MATIN' | 'APRES_MIDI' | 'SOIR';
  training_id: number | null;
  description: string | null;
}
