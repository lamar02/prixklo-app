import 'package:get/get.dart';
import '../../../data/models/report_model.dart';
import '../../../services/api_service.dart';

class HistoryController extends GetxController {
  final _api = Get.find<ApiService>();

  final RxList<ReportModel> reports = <ReportModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasMore = true.obs;
  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    fetchReports();
  }

  Future<void> fetchReports({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      reports.clear();
      hasMore.value = true;
    }
    if (!hasMore.value || isLoading.value) return;

    isLoading.value = true;
    try {
      final res = await _api.getMyReports(page: _page);
      if (res.isOk) {
        final newReports = (res.body['reports'] as List)
            .map((r) => ReportModel.fromJson(r as Map<String, dynamic>))
            .toList();
        reports.addAll(newReports);
        if (newReports.isEmpty) {
          hasMore.value = false;
        } else {
          _page++;
        }
      }
    } finally {
      isLoading.value = false;
    }
  }
}
