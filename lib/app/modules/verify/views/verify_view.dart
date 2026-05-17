import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/verify_controller.dart';
import 'screens/screen1_search.dart';
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
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: child,
          ),
          layoutBuilder: (currentChild, previousChildren) => Stack(
            fit: StackFit.expand,
            alignment: Alignment.topCenter,
            children: [
              ...previousChildren,
              ?currentChild,
            ],
          ),
          child: controller.currentScreen.value == 0
              ? const Screen1Search(key: ValueKey(0))
              : const Screen3Price(key: ValueKey(1)),
        ),
      );
    });
  }
}
