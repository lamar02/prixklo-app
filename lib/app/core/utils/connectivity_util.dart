import 'dart:io';

abstract class ConnectivityUtil {
  static Future<bool> isOnline() async {
    try {
      final result =
          await InternetAddress.lookup('prixklobackend.vercel.app')
              .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
