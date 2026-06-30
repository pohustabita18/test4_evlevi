class AppUser {
  final String id;
  final String email;
  final String role;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'Creator',
      createdAt: (data['createdAt'] != null)
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'email': email, 'role': role, 'createdAt': createdAt};
  }
}
