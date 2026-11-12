import { MatchesRepository } from './matches.repository.js';
import type{ CreateMatchDto, SetLineupDto, CreateMatchEventDto, UpsertPlayerStatDto, UpsertEvaluationDto } from './matches.dto.js';
import { NotFoundError, ForbiddenError } from '../../shared/errors/AppError.js';
import { generateMatchReportPdf } from '../../shared/services/report.service.js';
import { fetchLineUpRecommendations } from '../../shared/clients/lineup.client.js';
import { SeasonsRepository } from '../seasons/seasons.repository.js';

export class MatchesService {
  private readonly repo = new MatchesRepository();
  private readonly seasonsRepo = new SeasonsRepository();

  async list(filters?: { teamId?: number; seasonId?: number; status?: string }) {
    return this.repo.findWithFilters(filters ?? {});
  }

  async getById(id: number) {
    const match = await this.repo.findById(id);
    if (!match) throw new NotFoundError('Match');
    return match;
  }

  async create(dto: CreateMatchDto, teamId?: number) {
    if (!teamId) throw new ForbiddenError('User is not assigned to a team');
    if (dto.seasonId !== undefined && !(await this.seasonsRepo.isAccessible(dto.seasonId, teamId))) {
      throw new ForbiddenError('The selected season is not available to this team');
    }
    return this.repo.create({
      team_id: teamId,
      season_id: dto.seasonId ?? null,
      adversaire: dto.adversaire,
      date_heure: dto.dateHeure,
      lieu: dto.lieu ?? null,
      is_home: dto.isHome ?? true,
      formation: dto.formation ?? null,
    });
  }

  async updateStatus(id: number, status: string) {
    const existing = await this.repo.findById(id);
    if (!existing) throw new NotFoundError('Match');
    return this.repo.updateStatus(id, status);
  }

  async remove(id: number) {
    const deleted = await this.repo.delete(id);
    if (!deleted) throw new NotFoundError('Match');
  }

  private async assertMatchExists(id: number) {
    const match = await this.repo.findById(id);
    if (!match) throw new NotFoundError('Match');
    return match;
  }

  private async assertPlayersBelongToMatchTeam(matchId: number, playerIds: Array<number | undefined>) {
    const ids = playerIds.filter((id): id is number => id !== undefined);
    if (!(await this.repo.playersBelongToMatchTeam(matchId, ids))) {
      throw new ForbiddenError('Every selected player must belong to the match team');
    }
  }

  // --- Lineup ---

  async setLineup(matchId: number, dto: SetLineupDto, selectedBy: number) {
    await this.assertMatchExists(matchId);
    await this.assertPlayersBelongToMatchTeam(matchId, dto.entries.map((entry) => entry.playerId));
    return this.repo.setLineup(matchId, dto.entries, selectedBy);
  }

  async getLineup(matchId: number) {
    await this.assertMatchExists(matchId);
    return this.repo.getLineup(matchId);
  }

  // --- AI recommendations ---

  async generateRecommendations(matchId: number, playerIds?: number[]) {
    const match = await this.assertMatchExists(matchId);

    // Le scoring habite dans lineup-recommendation-service (FastAPI) — seule
    // source de vérité. Express assemble les features puis persiste le résultat.
    const players = await this.repo.getLineUpFeatures(matchId, match.team_id, playerIds);
    const result = await fetchLineUpRecommendations({ matchId, players });
    return this.repo.storeLineUpRecommendations(matchId, result.recommendations);
  }

  async getRecommendations(matchId: number) {
    await this.assertMatchExists(matchId);
    return this.repo.listRecommendations(matchId);
  }

  // --- Live events ---

  async createEvent(matchId: number, dto: CreateMatchEventDto, createdBy: number) {
    await this.assertMatchExists(matchId);
    await this.assertPlayersBelongToMatchTeam(matchId, [dto.playerId, dto.relatedPlayerId]);
    return this.repo.createEvent(matchId, {
      event_type: dto.eventType,
      minute: dto.minute,
      player_id: dto.playerId,
      related_player_id: dto.relatedPlayerId,
      comment: dto.comment,
      created_by: createdBy,
    });
  }

  async listEvents(matchId: number) {
    await this.assertMatchExists(matchId);
    return this.repo.listEvents(matchId);
  }

  // --- Player stats ---

  async upsertPlayerStat(matchId: number, dto: UpsertPlayerStatDto) {
    await this.assertMatchExists(matchId);
    await this.assertPlayersBelongToMatchTeam(matchId, [dto.playerId]);
    return this.repo.upsertPlayerStat(matchId, {
      player_id: dto.playerId,
      minutes_played: dto.minutesPlayed,
      goals: dto.goals,
      assists: dto.assists,
      goals_conceded: dto.goalsConceded,
      yellow_cards: dto.yellowCards,
      red_cards: dto.redCards,
    });
  }

  async listPlayerStats(matchId: number) {
    await this.assertMatchExists(matchId);
    return this.repo.listPlayerStats(matchId);
  }

  // --- Evaluations ---

  async upsertEvaluation(matchId: number, evaluatedBy: number, dto: UpsertEvaluationDto) {
    await this.assertMatchExists(matchId);
    await this.assertPlayersBelongToMatchTeam(matchId, [dto.playerId]);
    return this.repo.upsertEvaluation(matchId, evaluatedBy, {
      player_id: dto.playerId,
      note: dto.note,
      commentaire: dto.commentaire,
    });
  }

  async listEvaluations(matchId: number) {
    await this.assertMatchExists(matchId);
    return this.repo.listEvaluations(matchId);
  }

  // --- Report ---

  async generateReport(matchId: number) {
    await this.assertMatchExists(matchId);
    const data = await this.repo.getReportData(matchId);
    const pdfUrl = await generateMatchReportPdf({
      id: data.match.id,
      adversaire: data.match.adversaire,
      dateHeure: data.match.date_heure,
      lieu: data.match.lieu,
      isHome: data.match.is_home,
      formation: data.match.formation,
      homeScore: data.match.home_score,
      awayScore: data.match.away_score,
      matchStatus: data.match.match_status,
      lineup: data.lineup,
      events: data.events,
      stats: data.stats,
      evaluations: data.evaluations,
    });
    return this.repo.saveReport(matchId, pdfUrl);
  }

  async getReport(matchId: number) {
    await this.assertMatchExists(matchId);
    const report = await this.repo.getReport(matchId);
    if (!report) throw new NotFoundError('Match report');
    return report;
  }
}
