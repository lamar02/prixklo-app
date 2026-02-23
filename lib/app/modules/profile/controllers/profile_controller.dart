import 'package:get/get.dart';
import '../../../data/models/gamification_model.dart';
import '../../../modules/auth/controllers/auth_controller.dart';
import '../../../modules/report/controllers/report_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';

class ProfileController extends GetxController {
  final _api = Get.find<ApiService>();
  final _storage = Get.find<StorageService>();
  final authCtrl = Get.find<AuthController>();

  final RxInt points = 0.obs;
  final RxInt level = 1.obs;
  final RxList<BadgeModel> badges = <BadgeModel>[].obs;
  final RxBool isLoading = false.obs;

  static const levelThresholds = [0, 50, 150, 350, 700, 1200];

  RxInt get pendingCount => _storage.pendingCount;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    isLoading.value = true;
    try {
      final res = await _api.getGamification();
      if (res.isOk) {
        final g = GamificationModel.fromJson(res.body as Map<String, dynamic>);
        points.value = g.points;
        level.value = g.level;
        badges.value = g.badges;
        authCtrl.updatePoints(g.points, g.level);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> flushPendingReports() async {
    await Get.find<ReportController>().flushOfflineQueue();
  }

  double get levelProgress {
    final l = level.value.clamp(1, levelThresholds.length);
    if (l >= levelThresholds.length) return 1.0;
    final current = levelThresholds[l - 1];
    final next = levelThresholds[l];
    if (next == current) return 1.0;
    return ((points.value - current) / (next - current)).clamp(0.0, 1.0);
  }

  int get nextLevelPoints {
    final l = level.value.clamp(1, levelThresholds.length - 1);
    return levelThresholds[l];
  }

  void goToHistory() => Get.toNamed(AppRoutes.history);
  void goToLeaderboard() => Get.toNamed(AppRoutes.leaderboard);
  void logout() => authCtrl.logout();
}
