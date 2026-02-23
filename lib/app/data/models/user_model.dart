class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final int points;
  final int level;
  final String? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.points,
    required this.level,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] as String? ?? '',
        email: j['email'] as String? ?? '',
        name: j['name'] as String? ?? '',
        role: j['role'] as String? ?? 'CITIZEN',
        points: (j['points'] as num?)?.toInt() ?? 0,
        level: (j['level'] as num?)?.toInt() ?? 1,
        createdAt: j['createdAt'] as String?,
      );

  UserModel copyWith({int? points, int? level}) => UserModel(
        id: id,
        email: email,
        name: name,
        role: role,
        points: points ?? this.points,
        level: level ?? this.level,
        createdAt: createdAt,
      );
}
