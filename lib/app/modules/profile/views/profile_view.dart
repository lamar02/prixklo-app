import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon Profil'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: controller.logout,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = controller.authCtrl.user.value;
        return RefreshIndicator(
          onRefresh: controller.fetchProfile,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Avatar + nom
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user?.name.isNotEmpty == true
                              ? user!.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.name ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neutral100,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                          color: AppColors.neutral60, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Points + niveau
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Points',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            Text(
                              '${controller.points.value}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Niveau ${controller.level.value}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: controller.levelProgress,
                        backgroundColor: Colors.white.withAlpha(50),
                        color: Colors.white,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${controller.points.value} / ${controller.nextLevelPoints} pts pour le niveau suivant',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ── Métriques d'impact ──────────────────────
              Obx(() => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.neutral20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mon impact',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.neutral100,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _ImpactStat(
                              emoji: '📢',
                              value:
                                  '${controller.totalReports.value}',
                              label: 'signalements',
                            ),
                            const SizedBox(width: 12),
                            _ImpactStat(
                              emoji: '👥',
                              value:
                                  '~${controller.peopleInformed}',
                              label: 'personnes informées',
                            ),
                            const SizedBox(width: 12),
                            _ImpactStat(
                              emoji: '✅',
                              value:
                                  '${controller.confirmationsCount.value}',
                              label: 'confirmations',
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              // Signalements en attente
              Obx(() {
                final count = controller.pendingCount.value;
                if (count == 0) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_upload_outlined,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$count signalement${count > 1 ? 's' : ''} en attente',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.neutral100,
                              ),
                            ),
                            const Text(
                              'En attente de connexion pour être envoyés.',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.neutral60),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: controller.flushPendingReports,
                        child: const Text('Envoyer'),
                      ),
                    ],
                  ),
                );
              }),
              // Badges
              if (controller.badges.isNotEmpty) ...[
                const Text(
                  'Mes badges',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral100,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: controller.badges.length,
                  itemBuilder: (_, i) {
                    final badge = controller.badges[i];
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.neutral20),
                      ),
                      child: Row(
                        children: [
                          Text(badge.emoji,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              badge.name,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutral100,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
              // Actions
              _ActionTile(
                icon: Icons.history_rounded,
                label: 'Mes signalements',
                onTap: controller.goToHistory,
              ),
              const Divider(height: 1),
              _ActionTile(
                icon: Icons.leaderboard_rounded,
                label: 'Classement',
                onTap: controller.goToLeaderboard,
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }
}

class _ImpactStat extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _ImpactStat(
      {required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.neutral100,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.neutral60),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: AppColors.surface,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.neutral60),
      onTap: onTap,
    );
  }
}
