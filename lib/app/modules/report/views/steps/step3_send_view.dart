import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controllers/report_controller.dart';

class Step3SendView extends GetView<ReportController> {
  const Step3SendView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Résumé
          Obx(() {
            final p = controller.selectedProduct.value;
            final pk = controller.selectedPackaging.value;
            final price = controller.observedPrice.value;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.neutral20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Récapitulatif',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutral100)),
                  const Divider(height: 16),
                  _SummaryRow(label: 'Produit', value: p?.name ?? '-'),
                  _SummaryRow(
                      label: 'Conditionnement', value: pk?.label ?? '-'),
                  _SummaryRow(
                      label: 'Prix observé',
                      value:
                          '${price.toStringAsFixed(0)} FCFA'),
                  if (controller.photo.value != null)
                    const _SummaryRow(label: 'Photo', value: '✓ Ajoutée'),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          // GPS
          const Text('Localisation',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral100)),
          const SizedBox(height: 8),
          Obx(() {
            if (controller.hasLocation.value) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${controller.lat.value.toStringAsFixed(4)}, ${controller.lng.value.toStringAsFixed(4)}',
                      style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }
            return OutlinedButton.icon(
              onPressed: controller.isLocating.value
                  ? null
                  : controller.locateUser,
              icon: controller.isLocating.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Icon(Icons.my_location),
              label: Text(controller.isLocating.value
                  ? 'Localisation en cours...'
                  : 'Obtenir ma position'),
            );
          }),
          const SizedBox(height: 8),
          const Text(
            'La localisation est obligatoire pour pouvoir envoyer le signalement.',
            style: TextStyle(fontSize: 12, color: AppColors.neutral60),
          ),
          const SizedBox(height: 32),
          Obx(() => ElevatedButton.icon(
                onPressed: controller.isSubmitting.value ||
                        !controller.hasLocation.value
                    ? null
                    : controller.submitReport,
                icon: controller.isSubmitting.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(controller.isSubmitting.value
                    ? 'Envoi en cours...'
                    : 'Envoyer le signalement'),
              )),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.neutral60, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
