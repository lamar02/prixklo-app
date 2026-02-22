import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/connectivity_util.dart';
import '../../../data/models/gamification_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/report_model.dart';
import '../../../data/providers/offline_queue_model.dart';
import '../../../modules/auth/controllers/auth_controller.dart';
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

  // ── Étape 3 : Localisation ────────────────────────────────
  final RxDouble lat = 0.0.obs;
  final RxDouble lng = 0.0.obs;
  final RxBool hasLocation = false.obs;
  final RxBool isLocating = false.obs;
  final RxBool isSubmitting = false.obs;

  // ── Résultat ──────────────────────────────────────────────
  final Rx<ReportModel?> submissionResult = Rx<ReportModel?>(null);

  @override
  void onInit() {
    super.onInit();
    _loadProducts();
    _flushOfflineQueue();
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
  }

  void selectPackaging(PackagingModel packaging) {
    selectedPackaging.value = packaging;
  }

  void goToStep(int step) => currentStep.value = step;

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

  Future<void> submitReport() async {
    if (selectedPackaging.value == null ||
        observedPrice.value <= 0 ||
        !hasLocation.value) {
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
      final fields = {
        'packagingId': selectedPackaging.value!.id,
        'observedPrice': observedPrice.value.toStringAsFixed(0),
        if (hasLocation.value) 'lat': lat.value.toString(),
        if (hasLocation.value) 'lng': lng.value.toString(),
      };

      Response res;
      if (photo.value != null) {
        res = await _api.createReportWithPhoto(fields, photo.value!.path);
      } else {
        res = await _api.createReport({
          'packagingId': selectedPackaging.value!.id,
          'observedPrice': observedPrice.value,
          if (hasLocation.value) 'lat': lat.value,
          if (hasLocation.value) 'lng': lng.value,
        });
      }

      if (res.statusCode == 201) {
        final report =
            ReportModel.fromJson(res.body['report'] as Map<String, dynamic>);
        submissionResult.value = report;
        _refreshUserPoints();
        _flushOfflineQueue();
      } else {
        Get.snackbar('Erreur', 'Envoi échoué. Réessayez.',
            snackPosition: SnackPosition.BOTTOM);
      }
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
      queuedAt: DateTime.now(),
    );
    final list = List<String>.from(_storage.pendingReports)
      ..add(pending.toEncodedString());
    _storage.savePendingReports(list);
  }

  Future<void> _flushOfflineQueue() async {
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
        });
        if (res.statusCode != 201) remaining.add(item);
      } catch (_) {
        remaining.add(item);
      }
    }
    await _storage.savePendingReports(remaining);
  }

  Future<void> _refreshUserPoints() async {
    final res = await _api.getGamification();
    if (res.isOk) {
      final g = GamificationModel.fromJson(res.body as Map<String, dynamic>);
      Get.find<AuthController>().updatePoints(g.points, g.level);
    }
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
    submissionResult.value = null;
    searchQuery.value = '';
  }
}
