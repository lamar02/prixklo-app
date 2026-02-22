import 'package:get/get.dart';
import '../controllers/splash_controller.dart';
// TODO(phase-2): réactiver AuthController quand auth est validée
// import '../../auth/controllers/auth_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // TODO(phase-2): réactiver AuthController (permanent) pour toute l'app
    // Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<SplashController>(SplashController());
  }
}
