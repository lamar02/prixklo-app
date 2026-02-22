import 'dart:convert';

class PendingReport {
  final String packagingId;
  final double observedPrice;
  final double? lat;
  final double? lng;
  final DateTime queuedAt;

  const PendingReport({
    required this.packagingId,
    required this.observedPrice,
    this.lat,
    this.lng,
    required this.queuedAt,
  });

  Map<String, dynamic> toJson() => {
        'packagingId': packagingId,
        'observedPrice': observedPrice,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'queuedAt': queuedAt.toIso8601String(),
      };

  factory PendingReport.fromJson(Map<String, dynamic> j) => PendingReport(
        packagingId: j['packagingId'] as String,
        observedPrice: (j['observedPrice'] as num).toDouble(),
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        queuedAt: DateTime.parse(j['queuedAt'] as String),
      );

  static PendingReport fromString(String s) =>
      PendingReport.fromJson(jsonDecode(s) as Map<String, dynamic>);

  String toEncodedString() => jsonEncode(toJson());
}
