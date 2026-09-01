export interface CreateProposalDto {
  trainingId?: number;
  titre: string;
  description?: string;
}

export interface ReviewProposalDto {
  status: 'VALIDATED' | 'REJECTED';
  reviewComment?: string;
}
