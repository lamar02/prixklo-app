import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../data/models/map_marker_model.dart';

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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (isAbus ? AppColors.abus : AppColors.success).withAlpha(25),
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
        ],
      ),
    );
  }
}

class _PriceInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PriceInfo({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.neutral60)),
        Text(value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
