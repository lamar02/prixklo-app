import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../routes/app_routes.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';

class AuthController extends GetxController {
  final _storage = Get.find<StorageService>();
  final _api = Get.find<ApiService>();

  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;

  bool get isLoggedIn => user.value != null;

  void setUser(UserModel u) => user.value = u;

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    try {
      final res = await _api.login(email.trim(), password);
      if (res.isOk) {
        await _storage.saveToken(res.body['token'] as String);
        user.value = UserModel.fromJson(res.body['user'] as Map<String, dynamic>);
        Get.offAllNamed(AppRoutes.mainNav);
      } else {
        final msg = res.body?['message'] as String? ?? 'Identifiants incorrects';
        Get.snackbar('Erreur de connexion', msg,
            snackPosition: SnackPosition.BOTTOM);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register(String name, String email, String password) async {
    isLoading.value = true;
    try {
      final res = await _api.register(name.trim(), email.trim(), password);
      if (res.statusCode == 201) {
        await _storage.saveToken(res.body['token'] as String);
        user.value = UserModel.fromJson(res.body['user'] as Map<String, dynamic>);
        Get.offAllNamed(AppRoutes.mainNav);
      } else {
        final msg = res.body?['message'] as String?
            ?? res.body?['error'] as String?
            ?? res.bodyString
            ?? 'Erreur ${res.statusCode}';
        Get.snackbar('Erreur inscription', msg,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 6));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _storage.clearToken();
    user.value = null;
    Get.offAllNamed(AppRoutes.login);
  }

  void updatePoints(int points, int level) {
    if (user.value != null) {
      user.value = user.value!.copyWith(points: points, level: level);
      user.refresh();
    }
  }
}
