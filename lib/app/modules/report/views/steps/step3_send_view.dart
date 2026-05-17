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
                      value: '${price.toStringAsFixed(0)} FCFA'),
                  if (controller.photo.value != null)
                    const _SummaryRow(label: 'Photo', value: '✓ Ajoutée'),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          // Type auto-déterminé (informatif, non modifiable)
          Obx(() {
            final isConfirmation =
                controller.reportType.value == 'CONFIRMATION';
            final color =
                isConfirmation ? AppColors.success : AppColors.primary;
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: color.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withAlpha(50)),
              ),
              child: Row(
                children: [
                  Icon(
                    isConfirmation
                        ? Icons.check_circle_outline
                        : Icons.flag_outlined,
                    color: color,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isConfirmation
                          ? 'Confirmation d\'un prix existant dans la zone (+3 pts bonus)'
                          : 'Nouveau signalement dans cette zone',
                      style: TextStyle(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          // Nom de l'enseigne
          const Text(
            'Nom de l\'enseigne (optionnel)',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.neutral100),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Ex : Marché Adjamé, Supermarché Hayat...',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
            onChanged: (v) => controller.shopName.value = v,
          ),
          const SizedBox(height: 20),
          // GPS
          Row(
            children: const [
              Text('Localisation',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.neutral100)),
              SizedBox(width: 6),
              Text('(optionnel)',
                  style: TextStyle(fontSize: 12, color: AppColors.neutral60)),
            ],
          ),
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
                    const Spacer(),
                    GestureDetector(
                      onTap: controller.locateUser,
                      child: const Icon(Icons.refresh,
                          color: AppColors.neutral60, size: 18),
                    ),
                  ],
                ),
              );
            }
            if (controller.isLocating.value) {
              return Row(
                children: const [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.neutral60),
                  ),
                  SizedBox(width: 10),
                  Text('Récupération GPS…',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.neutral60)),
                ],
              );
            }
            return OutlinedButton.icon(
              onPressed: controller.locateUser,
              icon: const Icon(Icons.my_location),
              label: const Text('Obtenir ma position'),
            );
          }),
          const SizedBox(height: 6),
          const Text(
            'La localisation améliore la carte. Vous pouvez envoyer sans attendre.',
            style: TextStyle(fontSize: 12, color: AppColors.neutral60),
          ),
          const SizedBox(height: 32),
          Obx(() => ElevatedButton.icon(
                onPressed: controller.isSubmitting.value
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
                label: Obx(() {
                  if (controller.isSubmitting.value) {
                    return const Text('Envoi en cours...');
                  }
                  if (!controller.hasLocation.value) {
                    final isAbus = controller.observedPrice.value >
                        (controller.effectiveMaxPrice ?? double.infinity);
                    return Text(isAbus
                        ? 'Signaler cet abus (sans GPS)'
                        : 'Envoyer sans GPS');
                  }
                  final isAbus = controller.observedPrice.value >
                      (controller.effectiveMaxPrice ?? double.infinity);
                  return Text(isAbus ? 'Signaler cet abus' : 'Envoyer ✓');
                }),
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
