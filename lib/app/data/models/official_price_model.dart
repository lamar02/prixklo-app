class OfficialPriceModel {
  final String packagingId;
  final String productName;
  final String packagingLabel;
  final double maxPrice;
  final String currency;
  final String zone;

  const OfficialPriceModel({
    required this.packagingId,
    required this.productName,
    required this.packagingLabel,
    required this.maxPrice,
    required this.currency,
    required this.zone,
  });

  factory OfficialPriceModel.fromJson(Map<String, dynamic> j) =>
      OfficialPriceModel(
        packagingId: j['packagingId'] as String,
        productName: j['productName'] as String,
        packagingLabel: j['packagingLabel'] as String,
        maxPrice: (j['maxPrice'] as num).toDouble(),
        currency: j['currency'] as String? ?? 'FCFA',
        zone: j['zone'] as String? ?? 'ABIDJAN_30KM',
      );

  Map<String, dynamic> toJson() => {
        'packagingId': packagingId,
        'productName': productName,
        'packagingLabel': packagingLabel,
        'maxPrice': maxPrice,
        'currency': currency,
        'zone': zone,
      };
}
