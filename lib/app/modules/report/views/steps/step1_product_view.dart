import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/product_model.dart';
import '../../controllers/report_controller.dart';

class Step1ProductView extends GetView<ReportController> {
  const Step1ProductView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher un produit...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => controller.searchQuery.value = v,
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.productsLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final products = controller.filteredProducts;
            if (products.isEmpty) {
              return const Center(
                child: Text('Aucun produit trouvé',
                    style: TextStyle(color: AppColors.neutral60)),
              );
            }
            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (_, i) => _ProductTile(
                product: products[i],
                onTap: () => _showSheet(context, products[i]),
              ),
            );
          }),
        ),
      ],
    );
  }

  void _showSheet(BuildContext context, ProductModel product) {
    controller.selectProduct(product);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SingleChildScrollView(
        child: _PackagingSheet(product: product, ctrl: controller),
      ),
    );
  }
}

// ── Tuile produit ──────────────────────────────────────────────────────────

class _ProductTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  const _ProductTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ReportController>();
    return Obx(() {
      final selected = ctrl.selectedProduct.value?.id == product.id;
      return ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withAlpha(25)
                : AppColors.neutral10,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primary : AppColors.neutral60,
              ),
            ),
          ),
        ),
        title: Text(product.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(product.category,
            style: const TextStyle(fontSize: 12, color: AppColors.neutral60)),
        trailing: selected
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : null,
        onTap: onTap,
      );
    });
  }
}

// ── Bottom sheet : packaging + contexte prix ───────────────────────────────

class _PackagingSheet extends StatelessWidget {
  final ProductModel product;
  final ReportController ctrl;
  const _PackagingSheet({required this.product, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
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
          const SizedBox(height: 14),
          // Titre
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.neutral100,
            ),
          ),
          Text(
            product.category,
            style: const TextStyle(fontSize: 13, color: AppColors.neutral60),
          ),
          const SizedBox(height: 14),
          // ── 1. Conditionnement ────────────────────────────
          const Text(
            'Conditionnement',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.neutral100,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: product.packagings
                .map((p) => Obx(() => ChoiceChip(
                      label: Text(p.label),
                      selected: ctrl.selectedPackaging.value?.id == p.id,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: ctrl.selectedPackaging.value?.id == p.id
                            ? Colors.white
                            : AppColors.neutral100,
                      ),
                      onSelected: (_) => ctrl.selectPackaging(p),
                    )))
                .toList(),
          ),
          // ── 2. Prix plafond officiel ───────────────────────
          Obx(() {
            final pkg = ctrl.selectedPackaging.value;
            if (pkg == null) return const SizedBox.shrink();
            final maxPrice = ctrl.effectiveMaxPrice;
            return Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(12),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.primary.withAlpha(50)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
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
                      ],
                    ),
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
                            'Non disponible pour ce produit',
                            style: TextStyle(
                                fontSize: 14, color: AppColors.neutral60),
                          ),
                    const SizedBox(height: 2),
                    const Text(
                      'Ne devrait pas dépasser ce montant',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.neutral60),
                    ),
                  ],
                ),
              ),
            );
          }),
          // ── 3. Résumé communautaire ────────────────────────
          Obx(() {
            final pkg = ctrl.selectedPackaging.value;
            if (pkg == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _SummaryCard(ctrl: ctrl),
            );
          }),
          // ── 4. Graphique 30 jours ──────────────────────────
          _HistoryChart(ctrl: ctrl),
          // ── 5. Bouton Continuer ───────────────────────────
          const SizedBox(height: 16),
          Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: ctrl.selectedPackaging.value != null
                      ? () {
                          Navigator.of(context).pop();
                          ctrl.goToStep(1);
                        }
                      : null,
                  child: const Text('Continuer'),
                ),
              )),
        ],
      ),
    );
  }
}

// ── Résumé communautaire ───────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final ReportController ctrl;
  const _SummaryCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.loadingSummary.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }

      if (!ctrl.hasLocation.value) {
        return Row(
          children: [
            const Icon(Icons.location_searching,
                size: 16, color: AppColors.neutral60),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                ctrl.isLocating.value
                    ? 'Localisation en cours…'
                    : 'GPS non disponible — résumé impossible',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.neutral60),
              ),
            ),
          ],
        );
      }

      final s = ctrl.priceSummary.value;
      if (s == null) return const SizedBox.shrink();

      if (s.count == 0) {
        return Row(
          children: [
            const Icon(Icons.info_outline,
                size: 16, color: AppColors.neutral60),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Aucun signalement dans un rayon de ${s.radiusKm} km. Soyez le premier !',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.neutral60),
              ),
            ),
          ],
        );
      }

      final status = s.dominantStatus ?? 'CONFORME';
      final isAbus = status == 'ABUS';
      final statusColor = isAbus ? AppColors.abus : AppColors.success;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: statusColor.withAlpha(12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAbus ? '🚨 Abus fréquents' : '✅ Prix conformes',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${s.count} signalement${s.count > 1 ? 's' : ''} (${s.radiusKm} km)',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.neutral60),
                ),
              ],
            ),
            if (s.avg != null || s.officialMaxPrice != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (s.avg != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Moy. observé',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.neutral60)),
                        Text('${s.avg!.toStringAsFixed(0)} FCFA',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: statusColor)),
                      ],
                    ),
                  if (s.officialMaxPrice != null) ...[
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Max officiel',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.neutral60)),
                        Text(
                            '${s.officialMaxPrice!.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.neutral60)),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      );
    });
  }
}

// ── Graphique 30 jours ─────────────────────────────────────────────────────

class _HistoryChart extends StatelessWidget {
  final ReportController ctrl;
  const _HistoryChart({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!ctrl.hasLocation.value) return const SizedBox.shrink();
      final history =
          ctrl.priceHistory.where((e) => e.avg != null).toList();
      if (history.isEmpty) return const SizedBox.shrink();

      final maxPrice = ctrl.effectiveMaxPrice;
      final avgValues = history.map((e) => e.avg!).toList();
      final allValues = [...avgValues, ?maxPrice];
      final dataMax = allValues.reduce((a, b) => a > b ? a : b);
      final dataMin = allValues.reduce((a, b) => a < b ? a : b);
      final padding = (dataMax - dataMin) * 0.15;
      final chartMax = dataMax + padding;
      final chartMin = (dataMin - padding).clamp(0, double.infinity);

      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 14, 16, 10),
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
                  const Icon(Icons.show_chart_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  const Text(
                    'Tendance des prix — 30 jours',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral100,
                    ),
                  ),
                  const Spacer(),
                  if (maxPrice != null)
                    Row(
                      children: [
                        Container(
                            width: 12,
                            height: 2,
                            color: AppColors.abus.withAlpha(180)),
                        const SizedBox(width: 4),
                        Text('Plafond',
                            style:
                                TextStyle(fontSize: 9, color: AppColors.abus)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 90,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: ((chartMax - chartMin) / 3)
                          .clamp(1, double.infinity),
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppColors.neutral20,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 18,
                          getTitlesWidget: (value, _) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= history.length) {
                              return const SizedBox.shrink();
                            }
                            final parts = history[idx].weekStart.split('-');
                            if (parts.length < 3) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${parts[2]}/${parts[1]}',
                                style: const TextStyle(
                                    fontSize: 8, color: AppColors.neutral60),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (history.length - 1).toDouble(),
                    minY: chartMin.toDouble(),
                    maxY: chartMax,
                    lineBarsData: [
                      LineChartBarData(
                        spots: history
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value.avg!))
                            .toList(),
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 2,
                        dotData: FlDotData(show: history.length <= 5),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withAlpha(20),
                        ),
                      ),
                    ],
                    extraLinesData: maxPrice != null
                        ? ExtraLinesData(
                            horizontalLines: [
                              HorizontalLine(
                                y: maxPrice,
                                color: AppColors.abus.withAlpha(180),
                                strokeWidth: 1.5,
                                dashArray: [6, 3],
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
