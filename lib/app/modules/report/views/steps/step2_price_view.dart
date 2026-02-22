import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controllers/report_controller.dart';

class Step2PriceView extends GetView<ReportController> {
  const Step2PriceView({super.key});

  @override
  Widget build(BuildContext context) {
    final priceCtrl = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Résumé produit sélectionné
          Obx(() {
            final p = controller.selectedProduct.value;
            final pk = controller.selectedPackaging.value;
            if (p == null) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${p.name}${pk != null ? ' — ${pk.label}' : ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => controller.goToStep(0),
                    child: const Icon(Icons.edit_outlined,
                        size: 16, color: AppColors.primary),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          const Text(
            'Prix observé (FCFA)',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.neutral100),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: priceCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              hintText: '0',
              suffixText: 'FCFA',
              suffixStyle: TextStyle(color: AppColors.neutral60),
            ),
            onChanged: (v) =>
                controller.observedPrice.value = double.tryParse(v) ?? 0,
          ),
          const SizedBox(height: 24),
          // Photo optionnelle
          const Text(
            'Photo (optionnelle)',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.neutral100),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ajoute une photo pour renforcer la fiabilité du signalement.',
            style: TextStyle(fontSize: 13, color: AppColors.neutral60),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final f = controller.photo.value;
            if (f != null) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(f,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => controller.photo.value = null,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.takePhoto,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Caméra'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.pickPhoto,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galerie'),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 32),
          Obx(() => ElevatedButton(
                onPressed: controller.observedPrice.value > 0
                    ? () => controller.goToStep(2)
                    : null,
                child: const Text('Suivant'),
              )),
        ],
      ),
    );
  }
}
