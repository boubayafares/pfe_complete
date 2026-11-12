export interface TrainingRecord {
  id: number;
  team_id: number;
  date: Date;
  start_time: string;
  end_time: string;
  location: string | null;
  status: 'SCHEDULED' | 'COMPLETED' | 'CANCELLED';
  created_by: number | null;
}

export interface TrainingSheetRecord {
  id: number;
  training_id: number;
  objectifs: string | null;
  effectif: string | null;
  created_by: number | null;
  created_at: Date;
}

export interface TrainingSituationRecord {
  id: number;
  training_sheet_id: number;
  ordre: number;
  titre: string | null;
  description: string | null;
  duree_travail: string | null;
  duree_recuperation: string | null;
  duree_minutes: number | null;
  criteres_reussite: string[] | null;
}

export interface TacticalDrawingRecord {
  id: number;
  training_situation_id: number | null;
  match_id: number | null;
  canvas_data: Record<string, unknown>;
  created_by: number | null;
  created_at: Date;
}
