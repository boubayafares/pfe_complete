/**
 * Snippet de référence — à intégrer dans matches.service.ts (méthode
 * appelée par POST /matches/:id/ai-recommendations). N'écrase pas de
 * fichier existant : à copier/adapter dans le module matches réel.
 *
 * Contrat exact avec lineup-recommendation-service — voir README.md du
 * microservice pour le détail des champs.
 */
import { env } from '../../config/env.js';

interface LineupServicePlayerInput {
  playerId: number;
  presenceRate: number; // 0..1
  recentPerformanceRating: number; // 0..10
  acuteChronicWorkloadRatio: number; // ACWR
  daysSinceLastMatch: number;
}

interface LineupServiceRecommendation {
  playerId: number;
  presenceScore: number;
  performanceScore: number;
  fatigueScore: number;
  finalScore: number;
  recommendedStatus: 'STARTER' | 'SUBSTITUTE' | 'NOT_SELECTED';
}

interface LineupServiceResponse {
  matchId: number;
  weightsVersion: string;
  recommendations: LineupServiceRecommendation[];
}

/**
 * Appelle le microservice Python, puis persiste chaque ligne dans
 * ai_lineup_recommendations (colonnes: match_id, player_id, presence_score,
 * performance_score, fatigue_score, score, recommended_status).
 */
export async function fetchAiLineupRecommendations(
  matchId: number,
  players: LineupServicePlayerInput[]
): Promise<LineupServiceResponse> {
  const response = await fetch(`${env.LINEUP_SERVICE_URL}/api/v1/lineup/recommendations`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ matchId, players }),
    // Timeout court: c'est un appel synchrone dans une requête HTTP du
    // backend principal, pas un job asynchrone — ne doit jamais bloquer
    // longtemps l'utilisateur qui a cliqué "générer les recommandations".
    signal: AbortSignal.timeout(5000),
  });

  if (!response.ok) {
    throw new Error(`lineup-recommendation-service returned ${response.status}`);
  }
  return response.json() as Promise<LineupServiceResponse>;
}
