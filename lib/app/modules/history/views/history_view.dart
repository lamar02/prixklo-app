import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../controllers/history_controller.dart';

class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mes signalements')),
      body: Obx(() {
        if (controller.isLoading.value && controller.reports.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.reports.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('📋', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text('Aucun signalement pour l\'instant',
                    style: TextStyle(color: AppColors.neutral60)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchReports(refresh: true),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.reports.length +
                (controller.hasMore.value ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              if (i >= controller.reports.length) {
                // Charger la page suivante quand on atteint la fin
                WidgetsBinding.instance.addPostFrameCallback(
                    (_) => controller.fetchReports());
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final report = controller.reports[i];
              final (Color statusColor, String statusEmoji) = switch (report.status) {
                'ABUS' => (AppColors.abus, '🚨'),
                'CONFORME' => (AppColors.success, '✅'),
                'LIMITE' => (AppColors.primary, '⚠️'),
                _ => (AppColors.unknown, '❓'),
              };
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(color: statusColor, width: 4),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      statusEmoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${report.productName} — ${report.packagingLabel}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${report.observedPrice.toStringAsFixed(0)} FCFA'
                            '${report.maxPrice != null ? '  •  Max: ${report.maxPrice!.toStringAsFixed(0)} FCFA' : ''}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.neutral60),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormatter.relative(report.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.neutral60),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
