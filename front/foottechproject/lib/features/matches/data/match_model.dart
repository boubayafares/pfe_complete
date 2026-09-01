class MatchInfo {
  const MatchInfo({
    required this.id,
    required this.teamId,
    required this.adversaire,
    required this.dateHeure,
    this.lieu,
    required this.isHome,
    this.formation,
    required this.homeScore,
    required this.awayScore,
    required this.matchStatus,
  });

  factory MatchInfo.fromJson(Map<String, dynamic> json) {
    return MatchInfo(
      id: json['id'] as int,
      teamId: json['team_id'] as int,
      adversaire: json['adversaire'] as String,
      dateHeure: DateTime.parse(json['date_heure'] as String),
      lieu: json['lieu'] as String?,
      isHome: json['is_home'] as bool,
      formation: json['formation'] as String?,
      homeScore: json['home_score'] as int? ?? 0,
      awayScore: json['away_score'] as int? ?? 0,
      matchStatus: json['match_status'] as String,
    );
  }

  final int id;
  final int teamId;
  final String adversaire;
  final DateTime dateHeure;
  final String? lieu;
  final bool isHome;
  final String? formation;
  final int homeScore;
  final int awayScore;
  final String matchStatus;

  bool get isLive => matchStatus == 'LIVE';

  String get scoreLabel => isHome ? '$homeScore - $awayScore' : '$awayScore - $homeScore';
}

class LineupEntry {
  const LineupEntry({
    required this.playerId,
    required this.status,
    this.positionTerrain,
    required this.firstName,
    required this.lastName,
    this.numeroMaillot,
  });

  factory LineupEntry.fromJson(Map<String, dynamic> json) {
    return LineupEntry(
      playerId: json['player_id'] as int,
      status: json['status'] as String,
      positionTerrain: json['position_terrain'] as String?,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      numeroMaillot: json['numero_maillot'] as int?,
    );
  }

  final int playerId;
  final String status; // STARTER | SUBSTITUTE | NOT_SELECTED
  final String? positionTerrain;
  final String firstName;
  final String lastName;
  final int? numeroMaillot;

  String get fullName => '$firstName $lastName';
}

class AiRecommendation {
  const AiRecommendation({
    required this.playerId,
    this.presenceScore,
    this.performanceScore,
    this.fatigueScore,
    this.finalScore,
    this.recommendedStatus,
  });

  factory AiRecommendation.fromJson(Map<String, dynamic> json) {
    return AiRecommendation(
      playerId: json['player_id'] as int,
      presenceScore: (json['presence_score'] as num?)?.toDouble(),
      performanceScore: (json['performance_score'] as num?)?.toDouble(),
      fatigueScore: (json['fatigue_score'] as num?)?.toDouble(),
      finalScore: (json['final_score'] as num?)?.toDouble(),
      recommendedStatus: json['recommended_status'] as String?,
    );
  }

  final int playerId;
  final double? presenceScore;
  final double? performanceScore;
  final double? fatigueScore;
  final double? finalScore;
  final String? recommendedStatus;
}

class MatchEvent {
  const MatchEvent({required this.eventType, required this.minute, this.playerId, this.comment});

  factory MatchEvent.fromJson(Map<String, dynamic> json) {
    return MatchEvent(
      eventType: json['event_type'] as String,
      minute: json['minute'] as int,
      playerId: json['player_id'] as int?,
      comment: json['comment'] as String?,
    );
  }

  final String eventType;
  final int minute;
  final int? playerId;
  final String? comment;
}
