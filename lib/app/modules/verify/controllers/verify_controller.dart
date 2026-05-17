import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/controllers/app_data_controller.dart';
import '../../../core/utils/connectivity_util.dart';
import '../../../data/models/gamification_model.dart';
import '../../../data/models/official_price_model.dart';
import '../../../data/models/price_summary_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/report_model.dart';
import '../../../data/providers/offline_queue_model.dart';
import '../../../modules/auth/controllers/auth_controller.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';

class VerifyController extends GetxController {
  final _api = Get.find<ApiService>();
  final _storage = Get.find<StorageService>();

  // ── Navigation interne ────────────────────────────────────
  // 0 = recherche produit, 1 = sélection packaging, 2 = saisie prix + verdict
  final RxInt currentScreen = 0.obs;

  // ── Produit / Packaging ───────────────────────────────────
  final RxString searchQuery = ''.obs;
  final Rx<ProductModel?> selectedProduct = Rx<ProductModel?>(null);
  final Rx<PackagingModel?> selectedPackaging = Rx<PackagingModel?>(null);

  // ── GPS ───────────────────────────────────────────────────
  final RxDouble lat = 0.0.obs;
  final RxDouble lng = 0.0.obs;
  final RxBool hasLocation = false.obs;
  final RxBool isLocating = false.obs;

  // ── Prix ──────────────────────────────────────────────────
  final RxDouble observedPrice = 0.0.obs;

  // ── Mini-flux post-verdict ────────────────────────────────
  final RxString shopName = ''.obs;
  final Rx<File?> photo = Rx<File?>(null);

  // ── Résumé communautaire (auto-type SIGNALEMENT/CONFIRMATION) ─
  final Rx<PriceSummaryModel?> priceSummary = Rx<PriceSummaryModel?>(null);
  final RxBool loadingSummary = false.obs;

  // ── Résultat soumission ───────────────────────────────────
  final Rx<ReportModel?> submissionResult = Rx<ReportModel?>(null);
  final RxBool isSubmitting = false.obs;

  // ── Getters vers AppDataController (réactifs via Obx) ────
  RxList<ProductModel> get _allProducts => Get.find<AppDataController>().products;
  RxBool get productsLoading => Get.find<AppDataController>().productsLoading;

  List<ProductModel> get filteredProducts {
    final q = searchQuery.value.toLowerCase();
    if (q.isEmpty) return _allProducts;
    return _allProducts
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q))
        .toList();
  }

  OfficialPriceModel? get officialPrice {
    final pkg = selectedPackaging.value;
    if (pkg == null) return null;
    try {
      return Get.find<AppDataController>()
          .officialPrices
          .firstWhere((p) => p.packagingId == pkg.id);
    } catch (_) {
      return null;
    }
  }

  double? get effectiveMaxPrice =>
      officialPrice?.maxPrice ?? priceSummary.value?.officialMaxPrice;

  /// Verdict local (avant soumission) — binaire : ABUS ou CONFORME.
  /// Le serveur détermine LIMITE vs ABUS à la soumission.
  String? get localVerdict {
    final price = observedPrice.value;
    final max = effectiveMaxPrice;
    if (price <= 0 || max == null || max <= 0) return null;
    return price > max ? 'ABUS' : 'CONFORME';
  }

  String get reportType =>
      (priceSummary.value?.count ?? 0) > 0 ? 'CONFIRMATION' : 'SIGNALEMENT';

  @override
  void onInit() {
    super.onInit();
    ever(selectedPackaging, (_) {
      priceSummary.value = null;
      if (hasLocation.value && selectedPackaging.value != null) {
        _fetchPriceSummary();
      }
    });
    ever(hasLocation, (_) {
      if (hasLocation.value && selectedPackaging.value != null) {
        _fetchPriceSummary();
      }
    });
  }

  // ── Navigation ────────────────────────────────────────────

  void selectProduct(ProductModel product) {
    selectedProduct.value = product;
    selectedPackaging.value = null;
    observedPrice.value = 0;
    photo.value = null;
    shopName.value = '';
    submissionResult.value = null;
    priceSummary.value = null;
    if (!hasLocation.value && !isLocating.value) locateUser();
    currentScreen.value = 1;
  }

  void selectPackaging(PackagingModel packaging) {
    selectedPackaging.value = packaging;
  }

  void goToScreen(int screen) => currentScreen.value = screen;

  void goBack() {
    if (currentScreen.value > 0) currentScreen.value--;
  }

  /// Pré-remplit depuis un marqueur carte et saute à l'écran prix.
  void preSelect(ProductModel product, PackagingModel packaging) {
    resetFlow();
    selectedProduct.value = product;
    selectedPackaging.value = packaging;
    if (!hasLocation.value && !isLocating.value) locateUser();
    currentScreen.value = 2;
  }

  // ── GPS ───────────────────────────────────────────────────

  Future<void> locateUser() async {
    isLocating.value = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      lat.value = pos.latitude;
      lng.value = pos.longitude;
      hasLocation.value = true;
    } catch (_) {
    } finally {
      isLocating.value = false;
    }
  }

  // ── Résumé communautaire ──────────────────────────────────

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

  // ── Photo ─────────────────────────────────────────────────

  Future<void> pickPhoto() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) photo.value = File(picked.path);
  }

  Future<void> takePhoto() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 75);
    if (picked != null) photo.value = File(picked.path);
  }

  // ── Soumission ────────────────────────────────────────────

  Future<void> submitReport() async {
    if (selectedPackaging.value == null || observedPrice.value <= 0) return;
    isSubmitting.value = true;
    final online = await ConnectivityUtil.isOnline();

    if (!online) {
      await _enqueueOffline();
      isSubmitting.value = false;
      Get.snackbar(
        'Hors ligne',
        'Signalement sauvegardé. Il sera envoyé dès la reconnexion.',
        snackPosition: SnackPosition.BOTTOM,
      );
      resetFlow();
      return;
    }

    try {
      final shop = shopName.value.trim();
      final fields = {
        'packagingId': selectedPackaging.value!.id,
        'observedPrice': observedPrice.value.toStringAsFixed(0),
        'type': reportType,
        if (hasLocation.value) 'lat': lat.value.toString(),
        if (hasLocation.value) 'lng': lng.value.toString(),
        if (shop.isNotEmpty) 'shopName': shop,
      };

      Response res;
      if (photo.value != null) {
        res = await _api.createReportWithPhoto(fields, photo.value!.path);
      } else {
        res = await _api.createReport({
          'packagingId': selectedPackaging.value!.id,
          'observedPrice': observedPrice.value,
          'type': reportType,
          if (hasLocation.value) 'lat': lat.value,
          if (hasLocation.value) 'lng': lng.value,
          if (shop.isNotEmpty) 'shopName': shop,
        });
      }

      if (res.statusCode == 201) {
        final report =
            ReportModel.fromJson(res.body['report'] as Map<String, dynamic>);
        submissionResult.value = report;
        _refreshUserPoints();
        flushOfflineQueue();
      } else {
        Get.snackbar('Erreur', 'Envoi échoué. Réessayez.',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (_) {
      Get.snackbar('Erreur', 'Problème de connexion. Réessayez.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> _enqueueOffline() async {
    final pending = PendingReport(
      packagingId: selectedPackaging.value!.id,
      observedPrice: observedPrice.value,
      lat: hasLocation.value ? lat.value : null,
      lng: hasLocation.value ? lng.value : null,
      shopName: shopName.value.trim().isNotEmpty ? shopName.value.trim() : null,
      queuedAt: DateTime.now(),
    );
    final list = List<String>.from(_storage.pendingReports)
      ..add(pending.toEncodedString());
    await _storage.savePendingReports(list);
  }

  Future<void> flushOfflineQueue() async {
    final list = _storage.pendingReports;
    if (list.isEmpty) return;
    final remaining = <String>[];
    for (final item in list) {
      try {
        final pending = PendingReport.fromString(item);
        final res = await _api.createReport({
          'packagingId': pending.packagingId,
          'observedPrice': pending.observedPrice,
          if (pending.lat != null) 'lat': pending.lat,
          if (pending.lng != null) 'lng': pending.lng,
          if (pending.shopName != null) 'shopName': pending.shopName,
        });
        if (res.statusCode != 201) remaining.add(item);
      } catch (_) {
        remaining.add(item);
      }
    }
    await _storage.savePendingReports(remaining);
    if (remaining.length < list.length) {
      Get.snackbar(
        'Signalements envoyés',
        '${list.length - remaining.length} signalement(s) envoyé(s) avec succès.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _refreshUserPoints() async {
    final res = await _api.getGamification();
    if (res.isOk) {
      final g = GamificationModel.fromJson(res.body as Map<String, dynamic>);
      Get.find<AuthController>().updatePoints(g.points, g.level);
    }
  }

  void resetFlow() {
    currentScreen.value = 0;
    selectedProduct.value = null;
    selectedPackaging.value = null;
    observedPrice.value = 0;
    photo.value = null;
    shopName.value = '';
    submissionResult.value = null;
    priceSummary.value = null;
    searchQuery.value = '';
    hasLocation.value = false;
    lat.value = 0;
    lng.value = 0;
  }
}
