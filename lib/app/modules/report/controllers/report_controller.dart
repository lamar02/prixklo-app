import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/connectivity_util.dart';
import '../../../data/models/gamification_model.dart';
import '../../../data/models/official_price_model.dart';
import '../../../data/models/price_history_model.dart';
import '../../../data/models/price_summary_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/report_model.dart';
import '../../../data/providers/offline_queue_model.dart';
import '../../../modules/auth/controllers/auth_controller.dart';
import '../../../modules/home/controllers/home_controller.dart';
import '../../../modules/main_nav/controllers/main_nav_controller.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';

class ReportController extends GetxController {
  final _api = Get.find<ApiService>();
  final _storage = Get.find<StorageService>();

  // ── Étapes ────────────────────────────────────────────────
  final RxInt currentStep = 0.obs;

  // ── Étape 1 : Produit ─────────────────────────────────────
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

  // ── Étape 2 : Prix + photo ────────────────────────────────
  final RxDouble observedPrice = 0.0.obs;
  final Rx<File?> photo = Rx<File?>(null);

  // ── Étape 3 : Localisation + enseigne + type ──────────────
  final RxDouble lat = 0.0.obs;
  final RxDouble lng = 0.0.obs;
  final RxBool hasLocation = false.obs;
  final RxBool isLocating = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxString shopName = ''.obs;
  final RxString reportType = 'SIGNALEMENT'.obs; // 'SIGNALEMENT' | 'CONFIRMATION'

  // ── Prix plafond officiel (sans GPS) ─────────────────────
  OfficialPriceModel? get officialPrice {
    final pkg = selectedPackaging.value;
    if (pkg == null) return null;
    try {
      return Get.find<HomeController>()
          .officialPrices
          .firstWhere((p) => p.packagingId == pkg.id);
    } catch (_) {
      return null;
    }
  }

  double? get effectiveMaxPrice =>
      officialPrice?.maxPrice ?? priceSummary.value?.officialMaxPrice;

  // ── Résumé des prix locaux ────────────────────────────────
  final Rx<PriceSummaryModel?> priceSummary = Rx<PriceSummaryModel?>(null);
  final RxBool loadingSummary = false.obs;
  final RxList<PriceHistoryEntry> priceHistory = <PriceHistoryEntry>[].obs;
  final RxBool loadingHistory = false.obs;

  // ── Résultat ──────────────────────────────────────────────
  final Rx<ReportModel?> submissionResult = Rx<ReportModel?>(null);

  @override
  void onInit() {
    super.onInit();
    _loadProducts();
    flushOfflineQueue();
    // Déclenche le fetch du résumé dès qu'un packaging est sélectionné
    ever(selectedPackaging, (_) {
      priceSummary.value = null;
      priceHistory.value = [];
      if (hasLocation.value && selectedPackaging.value != null) {
        _fetchPriceSummary();
        fetchPriceHistory();
      }
    });
    // Déclenche le fetch si le GPS arrive après la sélection du packaging
    ever(hasLocation, (_) {
      if (hasLocation.value && selectedPackaging.value != null) {
        _fetchPriceSummary();
        fetchPriceHistory();
      }
    });
    // Type auto-déterminé à partir du résumé communautaire
    ever(priceSummary, (_) {
      reportType.value =
          (priceSummary.value?.count ?? 0) > 0 ? 'CONFIRMATION' : 'SIGNALEMENT';
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

  void selectProduct(ProductModel product) {
    selectedProduct.value = product;
    selectedPackaging.value = null;
    // Démarrer le GPS tôt pour avoir le résumé dès le bottom sheet
    if (!hasLocation.value && !isLocating.value) locateUser();
  }

  void selectPackaging(PackagingModel packaging) {
    selectedPackaging.value = packaging;
  }

  /// Passe à l'étape [step]. Lance la localisation silencieusement
  /// quand l'utilisateur entre l'étape 2 (prix) pour que le GPS
  /// soit prêt à l'étape 3 sans bloquer.
  void goToStep(int step) {
    currentStep.value = step;
    if (step == 1 && !hasLocation.value && !isLocating.value) {
      locateUser();
    }
  }

  Future<void> pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked != null) photo.value = File(picked.path);
  }

  Future<void> takePhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );
    if (picked != null) photo.value = File(picked.path);
  }

  Future<void> locateUser() async {
    isLocating.value = true;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar('GPS', 'Le service de localisation est désactivé.',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        Get.snackbar('Localisation',
            'Autorisation refusée. Activez-la dans les réglages.',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      lat.value = pos.latitude;
      lng.value = pos.longitude;
      hasLocation.value = true;
    } catch (e) {
      Get.snackbar('GPS', 'Impossible d\'obtenir la position.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLocating.value = false;
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

  Future<void> fetchPriceHistory() async {
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
        priceHistory.value = (res.body['history'] as List)
            .map((e) => PriceHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } finally {
      loadingHistory.value = false;
    }
  }

  Future<void> submitReport() async {
    if (selectedPackaging.value == null || observedPrice.value <= 0) {
      return;
    }

    isSubmitting.value = true;
    final online = await ConnectivityUtil.isOnline();

    if (!online) {
      _enqueueOffline();
      isSubmitting.value = false;
      Get.snackbar(
        'Hors ligne',
        'Signalement sauvegardé. Il sera envoyé dès la reconnexion.',
        snackPosition: SnackPosition.BOTTOM,
      );
      resetWizard();
      return;
    }

    try {
      final shop = shopName.value.trim();
      final fields = {
        'packagingId': selectedPackaging.value!.id,
        'observedPrice': observedPrice.value.toStringAsFixed(0),
        'type': reportType.value,
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
          'type': reportType.value,
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

  void _enqueueOffline() {
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
    _storage.savePendingReports(list);
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
        '${list.length - remaining.length} signalement(s) en attente envoyé(s) avec succès.',
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

  /// Pré-remplit le wizard depuis PriceCheck.
  /// - Avec [observedPrice] : saute à l'étape 3 (GPS + envoi) — tout est rempli.
  /// - Sans [observedPrice] : saute à l'étape 2 (saisie du prix).
  void preSelect(
    ProductModel product,
    PackagingModel packaging, {
    String type = 'CONFIRMATION',
    double? observedPrice,
  }) {
    resetWizard();
    selectedProduct.value = product;
    selectedPackaging.value = packaging;
    reportType.value = type;
    if (!hasLocation.value && !isLocating.value) locateUser();
    if (observedPrice != null && observedPrice > 0) {
      this.observedPrice.value = observedPrice;
      currentStep.value = 2; // saute directement à l'étape 3 (GPS + envoi)
    } else {
      currentStep.value = 1; // saute à l'étape 2 (saisie du prix)
    }
  }

  /// Réinitialise le wizard et navigue vers la carte
  void viewOnMap() {
    resetWizard();
    Get.find<MainNavController>().goToMap();
  }

  void resetWizard() {
    currentStep.value = 0;
    selectedProduct.value = null;
    selectedPackaging.value = null;
    observedPrice.value = 0;
    photo.value = null;
    hasLocation.value = false;
    lat.value = 0;
    lng.value = 0;
    shopName.value = '';
    submissionResult.value = null;
    searchQuery.value = '';
    reportType.value = 'SIGNALEMENT';
    priceSummary.value = null;
    priceHistory.value = [];
  }
}
