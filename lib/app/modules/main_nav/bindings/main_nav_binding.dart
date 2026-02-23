import 'package:get/get.dart';
import '../../home/controllers/home_controller.dart';
import '../../map/controllers/map_controller.dart';
import '../../notifications/controllers/notifications_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../report/controllers/report_controller.dart';
import '../controllers/main_nav_controller.dart';

class MainNavBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainNavController>(() => MainNavController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<MapController>(() => MapController());
    Get.lazyPut<ReportController>(() => ReportController());
    Get.lazyPut<ProfileController>(() => ProfileController());
    Get.lazyPut<NotificationsController>(() => NotificationsController());
  }
}
