import 'package:get/get.dart';
import '../../map/controllers/map_controller.dart';
import '../../notifications/controllers/notifications_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../verify/controllers/verify_controller.dart';
import '../controllers/main_nav_controller.dart';

class MainNavBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainNavController>(() => MainNavController());
    Get.lazyPut<VerifyController>(() => VerifyController());
    Get.lazyPut<MapController>(() => MapController());
    Get.lazyPut<ProfileController>(() => ProfileController());
    Get.lazyPut<NotificationsController>(() => NotificationsController());
  }
}
