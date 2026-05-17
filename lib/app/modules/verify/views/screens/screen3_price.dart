import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controllers/verify_controller.dart';
import '../widgets/mini_flux_sheet.dart';

class Screen3Price extends StatefulWidget {
  const Screen3Price({super.key});

  @override
  State<Screen3Price> createState() => _Screen3PriceState();
}

class _Screen3PriceState extends State<Screen3Price> {
  late final TextEditingController _priceCtrl;
  late final Worker _priceWorker;

  VerifyController get controller => Get.find<VerifyController>();

  @override
  void initState() {
    super.initState();
    final current = controller.observedPrice.value;
    _priceCtrl = TextEditingController(
      text: current > 0 ? current.toStringAsFixed(0) : '',
    );
    _priceWorker = ever(controller.observedPrice, (double v) {
      final text = v > 0 ? v.toStringAsFixed(0) : '';
      if (_priceCtrl.text != text) _priceCtrl.text = text;
    });
  }

  @override
  void dispose() {
    _priceWorker.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _showMiniFlux() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const MiniFluxSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête + retour ────────────────────────────
            Row(
              children: [
                GestureDetector(
                  onTap: controller.goBack,
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: AppColors.neutral100),
                ),
                const SizedBox(width: 8),
                Obx(() {
                  final p = controller.selectedProduct.value;
                  final pk = controller.selectedPackaging.value;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => controller.goToScreen(1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${p?.name ?? ''}${pk != null ? ' — ${pk.label}' : ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.edit_outlined,
                                size: 14, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),
            // ── Prix plafond officiel ───────────────────────
            Obx(() {
              final max = controller.effectiveMaxPrice;
              if (max == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
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
                      Text(
                        '${max.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Ne devrait pas dépasser ce montant',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.neutral60),
                      ),
                    ],
                  ),
                ),
              );
            }),
            // ── Champ prix ─────────────────────────────────
            const Text(
              'Prix affiché en magasin (FCFA)',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.neutral100),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                hintText: '0',
                suffixText: 'FCFA',
                suffixStyle: TextStyle(color: AppColors.neutral60),
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
              onChanged: (v) =>
                  controller.observedPrice.value = double.tryParse(v) ?? 0,
            ),
            const SizedBox(height: 12),
            // ── Bannière verdict temps réel ─────────────────
            Obx(() {
              final verdict = controller.localVerdict;
              if (verdict == null) return const SizedBox.shrink();
              final max = controller.effectiveMaxPrice!;
              final price = controller.observedPrice.value;
              final isAbus = verdict == 'ABUS';
              final diff = (price - max).abs();
              final pct = ((diff / max) * 100).toStringAsFixed(0);
              final color = isAbus ? AppColors.abus : AppColors.success;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: color.withAlpha(18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAbus
                          ? Icons.warning_rounded
                          : Icons.check_circle_rounded,
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isAbus
                            ? '🚨 +$pct% au-dessus du plafond'
                            : '✅ Dans la limite du plafond',
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
            const SizedBox(height: 32),
            // ── CTA contextuel ──────────────────────────────
            Obx(() {
              final verdict = controller.localVerdict;
              final active = verdict != null;
              final isAbus = verdict == 'ABUS';
              final label = isAbus
                  ? 'Signaler cet abus  ·  +10 pts'
                  : 'Confirmer ce prix  ·  +5 pts';
              final color = isAbus ? AppColors.abus : AppColors.success;

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  onPressed: active ? _showMiniFlux : null,
                  child: Text(label),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
