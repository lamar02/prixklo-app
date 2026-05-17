import 'dart:convert';
import 'package:get/get.dart';
import '../../data/models/bulletin_model.dart';
import '../../data/models/official_price_model.dart';
import '../../data/models/product_model.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';

/// Singleton permanent — source de vérité pour les prix officiels et le catalogue.
/// Remplace HomeController comme fournisseur de officialPrices et products.
class AppDataController extends GetxController {
  final _api = Get.find<ApiService>();
  final _storage = Get.find<StorageService>();

  final RxList<OfficialPriceModel> officialPrices = <OfficialPriceModel>[].obs;
  final Rx<BulletinModel?> activeBulletin = Rx<BulletinModel?>(null);
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxBool productsLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
    fetchBulletinAndPrices();
  }

  Future<void> fetchProducts() async {
    productsLoading.value = true;
    try {
      final res = await _api.getProducts();
      if (res.isOk) {
        products.value = (res.body['products'] as List)
            .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
            .toList();
      }
    } finally {
      productsLoading.value = false;
    }
  }

  Future<void> fetchBulletinAndPrices() async {
    try {
      final bulletinRes = await _api.getActiveBulletin();
      if (bulletinRes.isOk) {
        final bData = bulletinRes.body['bulletin'] as Map<String, dynamic>?;
        if (bData != null) activeBulletin.value = BulletinModel.fromJson(bData);
      }

      final currentId = activeBulletin.value?.id;
      if (currentId != null && _storage.cachedBulletinId == currentId) {
        _loadPricesFromCache();
        return;
      }

      final pricesRes = await _api.getActivePrices();
      if (pricesRes.isOk) {
        final list = (pricesRes.body['prices'] as List)
            .map((p) => OfficialPriceModel.fromJson(p as Map<String, dynamic>))
            .toList();
        officialPrices.value = list;
        if (currentId != null) {
          await _storage.cacheBulletinId(currentId);
          await _storage.cacheOfficialPrices(
            jsonEncode(list.map((p) => p.toJson()).toList()),
          );
        }
      } else {
        _loadPricesFromCache();
      }
    } catch (_) {
      _loadPricesFromCache();
    }
  }

  void _loadPricesFromCache() {
    final cached = _storage.cachedOfficialPricesJson;
    if (cached == null) return;
    try {
      officialPrices.value = (jsonDecode(cached) as List)
          .map((p) => OfficialPriceModel.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (_) {}
  }
}
