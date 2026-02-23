import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

import '../modules/main_nav/controllers/main_nav_controller.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';

/// Gestionnaire global des notifications push FCM.
/// À initialiser après Firebase.initializeApp() dans main().
class PushNotificationService extends GetxService {
  final _fcm = FirebaseMessaging.instance;
  final _api = Get.find<ApiService>();

  Future<PushNotificationService> init() async {
    // Demande la permission (iOS + Android 13+)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Écoute les messages reçus en foreground
    FirebaseMessaging.onMessage.listen(_onForeground);

    // Tap sur notification quand l'app était en background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // Tap sur notification qui a lancé l'app depuis un état terminé
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleTap(initial);

    return this;
  }

  /// Enregistre (ou met à jour) le token FCM sur le backend.
  /// À appeler après chaque login / register réussi.
  Future<void> registerToken() async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      final platform = Platform.isAndroid ? 'android' : 'ios';
      await _api.registerFcmToken(token: token, platform: platform);
    } catch (_) {
      // Échec silencieux — les notifications push resteront non configurées
    }
  }

  void _onForeground(RemoteMessage message) {
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';
    if (title.isEmpty && body.isEmpty) return;
    Get.snackbar(
      title,
      body,
      duration: const Duration(seconds: 5),
      onTap: (_) => _handleTap(message),
    );
  }

  void _handleTap(RemoteMessage message) {
    final type = message.data['type'] as String?;
    switch (type) {
      case 'ABUS_NEARBY':
        // Navigue vers la carte (onglet 1)
        Get.until((route) => Get.currentRoute == AppRoutes.mainNav);
        try {
          Get.find<MainNavController>().changeTab(1);
        } catch (_) {}
      case 'REPORT_CONFIRMED':
        Get.toNamed(AppRoutes.history);
    }
  }
}
