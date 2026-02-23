import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../data/models/map_marker_model.dart';
import '../../../../modules/main_nav/controllers/main_nav_controller.dart';
import '../../../../modules/report/controllers/report_controller.dart';

class MapMarkerSheet extends StatelessWidget {
  final MapMarkerModel marker;
  const MapMarkerSheet({super.key, required this.marker});

  @override
  Widget build(BuildContext context) {
    final isAbus = marker.status == 'ABUS';
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral20,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      (isAbus ? AppColors.abus : AppColors.success).withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isAbus ? '🚨 ABUS' : '✅ CONFORME',
                  style: TextStyle(
                    color: isAbus ? AppColors.abus : AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${marker.productName} — ${marker.packagingLabel}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.neutral100,
            ),
          ),
          if (marker.shopName != null && marker.shopName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.storefront_outlined,
                    size: 14, color: AppColors.neutral60),
                const SizedBox(width: 4),
                Text(
                  marker.shopName!,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.neutral60),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _PriceInfo(
                label: 'Prix observé',
                value: '${marker.observedPrice.toStringAsFixed(0)} FCFA',
                color: isAbus ? AppColors.abus : AppColors.success,
              ),
              const SizedBox(width: 24),
              _PriceInfo(
                label: 'Prix officiel max',
                value: '${marker.maxPrice.toStringAsFixed(0)} FCFA',
                color: AppColors.neutral60,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormatter.full(marker.createdAt),
            style: const TextStyle(fontSize: 12, color: AppColors.neutral60),
          ),
          const SizedBox(height: 16),
          // ── CTAs ───────────────────────────────────────────
          if (marker.packagingId != null)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launchReport('CONFIRMATION'),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Confirmer ce prix'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: const BorderSide(color: AppColors.success),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchReport('SIGNALEMENT'),
                    icon: const Icon(Icons.warning_rounded, size: 16),
                    label: const Text('Signaler ici'),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _launchReport(String type) {
    final reportCtrl = Get.find<ReportController>();
    // Cherche le packaging dans le catalogue déjà chargé
    for (final product in reportCtrl.products) {
      for (final pkg in product.packagings) {
        if (pkg.id == marker.packagingId) {
          reportCtrl.preSelect(product, pkg, type: type);
          Get.find<MainNavController>().goToReport();
          Get.back(); // ferme le bottom sheet
          return;
        }
      }
    }
    // Fallback : ouvre simplement l'onglet signaler sans pré-remplissage
    Get.find<MainNavController>().goToReport();
    Get.back();
  }
}

class _PriceInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PriceInfo(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.neutral60)),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
