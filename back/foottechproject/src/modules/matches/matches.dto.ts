export interface CreateMatchDto {
  seasonId?: number;
  adversaire: string;
  dateHeure: string;
  lieu?: string;
  isHome?: boolean;
  formation?: string;
}

export interface UpdateMatchStatusDto {
  matchStatus: 'SCHEDULED' | 'LIVE' | 'FINISHED' | 'CANCELLED' | 'POSTPONED';
}

export interface SetLineupEntryDto {
  playerId: number;
  status: 'STARTER' | 'SUBSTITUTE' | 'NOT_SELECTED';
  positionTerrain?: string;
}

export interface SetLineupDto {
  entries: SetLineupEntryDto[];
}

export interface GenerateAiRecommendationsDto {
  // Empty for now — the AI scoring reads presence (attendance history),
  // performance (match_player_stats/evaluations), and fatigue (recent
  // minutes played) directly from the DB. Kept as a DTO so filters
  // (e.g. limit to a shortlist of player ids) can be added later.
  playerIds?: number[];
}

export interface CreateMatchEventDto {
  eventType: 'GOAL' | 'ASSIST' | 'YELLOW_CARD' | 'RED_CARD' | 'SUBSTITUTION_IN' | 'SUBSTITUTION_OUT' | 'INJURY';
  minute: number;
  playerId?: number;
  relatedPlayerId?: number;
  comment?: string;
}

export interface UpsertPlayerStatDto {
  playerId: number;
  minutesPlayed?: number;
  goals?: number;
  assists?: number;
  goalsConceded?: number;
  yellowCards?: number;
  redCards?: number;
}

export interface UpsertEvaluationDto {
  playerId: number;
  note?: number;
  commentaire?: string;
}

export interface SaveMatchReportDto {
  pdfUrl: string;
}
