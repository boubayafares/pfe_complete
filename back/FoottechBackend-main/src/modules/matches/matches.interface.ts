export interface MatchRecord {
  id: number;
  team_id: number;
  season_id: number | null;
  adversaire: string;
  date_heure: Date;
  lieu: string | null;
  is_home: boolean;
  formation: string | null;
  home_score: number;
  away_score: number;
  match_status: 'SCHEDULED' | 'LIVE' | 'FINISHED' | 'CANCELLED' | 'POSTPONED';
  created_at: Date;
}

export interface MatchLineupRecord {
  id: number;
  match_id: number;
  player_id: number;
  status: 'STARTER' | 'SUBSTITUTE' | 'NOT_SELECTED';
  position_terrain: string | null;
  selected_by: number | null;
}

export interface MatchLineupWithPlayer extends MatchLineupRecord {
  first_name: string;
  last_name: string;
  numero_maillot: number | null;
}

export interface AiLineupRecommendationRecord {
  id: number;
  match_id: number;
  player_id: number;
  presence_score: number | null;
  performance_score: number | null;
  fatigue_score: number | null;
  final_score: number | null;
  recommended_status: 'STARTER' | 'SUBSTITUTE' | 'NOT_SELECTED' | null;
  generated_at: Date;
}

export interface MatchEventRecord {
  id: number;
  match_id: number;
  event_type: 'GOAL' | 'ASSIST' | 'YELLOW_CARD' | 'RED_CARD' | 'SUBSTITUTION_IN' | 'SUBSTITUTION_OUT' | 'INJURY';
  minute: number;
  player_id: number | null;
  related_player_id: number | null;
  comment: string | null;
  created_by: number | null;
  created_at: Date;
}

export interface MatchPlayerStatRecord {
  id: number;
  match_id: number;
  player_id: number;
  minutes_played: number;
  goals: number;
  assists: number;
  goals_conceded: number;
  yellow_cards: number;
  red_cards: number;
}

export interface MatchEvaluationRecord {
  id: number;
  match_id: number;
  player_id: number;
  note: number | null;
  commentaire: string | null;
  evaluated_by: number;
  evaluated_at: Date;
}

export interface MatchReportRecord {
  id: number;
  match_id: number;
  pdf_url: string | null;
  generated_at: Date;
}
