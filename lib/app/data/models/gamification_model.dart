class BadgeModel {
  final String code;
  final String name;
  final String description;
  final String earnedAt;

  const BadgeModel({
    required this.code,
    required this.name,
    required this.description,
    required this.earnedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> j) => BadgeModel(
        code: j['code'] as String,
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
        earnedAt: j['earnedAt'] as String? ?? '',
      );

  String get emoji {
    switch (code) {
      case 'PREMIER_SIGNALEMENT':
        return '🌟';
      case 'CHASSEUR_ABUS':
        return '🔍';
      case 'REPORTER_REGULIER':
        return '📢';
      case 'HEROS_QUARTIER':
        return '🦸';
      default:
        return '🏅';
    }
  }
}

class GamificationModel {
  final int points;
  final int level;
  final List<BadgeModel> badges;

  const GamificationModel({
    required this.points,
    required this.level,
    required this.badges,
  });

  factory GamificationModel.fromJson(Map<String, dynamic> j) =>
      GamificationModel(
        points: (j['points'] as num?)?.toInt() ?? 0,
        level: (j['level'] as num?)?.toInt() ?? 1,
        badges: (j['badges'] as List? ?? [])
            .map((b) => BadgeModel.fromJson(b as Map<String, dynamic>))
            .toList(),
      );
}
