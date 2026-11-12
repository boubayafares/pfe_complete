class Team {
  const Team({
    required this.id,
    required this.name,
    this.category,
    this.logo,
    this.description,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String?,
      logo: json['logo'] as String?,
      description: json['description'] as String?,
    );
  }

  final int id;
  final String name;
  final String? category;
  final String? logo;
  final String? description;
}

class TeamStaffMember {
  const TeamStaffMember({
    required this.adjointId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    required this.accountStatus,
  });

  factory TeamStaffMember.fromJson(Map<String, dynamic> json) {
    return TeamStaffMember(
      adjointId: json['adjoint_id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      accountStatus: json['account_status'] as String,
    );
  }

  final int adjointId;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String accountStatus;

  String get fullName => '$firstName $lastName';
}
