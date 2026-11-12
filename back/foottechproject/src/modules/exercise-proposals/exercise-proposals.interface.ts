export interface ExerciseProposalRecord {
  id: number;
  team_id: number | null;
  training_id: number | null;
  proposed_by: number;
  titre: string;
  description: string | null;
  category: string | null;
  objectif: string | null;
  difficulty: 'EASY' | 'MEDIUM' | 'HARD' | 'ELITE' | null;
  duration_minutes: number | null;
  visibility: 'PRIVATE' | 'TEAM' | 'COMMUNITY' | null;
  tags: string[] | null;
  canvas_data: Record<string, unknown> | null;
  animation_data: Record<string, unknown> | null;
  ai_model: Record<string, unknown> | null;
  status: 'PENDING' | 'VALIDATED' | 'REJECTED';
  reviewed_by: number | null;
  reviewed_at: Date | null;
  review_comment: string | null;
  created_at: Date;
}
