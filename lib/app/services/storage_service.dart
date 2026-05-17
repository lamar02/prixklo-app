import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService extends GetxService {
  late SharedPreferences _prefs;

  static const _tokenKey = 'auth_token';
  static const _onboardingKey = 'onboarding_done';
  static const _pendingReportsKey = 'pending_reports';
  static const _officialPricesKey = 'official_prices_json';
  static const _bulletinIdKey = 'cached_bulletin_id';
  static const _fcmPermissionKey = 'fcm_permission_asked';

  /// Nombre de signalements en attente d'envoi (observable)
  final RxInt pendingCount = 0.obs;

  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    pendingCount.value = pendingReports.length;
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

  Future<void> savePendingReports(List<String> list) async {
    await _prefs.setStringList(_pendingReportsKey, list);
    pendingCount.value = list.length;
  }

  // Cache prix officiels + bulletin
  String? get cachedOfficialPricesJson => _prefs.getString(_officialPricesKey);
  String? get cachedBulletinId => _prefs.getString(_bulletinIdKey);

  Future<void> cacheOfficialPrices(String json) =>
      _prefs.setString(_officialPricesKey, json);

  Future<void> cacheBulletinId(String id) =>
      _prefs.setString(_bulletinIdKey, id);

  // Permission FCM — demandée une seule fois après le premier signalement réussi
  bool get fcmPermissionAsked => _prefs.getBool(_fcmPermissionKey) ?? false;
  Future<void> markFcmPermissionAsked() =>
      _prefs.setBool(_fcmPermissionKey, true);
}
