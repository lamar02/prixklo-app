import 'dart:convert';

import 'package:get/get.dart';
import '../../../data/models/bulletin_model.dart';
import '../../../data/models/gamification_model.dart';
import '../../../data/models/map_marker_model.dart';
import '../../../data/models/official_price_model.dart';
import '../../../modules/auth/controllers/auth_controller.dart';
import '../../../modules/main_nav/controllers/main_nav_controller.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';

class HomeController extends GetxController {
  final _api = Get.find<ApiService>();
  final _storage = Get.find<StorageService>();
  final authCtrl = Get.find<AuthController>();

  // ── Abus récents + gamification ──────────────────────────
  final RxList<MapMarkerModel> recentAbuses = <MapMarkerModel>[].obs;
  final RxInt points = 0.obs;
  final RxInt level = 1.obs;
  final Rx<BadgeModel?> latestBadge = Rx<BadgeModel?>(null);
  final RxBool isLoading = false.obs;

  // ── Bulletin + prix officiels ─────────────────────────────
  final Rx<BulletinModel?> activeBulletin = Rx<BulletinModel?>(null);
  final RxList<OfficialPriceModel> officialPrices = <OfficialPriceModel>[].obs;
  final RxBool loadingPrices = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHomeData();
  }

  Future<void> fetchHomeData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _fetchRecentAbuses(),
        _fetchGamification(),
        fetchBulletinAndPrices(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchRecentAbuses() async {
    final res = await _api.getMapMarkers(onlyAbus: true);
    if (res.isOk) {
      final markers = (res.body['markers'] as List)
          .map((m) => MapMarkerModel.fromJson(m as Map<String, dynamic>))
          .toList();
      recentAbuses.value = markers.take(5).toList();
    }
  }

  Future<void> _fetchGamification() async {
    final res = await _api.getGamification();
    if (res.isOk) {
      final g = GamificationModel.fromJson(res.body as Map<String, dynamic>);
      points.value = g.points;
      level.value = g.level;
      latestBadge.value = g.badges.isNotEmpty ? g.badges.last : null;
    }
  }

  Future<void> fetchBulletinAndPrices() async {
    loadingPrices.value = true;
    try {
      // 1. Bulletin actif
      final bulletinRes = await _api.getActiveBulletin();
      if (bulletinRes.isOk) {
        final bData = bulletinRes.body['bulletin'] as Map<String, dynamic>?;
        if (bData != null) {
          activeBulletin.value = BulletinModel.fromJson(bData);
        }
      }

      // 2. Prix officiels — utilise le cache si bulletin inchangé
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
    } finally {
      loadingPrices.value = false;
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

  void goToReport() => Get.find<MainNavController>().goToReport();
}
