import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/core/app_binding.dart';
import 'app/core/theme/app_theme.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/services/connectivity_service.dart';
import 'app/services/storage_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  await Get.putAsync(() => StorageService().init());
  Get.put(ConnectivityService(), permanent: true);
  runApp(const PrixKloApp());
}

class PrixKloApp extends StatelessWidget {
  const PrixKloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PrixKlo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      initialBinding: AppBinding(),
      defaultTransition: Transition.cupertino,
      builder: (context, child) {
        return _ConnectivityWrapper(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

// ── Overlay global "Pas de connexion" ──────────────────────────────────────

class _ConnectivityWrapper extends StatelessWidget {
  final Widget child;
  const _ConnectivityWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    final svc = Get.find<ConnectivityService>();
    return Obx(() {
      return Stack(
        children: [
          child,
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: svc.isOnline.value
                ? const SizedBox.shrink()
                : _NoConnectionScreen(
                    key: const ValueKey('offline'),
                    onRetry: svc.retry,
                  ),
          ),
        ],
      );
    });
  }
}

class _NoConnectionScreen extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _NoConnectionScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.neutral20,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: AppColors.neutral60,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Pas de connexion',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral100,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Vérifiez votre connexion internet\net réessayez.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.neutral60,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              _RetryButton(onRetry: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}

class _RetryButton extends StatefulWidget {
  final Future<void> Function() onRetry;
  const _RetryButton({required this.onRetry});

  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton> {
  bool _loading = false;

  Future<void> _tap() async {
    if (_loading) return;
    setState(() => _loading = true);
    await widget.onRetry();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _tap,
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.refresh_rounded, size: 20),
        label: Text(_loading ? 'Vérification…' : 'Réessayer'),
      ),
    );
  }
}
