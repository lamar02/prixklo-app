import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/report_model.dart';
import '../../controllers/verify_controller.dart';

class VerifyResultScreen extends StatefulWidget {
  final ReportModel result;
  const VerifyResultScreen({super.key, required this.result});

  @override
  State<VerifyResultScreen> createState() => _VerifyResultScreenState();
}

class _VerifyResultScreenState extends State<VerifyResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scale = CurvedAnimation(parent: _anim, curve: Curves.elasticOut);
    _anim.forward();
    _fade = CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final isConfirmation =
        Get.find<VerifyController>().reportType == 'CONFIRMATION';

    final (Color color, String emoji, String label, String pointsLabel) =
        switch (r.status) {
      'ABUS' => (AppColors.abus, '🚨', 'Abus détecté', '+10 pts'),
      'LIMITE' => (AppColors.primary, '⚠️', 'Prix à la limite', '+7 pts'),
      'CONFORME' => (AppColors.success, '✅', 'Prix conforme', '+5 pts'),
      _ => (AppColors.unknown, '❓', 'Statut inconnu', '+2 pts'),
    };

    final displayPoints = isConfirmation ? '+3 pts' : pointsLabel;
    final displayLabel =
        isConfirmation ? 'Confirmation enregistrée' : label;

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
                  child:
                      Center(child: Text(emoji, style: const TextStyle(fontSize: 56))),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fade,
                child: Column(
                  children: [
                    Text(
                      displayLabel,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${r.productName} — ${r.packagingLabel}',
                      style: const TextStyle(
                          fontSize: 15, color: AppColors.neutral60),
                      textAlign: TextAlign.center,
                    ),
                    if (r.shopName != null && r.shopName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        r.shopName!,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.neutral60),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PricePill(
                          label: 'Observé',
                          value: '${r.observedPrice.toStringAsFixed(0)} FCFA',
                          color: color,
                        ),
                        if (r.maxPrice != null) ...[
                          const SizedBox(width: 12),
                          _PricePill(
                            label: 'Max officiel',
                            value:
                                '${r.maxPrice!.toStringAsFixed(0)} FCFA',
                            color: AppColors.neutral60,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'PrixKlo n\'est pas une application officielle du gouvernement.',
                      style: TextStyle(fontSize: 11, color: AppColors.neutral60),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () => launchUrl(
                        Uri.parse('https://www.commerce.gouv.ci/'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: const Text(
                        'Source : Ministère du Commerce, CI ↗',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
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
                            '$displayPoints gagnés !',
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
                      onPressed: Get.find<VerifyController>().resetFlow,
                      child: const Text('Nouveau signalement'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: Get.find<VerifyController>().resetFlow,
                      child: const Text('Fermer'),
                    ),
                  ],
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
  const _PricePill({required this.label, required this.value, required this.color});

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
              style: const TextStyle(fontSize: 10, color: AppColors.neutral60)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14, color: color)),
        ],
      ),
    );
  }
}
