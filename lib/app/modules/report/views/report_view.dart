import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/report_controller.dart';
import 'steps/step1_product_view.dart';
import 'steps/step2_price_view.dart';
import 'steps/step3_send_view.dart';
import 'widgets/report_result_sheet.dart';

class ReportView extends GetView<ReportController> {
  const ReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Afficher le résultat en plein écran si disponible
      if (controller.submissionResult.value != null) {
        return ReportResultSheet(
          result: controller.submissionResult.value!,
          isConfirmation: controller.reportType.value == 'CONFIRMATION',
        );
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Signaler — Étape ${controller.currentStep.value + 1}/3'),
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            _StepIndicator(currentStep: controller.currentStep.value),
            Expanded(
              child: IndexedStack(
                index: controller.currentStep.value,
                children: const [
                  Step1ProductView(),
                  Step2PriceView(),
                  Step3SendView(),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(3, (i) {
          final done = i < currentStep;
          final active = i == currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: done || active
                        ? AppColors.primary
                        : AppColors.neutral20,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: active
                                  ? Colors.white
                                  : AppColors.neutral60,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
                if (i < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      color:
                          i < currentStep ? AppColors.primary : AppColors.neutral20,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
