class PriceHistoryEntry {
  final String weekStart;
  final double? avg;
  final int count;

  const PriceHistoryEntry({
    required this.weekStart,
    required this.avg,
    required this.count,
  });

  factory PriceHistoryEntry.fromJson(Map<String, dynamic> j) =>
      PriceHistoryEntry(
        weekStart: j['weekStart'] as String,
        avg: (j['avg'] as num?)?.toDouble(),
        count: (j['count'] as num?)?.toInt() ?? 0,
      );
}
