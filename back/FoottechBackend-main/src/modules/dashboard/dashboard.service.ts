import { DashboardRepository } from './dashboard.repository.js';
import { BadRequestError } from '../../shared/errors/AppError.js';

export class DashboardService {
  private readonly repo = new DashboardRepository();

  async getCoachDashboard(coachId: number, teamId: number) {
    const [upcomingTraining, upcomingMatch, pendingProposals, unreadNotifications, playerCount] = await Promise.all([
      this.repo.getUpcomingTraining(teamId),
      this.repo.getUpcomingMatch(teamId),
      this.repo.getPendingProposalsCount(coachId),
      this.repo.getUnreadNotificationCount(coachId),
      this.repo.getTeamPlayerCount(teamId),
    ]);
    return { upcomingTraining, upcomingMatch, pendingProposals, unreadNotifications, playerCount };
  }

  async getAdjointDashboard(adjointId: number, teamId: number) {
    const [upcomingTraining, upcomingMatch, unreadNotifications, playerCount] = await Promise.all([
      this.repo.getUpcomingTraining(teamId),
      this.repo.getUpcomingMatch(teamId),
      this.repo.getUnreadNotificationCount(adjointId),
      this.repo.getTeamPlayerCount(teamId),
    ]);
    return { upcomingTraining, upcomingMatch, unreadNotifications, playerCount };
  }

  async getPlayerDashboard(playerId: number, teamId: number) {
    const [upcomingTraining, upcomingMatch, unreadNotifications] = await Promise.all([
      this.repo.getUpcomingTraining(teamId),
      this.repo.getUpcomingMatch(teamId),
      this.repo.getUnreadNotificationCount(playerId),
    ]);
    const nextMatchSelectionStatus = upcomingMatch
      ? await this.repo.getPlayerNextMatchStatus(playerId, (upcomingMatch as { id: number }).id)
      : null;
    return { upcomingTraining, upcomingMatch, unreadNotifications, nextMatchSelectionStatus };
  }

  async getDashboard(userId: number, role: 'COACH' | 'ADJOINT' | 'JOUEUR', teamId: number | null) {
    if (!teamId) throw new BadRequestError('No team associated with this account yet');
    if (role === 'COACH') return this.getCoachDashboard(userId, teamId);
    if (role === 'ADJOINT') return this.getAdjointDashboard(userId, teamId);
    return this.getPlayerDashboard(userId, teamId);
  }

  async getSeasonBilan(teamId: number, seasonId?: number) {
    return this.repo.getSeasonBilan(teamId, seasonId);
  }
}
