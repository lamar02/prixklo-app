import 'package:get/get.dart';
import '../../../data/models/gamification_model.dart';
import '../../../data/models/map_marker_model.dart';
import '../../../modules/auth/controllers/auth_controller.dart';
import '../../../modules/main_nav/controllers/main_nav_controller.dart';
import '../../../services/api_service.dart';

class HomeController extends GetxController {
  final _api = Get.find<ApiService>();
  final authCtrl = Get.find<AuthController>();

  final RxList<MapMarkerModel> recentAbuses = <MapMarkerModel>[].obs;
  final RxInt points = 0.obs;
  final RxInt level = 1.obs;
  final Rx<BadgeModel?> latestBadge = Rx<BadgeModel?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHomeData();
  }

  Future<void> fetchHomeData() async {
    isLoading.value = true;
    try {
      await Future.wait([_fetchRecentAbuses(), _fetchGamification()]);
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

  void goToReport() => Get.find<MainNavController>().goToReport();
}
