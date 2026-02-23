import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/map_marker_model.dart';
import '../../../modules/main_nav/controllers/main_nav_controller.dart';
import '../../../modules/notifications/controllers/notifications_controller.dart';
import '../../../routes/app_routes.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.fetchHomeData,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: AppColors.surface,
                surfaceTintColor: Colors.transparent,
                title: Obx(() => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour, ${controller.authCtrl.user.value?.name.split(' ').first ?? 'Citoyen'} 👋',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.neutral100,
                          ),
                        ),
                        const Text(
                          'Abidjan, Côte d\'Ivoire',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.neutral60),
                        ),
                      ],
                    )),
                actions: [
                  Obx(() {
                    final notifCtrl = Get.find<NotificationsController>();
                    final count = notifCtrl.unreadCount;
                    return IconButton(
                      onPressed: () =>
                          Get.toNamed(AppRoutes.notifications),
                      icon: Badge(
                        isLabelVisible: count > 0,
                        label: Text(count > 9 ? '9+' : '$count'),
                        child: const Icon(Icons.notifications_outlined),
                      ),
                    );
                  }),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Barre de recherche principale ──────
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.priceCheck),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.primary, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(20),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search,
                                  color: AppColors.primary, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Vérifier le prix d\'un produit…',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.neutral60,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Vérifier',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ── Gamification ────────────────────────
                      _GamificationCard(controller: controller),
                      const SizedBox(height: 24),
                      const Text(
                        'Abus récents près de toi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutral100,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              Obx(() {
                if (controller.isLoading.value) {
                  return const SliverToBoxAdapter(
                    child: Center(
                        child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    )),
                  );
                }
                if (controller.recentAbuses.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Aucun abus signalé récemment 🎉',
                          style: TextStyle(color: AppColors.neutral60),
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final m = controller.recentAbuses[i];
                        return _AbuseCard(marker: m);
                      },
                      childCount: controller.recentAbuses.length,
                    ),
                  ),
                );
              }),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

}

class _GamificationCard extends StatelessWidget {
  final HomeController controller;
  const _GamificationCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mes points',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(
                    '${controller.points.value} pts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Niveau ${controller.level.value}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              const Spacer(),
              if (controller.latestBadge.value != null)
                Column(
                  children: [
                    Text(
                      controller.latestBadge.value!.emoji,
                      style: const TextStyle(fontSize: 36),
                    ),
                    Text(
                      controller.latestBadge.value!.name,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              else
                const Text('🌟', style: TextStyle(fontSize: 36)),
            ],
          ),
        ));
  }
}

class _AbuseCard extends StatelessWidget {
  final MapMarkerModel marker;
  const _AbuseCard({required this.marker});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.find<MainNavController>().goToMap(),
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
            left: BorderSide(color: AppColors.abus, width: 4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: AppColors.abus, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${marker.productName} — ${marker.packagingLabel}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Observé: ${marker.observedPrice.toStringAsFixed(0)} FCFA  •  Max: ${marker.maxPrice.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.neutral60),
                ),
              ],
            ),
          ),
          Text(
            DateFormatter.relative(marker.createdAt),
            style:
                const TextStyle(fontSize: 11, color: AppColors.neutral60),
          ),
        ],
      ),
    ),
    );
  }
}

