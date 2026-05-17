import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/verify_controller.dart';
import 'screens/screen1_search.dart';
import 'screens/screen2_packaging.dart';
import 'screens/screen3_price.dart';
import 'widgets/verify_result_screen.dart';

class VerifyView extends GetView<VerifyController> {
  const VerifyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final result = controller.submissionResult.value;
      if (result != null) {
        return VerifyResultScreen(result: result);
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: controller.currentScreen.value,
          children: const [
            Screen1Search(),
            Screen2Packaging(),
            Screen3Price(),
          ],
        ),
      );
    });
  }
}
