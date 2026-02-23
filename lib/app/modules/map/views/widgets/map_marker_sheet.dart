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
    final (Color statusColor, String statusLabel) = switch (marker.status) {
      'ABUS' => (AppColors.abus, '🚨 ABUS'),
      'CONFORME' => (AppColors.success, '✅ CONFORME'),
      'LIMITE' => (AppColors.primary, '⚠️ LIMITE'),
      _ => (AppColors.unknown, '❓ INCONNU'),
    };
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
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
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
                color: statusColor,
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
          // ── CTA ────────────────────────────────────────────
          if (marker.packagingId != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _launchReport,
                icon: const Icon(Icons.flag_outlined, size: 16),
                label: const Text('Signaler ce produit ici'),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _launchReport() {
    final reportCtrl = Get.find<ReportController>();
    for (final product in reportCtrl.products) {
      for (final pkg in product.packagings) {
        if (pkg.id == marker.packagingId) {
          reportCtrl.preSelect(product, pkg);
          Get.find<MainNavController>().goToReport();
          Get.back();
          return;
        }
      }
    }
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
