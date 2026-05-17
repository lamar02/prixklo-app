import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controllers/verify_controller.dart';

class PackagingSheet extends GetView<VerifyController> {
  const PackagingSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral60.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Product name + category
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(() {
              final product = controller.selectedProduct.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product?.name ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral100,
                    ),
                  ),
                  if (product?.category != null)
                    Text(
                      product!.category,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.neutral60,
                      ),
                    ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
          // Packaging chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(() {
              final product = controller.selectedProduct.value;
              if (product == null) return const SizedBox.shrink();
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: product.packagings
                    .map((p) => Obx(() => ChoiceChip(
                          label: Text(p.label),
                          selected: controller.selectedPackaging.value?.id == p.id,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: controller.selectedPackaging.value?.id == p.id
                                ? Colors.white
                                : AppColors.neutral100,
                          ),
                          onSelected: (_) => controller.selectPackaging(p),
                        )))
                    .toList(),
              );
            }),
          ),
          const SizedBox(height: 16),
          // Official price card (only when packaging selected)
          Obx(() {
            final pkg = controller.selectedPackaging.value;
            if (pkg == null) return const SizedBox.shrink();
            final maxPrice = controller.effectiveMaxPrice;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(50)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.verified_outlined,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      const Text(
                        'Prix plafond officiel',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    maxPrice != null
                        ? Text(
                            '${maxPrice.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          )
                        : const Text(
                            'Non disponible',
                            style: TextStyle(
                                fontSize: 14, color: AppColors.neutral60),
                          ),
                    const SizedBox(height: 2),
                    const Text(
                      'Ne devrait pas dépasser ce montant',
                      style: TextStyle(fontSize: 11, color: AppColors.neutral60),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          // Continuer button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Obx(() => ElevatedButton(
                  onPressed: controller.selectedPackaging.value != null
                      ? () {
                          Navigator.pop(context);
                          controller.goToScreen(1);
                        }
                      : null,
                  child: const Text('Continuer'),
                )),
          ),
        ],
      ),
    );
  }
}
