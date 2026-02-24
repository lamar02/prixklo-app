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
      final result = await InternetAddress.lookup('prixklobackend.vercel.app')
          .timeout(const Duration(seconds: 4));
      isOnline.value = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
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
