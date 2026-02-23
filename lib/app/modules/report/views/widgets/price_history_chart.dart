import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/price_history_model.dart';

class PriceHistoryChart extends StatelessWidget {
  final List<PriceHistoryEntry> history;

  const PriceHistoryChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final valid = history.where((e) => e.avg != null).toList();

    if (valid.isEmpty) {
      return const Center(
        child: Text(
          'Pas encore de données de tendance',
          style: TextStyle(color: AppColors.neutral60),
        ),
      );
    }

    final spots = valid.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.avg!))
        .toList();

    final maxY = valid.map((e) => e.avg!).reduce((a, b) => a > b ? a : b);
    final minY = valid.map((e) => e.avg!).reduce((a, b) => a < b ? a : b);
    final pad = valid.length > 1 ? (maxY - minY) * 0.25 : maxY * 0.1;

    return LineChart(
      LineChartData(
        minY: (minY - pad).clamp(0, double.infinity),
        maxY: maxY + pad,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.neutral20,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= valid.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _fmtWeek(valid[i].weekStart),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.neutral60),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Text(
                  _fmtPrice(value),
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.neutral60),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: valid.length > 2,
            color: AppColors.primary,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withAlpha(30),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtWeek(String weekStart) {
    try {
      final d = DateTime.parse(weekStart);
      final day = d.day.toString().padLeft(2, '0');
      final month = d.month.toString().padLeft(2, '0');
      return '$day/$month';
    } catch (_) {
      return '';
    }
  }

  String _fmtPrice(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }
}
