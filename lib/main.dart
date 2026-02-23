import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/core/app_binding.dart';
import 'app/core/theme/app_theme.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // StorageService initialisé avant runApp (requis pour SharedPreferences)
  await Get.putAsync(() => StorageService().init());
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
    );
  }
}
