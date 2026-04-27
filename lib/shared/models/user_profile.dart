class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.phoneNumber,
    required this.profilePhotoUrl,
  });

  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String phoneNumber;
  final String profilePhotoUrl;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      role: json['role'] as String? ?? 'citizen',
      phoneNumber: json['phone_number'] as String? ?? '',
      profilePhotoUrl: json['profile_photo'] as String? ?? '',
    );
  }

  String get fullName {
    final parts = [firstName, lastName].where((part) => part.trim().isNotEmpty);
    return parts.join(' ').trim();
  }
}
