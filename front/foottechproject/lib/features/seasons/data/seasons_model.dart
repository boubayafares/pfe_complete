class Season {
  const Season({
    required this.id,
    required this.teamId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'] as int,
      teamId: json['team_id'] as int?,
      name: json['name'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isCurrent: json['is_current'] as bool? ?? false,
    );
  }

  final int id;
  /// Null only for legacy shared seasons, which the backend exposes read-only.
  final int? teamId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;
}
