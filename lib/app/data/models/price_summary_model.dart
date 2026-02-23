class PriceSummaryModel {
  final double? officialMaxPrice;
  final int count;
  final double? avg;
  final double? min;
  final double? max;
  final Map<String, int> statusBreakdown;
  final String? dominantStatus;
  final int radiusKm;

  const PriceSummaryModel({
    required this.officialMaxPrice,
    required this.count,
    required this.avg,
    required this.min,
    required this.max,
    required this.statusBreakdown,
    required this.dominantStatus,
    required this.radiusKm,
  });

  factory PriceSummaryModel.fromJson(Map<String, dynamic> j) {
    final observed = j['observed'] as Map<String, dynamic>? ?? {};
    final rawBreakdown =
        observed['statusBreakdown'] as Map<String, dynamic>? ?? {};
    return PriceSummaryModel(
      officialMaxPrice: (j['officialMaxPrice'] as num?)?.toDouble(),
      count: (observed['count'] as num?)?.toInt() ?? 0,
      avg: (observed['avg'] as num?)?.toDouble(),
      min: (observed['min'] as num?)?.toDouble(),
      max: (observed['max'] as num?)?.toDouble(),
      statusBreakdown:
          rawBreakdown.map((k, v) => MapEntry(k, (v as num).toInt())),
      dominantStatus: j['dominantStatus'] as String?,
      radiusKm: (j['radiusKm'] as num?)?.toInt() ?? 5,
    );
  }
}
