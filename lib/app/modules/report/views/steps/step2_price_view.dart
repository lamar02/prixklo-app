import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controllers/report_controller.dart';
import '../widgets/price_history_chart.dart';

class Step2PriceView extends StatefulWidget {
  const Step2PriceView({super.key});

  @override
  State<Step2PriceView> createState() => _Step2PriceViewState();
}

class _Step2PriceViewState extends State<Step2PriceView> {
  late final TextEditingController _priceCtrl;

  ReportController get controller => Get.find<ReportController>();

  @override
  void initState() {
    super.initState();
    final currentPrice = Get.find<ReportController>().observedPrice.value;
    _priceCtrl = TextEditingController(
      text: currentPrice > 0 ? currentPrice.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            controller: _priceCtrl,
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
          const SizedBox(height: 16),
          const _PriceSummaryCard(),
          const SizedBox(height: 16),
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

// ── Carte "Prix dans ce quartier" ─────────────────────────────────────────────

class _PriceSummaryCard extends StatelessWidget {
  const _PriceSummaryCard();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ReportController>();
    return Obx(() {
      if (ctrl.selectedPackaging.value == null) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neutral20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: AppColors.neutral60),
                const SizedBox(width: 4),
                Text(
                  'Prix dans ce quartier (${ctrl.priceSummary.value?.radiusKm ?? 5} km)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral100,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildBody(context, ctrl),
          ],
        ),
      );
    });
  }

  Widget _buildBody(BuildContext context, ReportController ctrl) {
    if (!ctrl.hasLocation.value) {
      return const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            'Recherche de votre position…',
            style: TextStyle(fontSize: 12, color: AppColors.neutral60),
          ),
        ],
      );
    }
    if (ctrl.loadingSummary.value) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final summary = ctrl.priceSummary.value;
    if (summary == null) return const SizedBox.shrink();

    if (summary.count == 0) {
      return const Text(
        'Soyez le premier à signaler dans cette zone !',
        style: TextStyle(fontSize: 13, color: AppColors.neutral60),
      );
    }

    final statusColor = _statusColor(summary.dominantStatus);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _PriceInfoTile(
                label: 'Prix officiel max',
                value: summary.officialMaxPrice != null
                    ? '${summary.officialMaxPrice!.toStringAsFixed(0)} FCFA'
                    : 'N/A',
                color: AppColors.neutral60,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PriceInfoTile(
                label: 'Observé en moyenne',
                value: summary.avg != null
                    ? '${summary.avg!.toStringAsFixed(0)} FCFA'
                    : 'N/A',
                color: statusColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: summary.statusBreakdown.entries
              .where((e) => e.value > 0)
              .map((e) => _StatusChip(status: e.key, count: e.value))
              .toList(),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _showHistorySheet(context, ctrl),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Voir la tendance',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios,
                  size: 12, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }

  Color _statusColor(String? status) => switch (status) {
        'ABUS' => AppColors.abus,
        'CONFORME' => AppColors.success,
        'LIMITE' => AppColors.primary,
        _ => AppColors.neutral60,
      };

  void _showHistorySheet(BuildContext context, ReportController ctrl) {
    ctrl.fetchPriceHistory();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PriceHistorySheet(ctrl: ctrl),
    );
  }
}

class _PriceInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PriceInfoTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.neutral60)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final int count;

  const _StatusChip({required this.status, required this.count});

  @override
  Widget build(BuildContext context) {
    final (Color color, String label) = switch (status) {
      'ABUS' => (AppColors.abus, 'Abus'),
      'CONFORME' => (AppColors.success, 'Conforme'),
      'LIMITE' => (AppColors.primary, 'Limite'),
      _ => (AppColors.neutral60, 'Inconnu'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PriceHistorySheet extends StatelessWidget {
  final ReportController ctrl;

  const _PriceHistorySheet({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutral20,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tendance des prix (30 jours)',
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          Obx(() {
            if (ctrl.loadingHistory.value) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return SizedBox(
              height: 200,
              child: PriceHistoryChart(history: ctrl.priceHistory),
            );
          }),
          const SizedBox(height: 8),
          const Text(
            'Prix moyens observés par semaine dans un rayon de 5 km',
            style:
                TextStyle(fontSize: 11, color: AppColors.neutral60),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
