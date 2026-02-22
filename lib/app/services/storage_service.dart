import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService extends GetxService {
  late SharedPreferences _prefs;

  static const _tokenKey = 'auth_token';
  static const _onboardingKey = 'onboarding_done';
  static const _pendingReportsKey = 'pending_reports';

  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  // Token JWT
  String? get token => _prefs.getString(_tokenKey);
  Future<void> saveToken(String token) => _prefs.setString(_tokenKey, token);
  Future<void> clearToken() => _prefs.remove(_tokenKey);

  // Onboarding
  bool get onboardingDone => _prefs.getBool(_onboardingKey) ?? false;
  Future<void> markOnboardingDone() => _prefs.setBool(_onboardingKey, true);

  // File d'attente hors-ligne (liste JSON encodée)
  List<String> get pendingReports =>
      _prefs.getStringList(_pendingReportsKey) ?? [];
  Future<void> savePendingReports(List<String> list) =>
      _prefs.setStringList(_pendingReportsKey, list);
}
