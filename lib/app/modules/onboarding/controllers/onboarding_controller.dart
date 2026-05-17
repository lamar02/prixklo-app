import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../services/storage_service.dart';

class OnboardingPage {
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;

  const OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
  });
}

class OnboardingController extends GetxController {
  final _storage = Get.find<StorageService>();
  final pageController = PageController();
  final RxInt currentPage = 0.obs;

  final List<OnboardingPage> pages = const [
    OnboardingPage(
      title: 'Vérifiez avant\nd\'acheter',
      subtitle:
          'Scannez le prix d\'un produit, comparez avec le plafond officiel et sachez immédiatement si vous payez trop cher.',
      emoji: '🔍',
      color: Color(0xFFF7374F),
    ),
    OnboardingPage(
      title: 'Signalez les abus\nen 30 secondes',
      subtitle:
          'Un prix trop élevé ? Entrez le montant, confirmez votre position, envoyez. Votre signalement protège tout votre quartier.',
      emoji: '🚨',
      color: Color(0xFF000000),
    ),
    OnboardingPage(
      title: 'Ensemble,\non change les prix',
      subtitle:
          'Chaque signalement informe des dizaines de voisins. Gagnez des points, débloquez des badges, et devenez le héros de votre communauté.',
      emoji: '🏆',
      color: Color(0xFF16A34A),
    ),
  ];

  void onPageChanged(int index) => currentPage.value = index;

  void nextPage() {
    if (currentPage.value < pages.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      finish();
    }
  }

  Future<void> finish() async {
    await _storage.markOnboardingDone();
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
