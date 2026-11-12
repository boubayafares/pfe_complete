export interface CreateProposalDto {
  trainingId?: number;
  titre: string;
  description?: string;
  category?: string;
  objectif?: string;
  difficulty?: 'EASY' | 'MEDIUM' | 'HARD' | 'ELITE';
  durationMinutes?: number;
  visibility?: 'PRIVATE' | 'TEAM' | 'COMMUNITY';
  tags?: string[];
  canvasData?: Record<string, unknown>;
  animationData?: Record<string, unknown>;
}

export interface ReviewProposalDto {
  status: 'VALIDATED' | 'REJECTED';
  reviewComment?: string;
}
