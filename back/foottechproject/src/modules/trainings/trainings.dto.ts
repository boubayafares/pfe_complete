export interface CreateTrainingDto {
  date: string;
  startTime: string;
  endTime: string;
  location?: string;
}

export interface UpdateTrainingDto {
  date?: string;
  startTime?: string;
  endTime?: string;
  location?: string;
  status?: 'SCHEDULED' | 'COMPLETED' | 'CANCELLED';
}

export interface UpsertTrainingSheetDto {
  objectifs?: string;
  effectif?: string;
}

export interface CreateSituationDto {
  ordre?: number;
  titre?: string;
  description?: string;
  dureeTravail?: string;
  dureeRecuperation?: string;
  dureeMinutes?: number;
  criteresReussite?: string[];
}

export interface UpdateSituationDto extends Partial<CreateSituationDto> {}

export interface SaveTacticalDrawingDto {
  canvasData: Record<string, unknown>;
}
