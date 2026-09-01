class UserProfile {
  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    this.profileImage,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      profileImage: json['profile_image'] as String?,
    );
  }

  final int id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String? profileImage;

  String get fullName => '$firstName $lastName';
}
