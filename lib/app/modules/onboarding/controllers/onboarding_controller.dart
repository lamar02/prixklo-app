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
      title: 'Vérifie les prix\nautour de toi',
      subtitle:
          'Consultez les prix officiels et signalez les abus dans votre quartier.',
      emoji: '🔍',
      color: Color(0xFFF97316),
    ),
    OnboardingPage(
      title: 'Signale en\n30 secondes',
      subtitle:
          'Choisissez le produit, entrez le prix observé, envoyez. C\'est tout.',
      emoji: '⚡',
      color: Color(0xFF1E3A5F),
    ),
    OnboardingPage(
      title: 'Gagne des points\nen aidant ta communauté',
      subtitle:
          'Chaque signalement rapporte des points et débloque des badges.',
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
