import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  final RxBool isOnline = true.obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _check();
    // Vérifie toutes les 5 secondes
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _check());
  }

  Future<void> _check() async {
    try {
      // Socket.connect fait un vrai handshake TCP — impossible à satisfaire
      // depuis un cache DNS ou un WiFi capté sans internet.
      final socket = await Socket.connect(
        'prixklobackend.vercel.app',
        443,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      isOnline.value = true;
    } catch (_) {
      isOnline.value = false;
    }
  }

  Future<void> retry() => _check();

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
