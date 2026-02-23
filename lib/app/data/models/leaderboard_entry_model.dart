class LeaderboardEntryModel {
  final String id;
  final String name;
  final String email;
  final int points;
  final int level;
  final int? reportCount; // présent uniquement pour period=week/month

  const LeaderboardEntryModel({
    required this.id,
    required this.name,
    required this.email,
    required this.points,
    required this.level,
    this.reportCount,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> j) =>
      LeaderboardEntryModel(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? j['email'] as String? ?? '',
        email: j['email'] as String? ?? '',
        points: (j['points'] as num?)?.toInt() ?? 0,
        level: (j['level'] as num?)?.toInt() ?? 1,
        reportCount: (j['reportCount'] as num?)?.toInt(),
      );
}
