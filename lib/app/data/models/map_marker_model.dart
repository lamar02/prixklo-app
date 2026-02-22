class MapMarkerModel {
  final String id;
  final double lat;
  final double lng;
  final String status; // 'ABUS' | 'CONFORME' | 'UNKNOWN'
  final String productName;
  final String packagingLabel;
  final double observedPrice;
  final double maxPrice;
  final String createdAt;

  const MapMarkerModel({
    required this.id,
    required this.lat,
    required this.lng,
    required this.status,
    required this.productName,
    required this.packagingLabel,
    required this.observedPrice,
    required this.maxPrice,
    required this.createdAt,
  });

  factory MapMarkerModel.fromJson(Map<String, dynamic> j) => MapMarkerModel(
        id: j['id'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        status: j['status'] as String? ?? 'UNKNOWN',
        productName: j['productName'] as String? ?? '',
        packagingLabel: j['packagingLabel'] as String? ?? '',
        observedPrice: (j['observedPrice'] as num?)?.toDouble() ?? 0,
        maxPrice: (j['maxPrice'] as num?)?.toDouble() ?? 0,
        createdAt: j['createdAt'] as String? ?? '',
      );
}
