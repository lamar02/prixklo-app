class BulletinModel {
  final String id;
  final String title;
  final int periodMonth;
  final int periodYear;
  final bool isActive;

  const BulletinModel({
    required this.id,
    required this.title,
    required this.periodMonth,
    required this.periodYear,
    required this.isActive,
  });

  factory BulletinModel.fromJson(Map<String, dynamic> j) => BulletinModel(
        id: j['id'] as String,
        title: j['title'] as String,
        periodMonth: (j['periodMonth'] as num).toInt(),
        periodYear: (j['periodYear'] as num).toInt(),
        isActive: j['isActive'] as bool? ?? false,
      );
}
