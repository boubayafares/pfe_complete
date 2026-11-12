import { BadRequestError } from '../../shared/errors/AppError.js';
import { analyzeCommentTone, clusterPlayers, detectPlayerTrend } from '../../shared/clients/ai-insights.client.js';
import { AiInsightsRepository } from './ai-insights.repository.js';

export class AiInsightsService {
  private readonly repo = new AiInsightsRepository();

  async getPlayerTrend(playerId: number) {
    const points = await this.repo.getPlayerTrendPoints(playerId);
    if (points.length < 3) {
      throw new BadRequestError('At least three player evaluations are required to calculate a meaningful trend');
    }
    return detectPlayerTrend({ playerId, points });
  }

  async getTeamClusters(teamId: number, nClusters: number) {
    const players = await this.repo.getTeamClusterFeatures(teamId);
    if (players.length < 4) {
      throw new BadRequestError('At least four players are required for clustering');
    }
    if (nClusters > players.length) {
      throw new BadRequestError('nClusters cannot exceed the number of players');
    }
    return clusterPlayers({ players, nClusters });
  }

  analyzeTone(comment: string) {
    return analyzeCommentTone(comment);
  }

  async getExpertProjectModel(teamId: number) {
    const signals = await this.repo.getProjectSignals(teamId);
    const maturityScore = Math.min(100, Math.round(
      signals.players * 8
      + signals.staff * 6
      + signals.trainings * 5
      + signals.matches * 5
      + signals.exercises * 4
      + signals.drawings * 6
      + signals.attendanceRows * 2
      + signals.evaluations * 3
      + signals.notifications
    ));

    return {
      name: 'FootTech Expert Coach AI v1',
      modelType: 'hybrid_rule_based_and_microservice_ai',
      maturityScore,
      signals,
      capabilities: [
        {
          id: 'TACTICAL_EDITOR',
          label: 'Editeur tactique 2D/3D',
          status: signals.drawings > 0 ? 'ACTIVE' : 'READY',
          decisionLogic: 'Canvas JSON + timeline animation + export PDF',
        },
        {
          id: 'LINEUP_RECOMMENDATION',
          label: 'Composition tactique',
          status: signals.matches > 0 && signals.players > 0 ? 'ACTIVE' : 'NEEDS_DATA',
          decisionLogic: 'Presence recente, note moyenne, charge de match et fatigue',
        },
        {
          id: 'TRAINING_LIBRARY',
          label: 'Bibliotheque communautaire',
          status: signals.exercises > 0 ? 'ACTIVE' : 'READY',
          decisionLogic: 'Classification par objectif, difficulte, duree, tags et dessin',
        },
        {
          id: 'COMMUNICATION',
          label: 'Courriel/SMS/convocations',
          status: signals.notifications > 0 ? 'ACTIVE' : 'READY',
          decisionLogic: 'Ciblage equipe, role, evenement et historique de lecture',
        },
        {
          id: 'PERFORMANCE_ANALYTICS',
          label: 'Statistiques et evaluations',
          status: signals.evaluations >= 3 ? 'ACTIVE' : 'NEEDS_DATA',
          decisionLogic: 'Tendances, notes, temps de jeu et bilans saison',
        },
      ],
      recommendations: [
        signals.players < 11 ? 'Completer l effectif pour fiabiliser la composition tactique.' : 'Effectif suffisant pour travailler les animations collectives.',
        signals.evaluations < 3 ? 'Ajouter au moins trois evaluations par joueur pour activer les tendances IA.' : 'Les tendances IA peuvent alimenter les choix de match.',
        signals.drawings === 0 ? 'Créer des dessins tactiques pour enrichir les fiches et exports.' : 'Les dessins disponibles peuvent etre reutilises dans la bibliotheque.',
      ],
      explainability: [
        'Le score de maturite combine volume de donnees, richesse tactique et communication.',
        'Chaque recommandation reste traçable vers des signaux metiers simples.',
        'Les microservices IA restent proteges derriere Express et ne sont jamais appeles directement par Flutter.',
      ],
    };
  }
}
