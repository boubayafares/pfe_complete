export const ROLES = {
  COACH: 'COACH',
  ADJOINT: 'ADJOINT',
  JOUEUR: 'JOUEUR',
} as const;

export type RoleName = (typeof ROLES)[keyof typeof ROLES];

export const ACCOUNT_STATUS = ['ACTIVE', 'INACTIVE', 'BLOCKED'] as const;
export const TRAINING_STATUS = ['SCHEDULED', 'COMPLETED', 'CANCELLED'] as const;
export const PLANNING_MOMENT = ['MATIN', 'APRES_MIDI', 'SOIR'] as const;
export const PROPOSAL_STATUS = ['PENDING', 'VALIDATED', 'REJECTED'] as const;
export const ATTENDANCE_STATUS = ['PRESENT', 'ABSENT', 'LATE', 'INJURED'] as const;
export const MATCH_STATUS = ['SCHEDULED', 'LIVE', 'FINISHED', 'CANCELLED', 'POSTPONED'] as const;
export const LINEUP_STATUS = ['STARTER', 'SUBSTITUTE', 'NOT_SELECTED'] as const;
export const MATCH_EVENT_TYPE = [
  'GOAL', 'ASSIST', 'YELLOW_CARD', 'RED_CARD', 'SUBSTITUTION_IN', 'SUBSTITUTION_OUT', 'INJURY',
] as const;
export const NIVEAU_SCOLAIRE = ['FAIBLE', 'MOYEN', 'BIEN', 'TRES_BIEN'] as const;
export const PIED_FORT = ['DROIT', 'GAUCHE', 'AMBIDEXTRE'] as const;
export const GUARDIAN_RELATION = ['PERE', 'MERE', 'TUTEUR'] as const;
export const NOTIFICATION_TYPE = [
  'MATCH_CONVOCATION', 'NEW_TRAINING', 'REPORT_AVAILABLE', 'PLANNING_CHANGE', 'OTHER',
] as const;

export const DB_SCHEMA = 'platform';
