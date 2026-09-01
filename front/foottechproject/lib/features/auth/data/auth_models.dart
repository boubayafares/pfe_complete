class AuthUser {
  const AuthUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.role,
    required this.accountStatus,
    this.teamId,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      role: json['role'] as String,
      accountStatus: json['accountStatus'] as String,
      teamId: json['teamId'] as int?,
    );
  }

  final int id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String role; // COACH | ADJOINT | JOUEUR
  final String accountStatus;
  final int? teamId;

  String get fullName => '$firstName $lastName';
  bool get isCoach => role == 'COACH';
  bool get isAdjoint => role == 'ADJOINT';
  bool get isJoueur => role == 'JOUEUR';
  bool get canManageTeam => isCoach || isAdjoint;
}
