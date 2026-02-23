class ReportModel {
  final String id;
  final String status; // 'ABUS' | 'CONFORME' | 'UNKNOWN'
  final double observedPrice;
  final double? maxPrice;
  final String? photoUrl;
  final String createdAt;
  final String packagingLabel;
  final String productName;
  final String? shopName;

  const ReportModel({
    required this.id,
    required this.status,
    required this.observedPrice,
    this.maxPrice,
    this.photoUrl,
    required this.createdAt,
    required this.packagingLabel,
    required this.productName,
    this.shopName,
  });

  factory ReportModel.fromJson(Map<String, dynamic> j) {
    final packaging = j['packaging'] as Map<String, dynamic>? ?? {};
    final product = packaging['product'] as Map<String, dynamic>? ?? {};
    return ReportModel(
      id: j['id'] as String,
      status: j['status'] as String? ?? 'UNKNOWN',
      observedPrice: (j['observedPrice'] as num?)?.toDouble() ?? 0,
      maxPrice: (j['maxPrice'] as num?)?.toDouble(),
      photoUrl: j['photoUrl'] as String?,
      createdAt: j['createdAt'] as String? ?? '',
      packagingLabel: packaging['label'] as String? ?? '',
      productName: product['name'] as String? ?? '',
      shopName: j['shopName'] as String?,
    );
  }
}
