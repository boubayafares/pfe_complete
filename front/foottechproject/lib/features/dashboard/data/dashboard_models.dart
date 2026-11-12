class DashboardData {
  const DashboardData({
    this.upcomingTrainingId,
    this.upcomingTrainingDate,
    this.upcomingTrainingLocation,
    this.upcomingTrainingRosterCount = 0,
    this.upcomingTrainingPresentCount = 0,
    this.upcomingTrainingMarkedCount = 0,
    this.upcomingMatchId,
    this.upcomingMatchAdversaire,
    this.upcomingMatchDate,
    this.pendingProposals,
    required this.unreadNotifications,
    this.playerCount,
    this.nextMatchSelectionStatus,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final training = json['upcomingTraining'] as Map<String, dynamic>?;
    final match = json['upcomingMatch'] as Map<String, dynamic>?;
    return DashboardData(
      upcomingTrainingId: training?['id'] as int?,
      upcomingTrainingDate: training?['date'] as String?,
      upcomingTrainingLocation: training?['location'] as String?,
      upcomingTrainingRosterCount: training?['roster_count'] as int? ?? 0,
      upcomingTrainingPresentCount: training?['present_count'] as int? ?? 0,
      upcomingTrainingMarkedCount: training?['marked_count'] as int? ?? 0,
      upcomingMatchId: match?['id'] as int?,
      upcomingMatchAdversaire: match?['adversaire'] as String?,
      upcomingMatchDate: match?['date_heure'] as String?,
      pendingProposals: json['pendingProposals'] as int?,
      unreadNotifications: json['unreadNotifications'] as int? ?? 0,
      playerCount: json['playerCount'] as int?,
      nextMatchSelectionStatus: json['nextMatchSelectionStatus'] as String?,
    );
  }

  final int? upcomingTrainingId;
  final String? upcomingTrainingDate;
  final String? upcomingTrainingLocation;
  final int upcomingTrainingRosterCount;
  final int upcomingTrainingPresentCount;
  final int upcomingTrainingMarkedCount;
  final int? upcomingMatchId;
  final String? upcomingMatchAdversaire;
  final String? upcomingMatchDate;
  final int? pendingProposals;
  final int unreadNotifications;
  final int? playerCount;
  final String? nextMatchSelectionStatus;
}

class SeasonBilanEntry {
  const SeasonBilanEntry({
    required this.playerId,
    required this.firstName,
    required this.lastName,
    this.postePrincipal,
    required this.nombreMatchsJoues,
    required this.tempsDeJeuMinutes,
    this.moyenneNote,
    required this.totalButs,
    required this.totalPassesDecisives,
    required this.totalButsEncaisses,
  });

  factory SeasonBilanEntry.fromJson(Map<String, dynamic> json) {
    return SeasonBilanEntry(
      playerId: json['player_id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      postePrincipal: json['poste_principal'] as String?,
      nombreMatchsJoues: json['nombre_matchs_joues'] as int? ?? 0,
      tempsDeJeuMinutes: json['temps_de_jeu_minutes'] as int? ?? 0,
      moyenneNote: (json['moyenne_note'] as num?)?.toDouble(),
      totalButs: json['total_buts'] as int? ?? 0,
      totalPassesDecisives: json['total_passes_decisives'] as int? ?? 0,
      totalButsEncaisses: json['total_buts_encaisses'] as int? ?? 0,
    );
  }

  final int playerId;
  final String firstName;
  final String lastName;
  final String? postePrincipal;
  final int nombreMatchsJoues;
  final int tempsDeJeuMinutes;
  final double? moyenneNote;
  final int totalButs;
  final int totalPassesDecisives;
  final int totalButsEncaisses;

  String get fullName => '$firstName $lastName';
}
