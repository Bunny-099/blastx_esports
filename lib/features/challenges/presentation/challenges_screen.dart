import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/challenges_provider.dart';
import 'widgets/challenge_card.dart';
import 'widgets/challenge_header.dart';
import 'widgets/progress_summary_card.dart';

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(challengesProvider);
    final totalProgress = ref.watch(dailyProgressProvider);
    final completedCount = challenges.where((c) => c.isCompleted).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glow
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
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: ChallengeHeader(),
                ),
                
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: ProgressSummaryCard(
                      progress: totalProgress,
                      completedCount: completedCount,
                      totalCount: challenges.length,
                    ),
                  ),
                ),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
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
                          'MISSIONS',
                          style: AppTextStyles.headingLg,
                        ),
                        const Spacer(),
                        Text(
                          '$completedCount/${challenges.length} COMPLETED',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final challenge = challenges[index];
                        return ChallengeCard(
                          challenge: challenge,
                          onClaim: () {
                            ref.read(claimChallengeProvider)(challenge.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.surface,
                                content: Text(
                                  'Claimed ${challenge.rewardCoins} Coins! 🪙',
                                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.gold),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          onGo: () {
                            // Navigation logic would go here
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Opening ${challenge.game}...'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ).animate(delay: (100 * index).ms)
                         .fadeIn(duration: 500.ms)
                         .slideX(begin: 0.1, end: 0);
                      },
                      childCount: challenges.length,
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
