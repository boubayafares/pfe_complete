export interface CreateWeeklyPlanningDto {
  teamId: number;
  seasonId?: number;
  semaineNumero?: number;
  dateDebut: string;
  dateFin: string;
  nombreSeances?: number;
  intensite?: string;
  volume?: string;
  matchPrevu?: boolean;
}

export interface UpdateWeeklyPlanningDto extends Partial<Omit<CreateWeeklyPlanningDto, 'teamId'>> {}

export interface UpsertSlotDto {
  jour: string;
  moment: 'MATIN' | 'APRES_MIDI' | 'SOIR';
  trainingId?: number;
  description?: string;
}
