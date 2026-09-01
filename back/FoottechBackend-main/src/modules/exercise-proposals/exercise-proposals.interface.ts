export interface ExerciseProposalRecord {
  id: number;
  training_id: number | null;
  proposed_by: number;
  titre: string;
  description: string | null;
  status: 'PENDING' | 'VALIDATED' | 'REJECTED';
  reviewed_by: number | null;
  reviewed_at: Date | null;
  review_comment: string | null;
  created_at: Date;
}
