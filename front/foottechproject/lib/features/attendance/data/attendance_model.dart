class AttendanceRecord {
  const AttendanceRecord({
    required this.playerId,
    required this.status,
    required this.firstName,
    required this.lastName,
    this.numeroMaillot,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      playerId: json['player_id'] as int,
      status: json['status'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      numeroMaillot: json['numero_maillot'] as int?,
    );
  }

  final int playerId;
  final String status; // PRESENT | ABSENT | LATE | INJURED
  final String firstName;
  final String lastName;
  final int? numeroMaillot;

  String get fullName => '$firstName $lastName';
}
