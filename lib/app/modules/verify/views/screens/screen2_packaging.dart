import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controllers/verify_controller.dart';

class Screen2Packaging extends GetView<VerifyController> {
  const Screen2Packaging({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête + retour ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: controller.goBack,
                ),
                Obx(() => Expanded(
                      child: Text(
                        controller.selectedProduct.value?.name ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutral100,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Catégorie ───────────────────────────────
                  Obx(() => Text(
                        controller.selectedProduct.value?.category ?? '',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.neutral60),
                      )),
                  const SizedBox(height: 20),
                  // ── Chips conditionnement ───────────────────
                  const Text(
                    'Conditionnement',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral100,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    final product = controller.selectedProduct.value;
                    if (product == null) return const SizedBox.shrink();
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.packagings
                          .map((p) => Obx(() => ChoiceChip(
                                label: Text(p.label),
                                selected:
                                    controller.selectedPackaging.value?.id ==
                                        p.id,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: controller.selectedPackaging.value
                                              ?.id ==
                                          p.id
                                      ? Colors.white
                                      : AppColors.neutral100,
                                ),
                                onSelected: (_) =>
                                    controller.selectPackaging(p),
                              )))
                          .toList(),
                    );
                  }),
                  const SizedBox(height: 20),
                  // ── Prix plafond officiel ───────────────────
                  Obx(() {
                    final pkg = controller.selectedPackaging.value;
                    if (pkg == null) return const SizedBox.shrink();
                    final maxPrice = controller.effectiveMaxPrice;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(12),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.primary.withAlpha(50)),
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
                          const SizedBox(height: 8),
                          maxPrice != null
                              ? Text(
                                  '${maxPrice.toStringAsFixed(0)} FCFA',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                )
                              : const Text(
                                  'Non disponible pour ce produit',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.neutral60),
                                ),
                          const SizedBox(height: 4),
                          const Text(
                            'Ne devrait pas dépasser ce montant',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.neutral60),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          // ── Bouton Continuer ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Obx(() => ElevatedButton(
                  onPressed: controller.selectedPackaging.value != null
                      ? () => controller.goToScreen(2)
                      : null,
                  child: const Text('Continuer'),
                )),
          ),
        ],
      ),
    );
  }
}
