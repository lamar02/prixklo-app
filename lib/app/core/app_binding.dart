import 'package:get/get.dart';
import '../core/controllers/app_data_controller.dart';
import '../modules/auth/controllers/auth_controller.dart';
import '../services/api_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ApiService>(ApiService(), permanent: true);
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<AppDataController>(AppDataController(), permanent: true);
  }
}
