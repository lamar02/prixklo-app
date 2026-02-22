class PackagingModel {
  final String id;
  final String label;

  const PackagingModel({required this.id, required this.label});

  factory PackagingModel.fromJson(Map<String, dynamic> j) => PackagingModel(
        id: j['id'] as String,
        label: j['label'] as String,
      );
}

class ProductModel {
  final String id;
  final String name;
  final String category;
  final List<PackagingModel> packagings;

  const ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.packagings,
  });

  factory ProductModel.fromJson(Map<String, dynamic> j) => ProductModel(
        id: j['id'] as String,
        name: j['name'] as String,
        category: j['category'] as String,
        packagings: (j['packagings'] as List? ?? [])
            .map((p) => PackagingModel.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}
