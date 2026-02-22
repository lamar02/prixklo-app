import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../modules/auth/controllers/auth_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';

class SplashController extends GetxController {
  final _storage = Get.find<StorageService>();
  final _api = Get.find<ApiService>();

  @override
  void onReady() {
    super.onReady();
    _checkAndRedirect();
  }

  Future<void> _checkAndRedirect() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final token = _storage.token;
    if (token == null) {
      _redirectGuest();
      return;
    }

    try {
      final res = await _api.getMe();
      if (res.isOk) {
        final user = UserModel.fromJson(res.body['user'] as Map<String, dynamic>);
        Get.find<AuthController>().setUser(user);
        Get.offAllNamed(AppRoutes.mainNav);
      } else {
        await _storage.clearToken();
        _redirectGuest();
      }
    } catch (_) {
      await _storage.clearToken();
      _redirectGuest();
    }
  }

  void _redirectGuest() {
    if (_storage.onboardingDone) {
      Get.offAllNamed(AppRoutes.login);
    } else {
      Get.offAllNamed(AppRoutes.onboarding);
    }
  }
}
