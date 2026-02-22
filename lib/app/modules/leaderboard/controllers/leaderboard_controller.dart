import 'package:get/get.dart';
import '../../../data/models/leaderboard_entry_model.dart';
import '../../../services/api_service.dart';

class LeaderboardController extends GetxController {
  final _api = Get.find<ApiService>();

  final RxList<LeaderboardEntryModel> entries = <LeaderboardEntryModel>[].obs;
  final RxString period = 'all'.obs; // 'all' | 'week' | 'month'
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLeaderboard();
    ever(period, (_) => fetchLeaderboard());
  }

  Future<void> fetchLeaderboard() async {
    isLoading.value = true;
    final res = await _api.getLeaderboard(
      period: period.value == 'all' ? null : period.value,
    );
    if (res.isOk) {
      entries.value = (res.body['leaderboard'] as List)
          .map((e) => LeaderboardEntryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    isLoading.value = false;
  }
}
