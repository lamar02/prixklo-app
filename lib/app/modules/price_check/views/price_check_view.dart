import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/product_model.dart';
import '../controllers/price_check_controller.dart';

class PriceCheckView extends GetView<PriceCheckController> {
  const PriceCheckView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vérifier un prix'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher un produit…',
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
                  child: Text(
                    'Aucun produit trouvé',
                    style: TextStyle(color: AppColors.neutral60),
                  ),
                );
              }
              return ListView.builder(
                itemCount: products.length,
                itemBuilder: (_, i) =>
                    _ProductTile(product: products[i], ctrl: controller),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Tuile produit ──────────────────────────────────────────────────────────

class _ProductTile extends StatelessWidget {
  final ProductModel product;
  final PriceCheckController ctrl;
  const _ProductTile({required this.product, required this.ctrl});

  @override
  Widget build(BuildContext context) {
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
            style:
                const TextStyle(fontSize: 12, color: AppColors.neutral60)),
        trailing: selected
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : null,
        onTap: () {
          ctrl.selectProduct(product);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: AppColors.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (ctx) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: _PackagingPanel(
                    controller: ctrl, product: product),
              ),
            ),
          ).then((_) => ctrl.clearSelection());
        },
      );
    });
  }
}

// ── Panneau packaging + résumé + CTAs ─────────────────────────────────────

class _PackagingPanel extends StatelessWidget {
  final PriceCheckController controller;
  final ProductModel product;
  const _PackagingPanel(
      {required this.controller, required this.product});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ───────────────────────────────────
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
          const SizedBox(height: 12),
          // ── Conditionnement ──────────────────────────────
          Text(
            'Conditionnement — ${product.name}',
            style: const TextStyle(
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
                      selected:
                          controller.selectedPackaging.value?.id == p.id,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color:
                            controller.selectedPackaging.value?.id == p.id
                                ? Colors.white
                                : AppColors.neutral100,
                      ),
                      onSelected: (_) => controller.selectPackaging(p),
                    )))
                .toList(),
          ),
          // ── 1. Prix plafond officiel (affiché en premier) ──
          Obx(() {
            final pkg = controller.selectedPackaging.value;
            if (pkg == null) return const SizedBox.shrink();
            final maxPrice = controller.effectiveMaxPrice;
            return Padding(
              padding: const EdgeInsets.only(top: 14),
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
                            'Chargement…',
                            style: TextStyle(
                                fontSize: 16, color: AppColors.neutral60),
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
          // ── 2. Saisie du prix observé ─────────────────────
          Obx(() {
            final pkg = controller.selectedPackaging.value;
            if (pkg == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Prix affiché en magasin',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral100,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: controller.observedPriceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: false),
                    decoration: const InputDecoration(
                      hintText: 'Ex : 650',
                      suffixText: 'FCFA',
                      prefixIcon: Icon(Icons.storefront_outlined),
                    ),
                    onChanged: (v) {
                      controller.observedPrice.value =
                          double.tryParse(v) ?? 0;
                    },
                  ),
                  const SizedBox(height: 10),
                  // ── 3. Comparaison en temps réel ──────────
                  _PriceComparisonBanner(controller: controller),
                ],
              ),
            );
          }),
          // ── 4. Résumé communautaire (données du quartier) ─
          Obx(() {
            final pkg = controller.selectedPackaging.value;
            if (pkg == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _PriceSummaryCard(controller: controller),
            );
          }),
          // ── 5. Graphique de tendance (30 jours) ───────────
          _PriceHistoryChart(controller: controller),
          // ── CTA — visible uniquement si un prix est saisi ─────
          Obx(() {
            final pkg = controller.selectedPackaging.value;
            if (pkg == null) return const SizedBox.shrink();

            final observed = controller.observedPrice.value;
            // Champ vide → aucun bouton
            if (observed <= 0) return const SizedBox.shrink();

            final maxPrice = controller.effectiveMaxPrice;

            // Plafond inconnu → bouton neutre
            if (maxPrice == null) {
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      controller.launchReport();
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Envoyer le signalement'),
                  ),
                ),
              );
            }

            final isAbus = observed > maxPrice;
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    controller.launchReport();
                  },
                  icon: Icon(
                    isAbus
                        ? Icons.warning_rounded
                        : Icons.check_circle_outline,
                    size: 18,
                  ),
                  label: Text(
                      isAbus ? 'Signaler cet abus' : 'Confirmer ce prix'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isAbus ? AppColors.abus : AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Carte résumé des prix ──────────────────────────────────────────────────

class _PriceSummaryCard extends StatelessWidget {
  final PriceCheckController controller;
  const _PriceSummaryCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.loadingSummary.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }

      if (!controller.hasLocation.value) {
        return _SummaryInfo(
          icon: Icons.location_off_outlined,
          text: 'GPS non disponible — résumé des prix impossible',
          color: AppColors.neutral60,
        );
      }

      final s = controller.priceSummary.value;
      if (s == null) return const SizedBox.shrink();

      if (s.count == 0) {
        return _SummaryInfo(
          icon: Icons.info_outline,
          text:
              'Aucun signalement dans un rayon de ${s.radiusKm} km. Soyez le premier !',
          color: AppColors.neutral60,
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
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
                    _StatChip(
                        label: 'Moy. observé',
                        value: '${s.avg!.toStringAsFixed(0)} FCFA',
                        color: statusColor),
                  if (s.officialMaxPrice != null) ...[
                    const SizedBox(width: 8),
                    _StatChip(
                        label: 'Max officiel',
                        value:
                            '${s.officialMaxPrice!.toStringAsFixed(0)} FCFA',
                        color: AppColors.neutral60),
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

class _SummaryInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _SummaryInfo(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 12, color: color)),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.neutral60)),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

// ── Bannière de comparaison prix observé vs max officiel ──────────────────

class _PriceComparisonBanner extends StatelessWidget {
  final PriceCheckController controller;
  const _PriceComparisonBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final observed = controller.observedPrice.value;
      if (observed <= 0) return const SizedBox.shrink();

      final officialMax = controller.effectiveMaxPrice;
      if (officialMax == null) {
        return _Banner(
          color: AppColors.neutral60,
          icon: Icons.info_outline,
          text: 'Prix plafond officiel non disponible pour ce produit.',
        );
      }

      final isAbus = observed > officialMax;
      final diff = (observed - officialMax).abs();
      final pct = ((diff / officialMax) * 100).toStringAsFixed(0);

      return _Banner(
        color: isAbus ? AppColors.abus : AppColors.success,
        icon: isAbus ? Icons.warning_rounded : Icons.check_circle_rounded,
        text: isAbus
            ? '🚨 +$pct% au-dessus du plafond — Abus probable'
            : '✅ Dans la limite du plafond — Prix conforme',
      );
    });
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  const _Banner(
      {required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Graphique de tendance 30 jours ─────────────────────────────────────────

class _PriceHistoryChart extends StatelessWidget {
  final PriceCheckController controller;
  const _PriceHistoryChart({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.hasLocation.value) return const SizedBox.shrink();

      final history =
          controller.priceHistory.where((e) => e.avg != null).toList();
      if (history.isEmpty) return const SizedBox.shrink();

      final maxPrice = controller.effectiveMaxPrice;
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
                        Text(
                          'Plafond',
                          style: TextStyle(
                              fontSize: 9, color: AppColors.abus),
                        ),
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
                      horizontalInterval:
                          ((chartMax - chartMin) / 3).clamp(1, double.infinity),
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
                            final parts =
                                history[idx].weekStart.split('-');
                            if (parts.length < 3) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${parts[2]}/${parts[1]}',
                                style: const TextStyle(
                                    fontSize: 8,
                                    color: AppColors.neutral60),
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
                            .map((e) =>
                                FlSpot(e.key.toDouble(), e.value.avg!))
                            .toList(),
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 2,
                        dotData: FlDotData(
                            show: history.length <= 5),
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
