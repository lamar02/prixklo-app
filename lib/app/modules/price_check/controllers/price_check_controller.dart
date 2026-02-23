import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../../data/models/official_price_model.dart';
import '../../../data/models/price_history_model.dart';
import '../../../data/models/price_summary_model.dart';
import '../../../data/models/product_model.dart';
import '../../../modules/home/controllers/home_controller.dart';
import '../../../modules/main_nav/controllers/main_nav_controller.dart';
import '../../../modules/report/controllers/report_controller.dart';
import '../../../services/api_service.dart';

class PriceCheckController extends GetxController {
  final _api = Get.find<ApiService>();

  // ── Catalogue ─────────────────────────────────────────────
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxString searchQuery = ''.obs;
  final Rx<ProductModel?> selectedProduct = Rx<ProductModel?>(null);
  final Rx<PackagingModel?> selectedPackaging = Rx<PackagingModel?>(null);
  final RxBool productsLoading = false.obs;

  List<ProductModel> get filteredProducts {
    final q = searchQuery.value.toLowerCase();
    if (q.isEmpty) return products;
    return products
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q))
        .toList();
  }

  // ── GPS ───────────────────────────────────────────────────
  final RxDouble lat = 0.0.obs;
  final RxDouble lng = 0.0.obs;
  final RxBool hasLocation = false.obs;
  final RxBool isLocating = false.obs;

  // ── Prix observé par l'utilisateur ───────────────────────
  final observedPriceCtrl = TextEditingController();
  final RxDouble observedPrice = 0.0.obs;

  // ── Prix plafond officiel (immédiat, sans GPS) ────────────
  /// Cherche le plafond officiel dans les prix déjà chargés par HomeController.
  OfficialPriceModel? get officialPrice {
    final pkg = selectedPackaging.value;
    if (pkg == null) return null;
    try {
      final home = Get.find<HomeController>();
      return home.officialPrices.firstWhere((p) => p.packagingId == pkg.id);
    } catch (_) {
      return null;
    }
  }

  /// Prix plafond à utiliser : officialPrices en priorité, sinon priceSummary.
  double? get effectiveMaxPrice =>
      officialPrice?.maxPrice ?? priceSummary.value?.officialMaxPrice;

  // ── Résumé des prix communautaires (GPS requis) ───────────
  final Rx<PriceSummaryModel?> priceSummary = Rx<PriceSummaryModel?>(null);
  final RxBool loadingSummary = false.obs;

  // ── Historique hebdomadaire (GPS requis) ──────────────────
  final RxList<PriceHistoryEntry> priceHistory = <PriceHistoryEntry>[].obs;
  final RxBool loadingHistory = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadProducts();
    _locateUser();
    ever(selectedPackaging, (_) {
      priceSummary.value = null;
      priceHistory.value = [];
      _fetchSummaryIfReady();
      _fetchHistoryIfReady();
    });
    ever(hasLocation, (_) {
      _fetchSummaryIfReady();
      _fetchHistoryIfReady();
    });
  }

  Future<void> _loadProducts() async {
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

  Future<void> _locateUser() async {
    isLocating.value = true;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      lat.value = pos.latitude;
      lng.value = pos.longitude;
      hasLocation.value = true;
    } catch (_) {
      // Échec silencieux — le résumé de prix ne s'affichera pas
    } finally {
      isLocating.value = false;
    }
  }

  void selectProduct(ProductModel product) {
    selectedProduct.value = product;
    selectedPackaging.value = null;
    priceSummary.value = null;
    priceHistory.value = [];
    observedPrice.value = 0;
    observedPriceCtrl.clear();
  }

  void clearSelection() {
    selectedProduct.value = null;
    selectedPackaging.value = null;
    priceSummary.value = null;
    priceHistory.value = [];
    observedPrice.value = 0;
    observedPriceCtrl.clear();
  }

  void selectPackaging(PackagingModel packaging) {
    selectedPackaging.value = packaging;
  }

  void _fetchSummaryIfReady() {
    if (hasLocation.value && selectedPackaging.value != null) {
      _fetchPriceSummary();
    }
  }

  void _fetchHistoryIfReady() {
    if (hasLocation.value && selectedPackaging.value != null) {
      _fetchPriceHistory();
    }
  }

  Future<void> _fetchPriceSummary() async {
    final pkg = selectedPackaging.value;
    if (pkg == null || !hasLocation.value) return;
    loadingSummary.value = true;
    try {
      final res = await _api.getPriceSummary(
        packagingId: pkg.id,
        lat: lat.value,
        lng: lng.value,
      );
      if (res.isOk) {
        priceSummary.value =
            PriceSummaryModel.fromJson(res.body as Map<String, dynamic>);
      }
    } finally {
      loadingSummary.value = false;
    }
  }

  Future<void> _fetchPriceHistory() async {
    final pkg = selectedPackaging.value;
    if (pkg == null || !hasLocation.value) return;
    loadingHistory.value = true;
    try {
      final res = await _api.getPriceHistory(
        packagingId: pkg.id,
        lat: lat.value,
        lng: lng.value,
      );
      if (res.isOk) {
        final list = (res.body['history'] as List?) ?? [];
        priceHistory.value = list
            .map((e) => PriceHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } finally {
      loadingHistory.value = false;
    }
  }

  /// Pré-remplit le wizard et bascule sur l'onglet Signaler.
  /// Si un prix observé est saisi, le wizard saute directement à l'étape GPS/Envoi.
  void launchReport({required String type}) {
    final product = selectedProduct.value;
    final packaging = selectedPackaging.value;
    if (product == null || packaging == null) return;
    Get.find<ReportController>().preSelect(
      product,
      packaging,
      type: type,
      observedPrice: observedPrice.value > 0 ? observedPrice.value : null,
    );
    Get.find<MainNavController>().goToReport();
    Get.back();
  }

  @override
  void onClose() {
    observedPriceCtrl.dispose();
    super.onClose();
  }
}
