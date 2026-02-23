class MapMarkerModel {
  final String id;
  final double lat;
  final double lng;
  final String status; // 'ABUS' | 'CONFORME' | 'UNKNOWN'
  final String productName;
  final String packagingLabel;
  final String? packagingId;
  final double observedPrice;
  final double maxPrice;
  final String createdAt;
  final String? shopName;

  const MapMarkerModel({
    required this.id,
    required this.lat,
    required this.lng,
    required this.status,
    required this.productName,
    required this.packagingLabel,
    this.packagingId,
    required this.observedPrice,
    required this.maxPrice,
    required this.createdAt,
    this.shopName,
  });

  factory MapMarkerModel.fromJson(Map<String, dynamic> j) => MapMarkerModel(
        id: j['id'] as String,
        lat: (j['lat'] as num?)?.toDouble() ?? 0,
        lng: (j['lng'] as num?)?.toDouble() ?? 0,
        status: j['status'] as String? ?? 'UNKNOWN',
        productName: j['productName'] as String? ?? '',
        packagingLabel: j['packagingLabel'] as String? ?? '',
        packagingId: j['packagingId'] as String?,
        observedPrice: (j['observedPrice'] as num?)?.toDouble() ?? 0,
        maxPrice: (j['maxPrice'] as num?)?.toDouble() ?? 0,
        createdAt: j['createdAt'] as String? ?? '',
        shopName: j['shopName'] as String?,
      );
}
