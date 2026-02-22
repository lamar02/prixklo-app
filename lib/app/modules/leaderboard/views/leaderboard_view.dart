import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../modules/auth/controllers/auth_controller.dart';
import '../controllers/leaderboard_controller.dart';

class LeaderboardView extends GetView<LeaderboardController> {
  const LeaderboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Classement')),
      body: Column(
        children: [
          // Filtre période
          Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(() => SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('Global')),
                    ButtonSegment(value: 'week', label: Text('Semaine')),
                    ButtonSegment(value: 'month', label: Text('Mois')),
                  ],
                  selected: {controller.period.value},
                  onSelectionChanged: (s) => controller.period.value = s.first,
                )),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.entries.isEmpty) {
                return const Center(
                  child: Text('Aucun résultat',
                      style: TextStyle(color: AppColors.neutral60)),
                );
              }
              final currentUserId =
                  Get.find<AuthController>().user.value?.id;
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.entries.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final entry = controller.entries[i];
                  final isMe = entry.id == currentUserId;
                  final rank = i + 1;
                  return Container(
                    color: isMe
                        ? AppColors.primary.withAlpha(15)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            _rankEmoji(rank),
                            style: const TextStyle(fontSize: 20),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isMe
                                ? AppColors.primary
                                : AppColors.neutral20,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              entry.name.isNotEmpty
                                  ? entry.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isMe
                                    ? Colors.white
                                    : AppColors.neutral60,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMe ? '${entry.name} (moi)' : entry.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isMe
                                      ? AppColors.primary
                                      : AppColors.neutral100,
                                ),
                              ),
                              if (entry.reportCount != null)
                                Text(
                                  '${entry.reportCount} signalements',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.neutral60),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          entry.reportCount != null
                              ? '${entry.reportCount} 📝'
                              : '${entry.points} pts',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isMe
                                ? AppColors.primary
                                : AppColors.neutral100,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  String _rankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank';
    }
  }
}
