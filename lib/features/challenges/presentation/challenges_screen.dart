import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/challenge_model.dart';
import '../providers/challenges_provider.dart';
import 'widgets/active_recording_overlay.dart';
import 'widgets/challenge_card.dart';
import 'widgets/challenge_header.dart';

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allChallenges = ref.watch(challengesProvider);
    final activeFilter = ref.watch(activeFilterTypeProvider);
    final activeRecordingId = ref.watch(activeRecordingChallengeIdProvider);
    final isUploading = ref.watch(isUploadingProofProvider);

    // Filter challenges based on selected tab
    final filteredChallenges = activeFilter == null
        ? allChallenges
        : allChallenges.where((c) => c.type == activeFilter).toList();

    final completedCount = allChallenges.where((c) => c.isCompleted || c.isClaimed).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glow Effect
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.ambientGlowOrange,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Screen Title and Reset Countdown Header
                const ChallengeHeader(),

                // Active Recording Banner Overlay (shown when match recording or uploading)
                if (activeRecordingId != null || isUploading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: ActiveRecordingOverlay(),
                  ),

                // Category Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'ALL (${allChallenges.length})',
                          isSelected: activeFilter == null,
                          onTap: () {
                            ref.read(activeFilterTypeProvider.notifier).state = null;
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'DAILY',
                          isSelected: activeFilter == ChallengeType.daily,
                          onTap: () {
                            ref.read(activeFilterTypeProvider.notifier).state = ChallengeType.daily;
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'WEEKLY',
                          isSelected: activeFilter == ChallengeType.weekly,
                          onTap: () {
                            ref.read(activeFilterTypeProvider.notifier).state = ChallengeType.weekly;
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'SPECIAL',
                          isSelected: activeFilter == ChallengeType.special,
                          onTap: () {
                            ref.read(activeFilterTypeProvider.notifier).state = ChallengeType.special;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Missions Summary Title Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: AppColors.fireGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'AVAILABLE MISSIONS',
                        style: AppTextStyles.headingLg,
                      ),
                      const Spacer(),
                      Text(
                        '$completedCount/${allChallenges.length} COMPLETED',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Challenge List View with Pull To Refresh
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryNeon,
                    backgroundColor: AppColors.surfaceNavy,
                    onRefresh: () async {
                      await ref.read(challengesProvider.notifier).loadChallenges();
                    },
                    child: filteredChallenges.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 80),
                              Center(
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.sports_esports_outlined,
                                      size: 56,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No challenges available in this category.',
                                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                            itemCount: filteredChallenges.length,
                            itemBuilder: (context, index) {
                              final challenge = filteredChallenges[index];
                              return ChallengeCard(
                                challenge: challenge,
                                onClaim: () {
                                  ref.read(claimChallengeProvider)(challenge.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppColors.surfaceNavy,
                                      content: Row(
                                        children: [
                                          const Icon(Icons.star, color: AppColors.gold, size: 20),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Claimed ${challenge.rewardXP} XP! ⭐',
                                            style: AppTextStyles.bodyMd.copyWith(color: AppColors.gold),
                                          ),
                                        ],
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ).animate(delay: (80 * index).ms)
                               .fadeIn(duration: 400.ms)
                               .slideY(begin: 0.1, end: 0);
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNeon : AppColors.surfaceNavy,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryNeon : AppColors.borderSubtle,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryNeon.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? AppColors.bgNavy : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
