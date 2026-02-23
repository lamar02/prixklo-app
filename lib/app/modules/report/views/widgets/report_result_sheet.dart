import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/report_model.dart';
import '../../controllers/report_controller.dart';

class ReportResultSheet extends StatefulWidget {
  final ReportModel result;
  const ReportResultSheet({super.key, required this.result});

  @override
  State<ReportResultSheet> createState() => _ReportResultSheetState();
}

class _ReportResultSheetState extends State<ReportResultSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _anim, curve: Curves.elasticOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAbus = widget.result.status == 'ABUS';
    final isUnknown = widget.result.status == 'UNKNOWN';

    final color = isAbus
        ? AppColors.abus
        : isUnknown
            ? AppColors.unknown
            : AppColors.success;
    final emoji = isAbus
        ? '🚨'
        : isUnknown
            ? '❓'
            : '✅';
    final label = isAbus
        ? 'Abus détecté'
        : isUnknown
            ? 'Statut inconnu'
            : 'Prix conforme';
    final pointsLabel = isAbus
        ? '+10 points gagnés !'
        : isUnknown
            ? '+2 points gagnés !'
            : '+5 points gagnés !';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 56)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                label,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.result.productName} — ${widget.result.packagingLabel}',
                style: const TextStyle(
                    fontSize: 16, color: AppColors.neutral60),
                textAlign: TextAlign.center,
              ),
              if (widget.result.shopName != null &&
                  widget.result.shopName!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.result.shopName!,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.neutral60),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PricePill(
                    label: 'Observé',
                    value:
                        '${widget.result.observedPrice.toStringAsFixed(0)} FCFA',
                    color: color,
                  ),
                  if (widget.result.maxPrice != null) ...[
                    const SizedBox(width: 12),
                    _PricePill(
                      label: 'Max officiel',
                      value:
                          '${widget.result.maxPrice!.toStringAsFixed(0)} FCFA',
                      color: AppColors.neutral60,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 32),
              // Points gagnés
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      pointsLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: Get.find<ReportController>().resetWizard,
                child: const Text('Nouveau signalement'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: Get.find<ReportController>().viewOnMap,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Voir sur la carte'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: Get.find<ReportController>().resetWizard,
                child: const Text(
                  'Fermer',
                  style: TextStyle(color: AppColors.neutral60),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PricePill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.neutral60)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: color)),
        ],
      ),
    );
  }
}
