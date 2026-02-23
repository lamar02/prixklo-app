import 'package:get/get.dart';
import '../../../data/models/notification_model.dart';
import '../../../services/api_service.dart';

class NotificationsController extends GetxController {
  final _api = Get.find<ApiService>();

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  int get unreadCount => notifications.where((n) => !n.read).length;

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    try {
      final res = await _api.getNotifications();
      if (res.isOk) {
        notifications.value = (res.body['notifications'] as List)
            .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
            .toList();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAllRead() async {
    final res = await _api.markNotificationsRead();
    if (res.isOk) {
      notifications.value =
          notifications.map((n) => n.copyWith(read: true)).toList();
    }
  }
}
