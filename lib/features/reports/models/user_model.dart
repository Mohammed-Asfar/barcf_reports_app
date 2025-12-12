class User {
  final int? id;
  final String username;
  final String role; // 'superadmin', 'admin', 'user'
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? createdByUserId;
  final DateTime? deletedAt;

  User({
    this.id,
    required this.username,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.createdByUserId,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdByUserId': createdByUserId,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      role: map['role'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      createdByUserId: map['createdByUserId'],
      deletedAt:
          map['deletedAt'] != null ? DateTime.parse(map['deletedAt']) : null,
    );
  }
}
