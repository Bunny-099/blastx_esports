import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/tournament_model.dart';

/// ============================================================
/// TOURNAMENT ROADMAP / BRACKET WIDGET
/// Displays Stage Progression (e.g., Round 1 -> Semi Finals -> Finals),
/// team statuses, cut-marks (❌) for eliminated teams, and winner crown.
/// ============================================================

class TournamentRoadmapWidget extends StatefulWidget {
  const TournamentRoadmapWidget({
    super.key,
    required this.tournament,
    required this.accentColor,
  });

  final TournamentModel tournament;
  final Color accentColor;

  @override
  State<TournamentRoadmapWidget> createState() =>
      _TournamentRoadmapWidgetState();
}

class _TournamentRoadmapWidgetState extends State<TournamentRoadmapWidget> {
  int _selectedStageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final stages = widget.tournament.effectiveStages;
    if (stages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('Roadmap details unavailable.',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    if (_selectedStageIndex >= stages.length) {
      _selectedStageIndex = 0;
    }

    final currentStage = stages[_selectedStageIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Stage Navigation Stepper ──
        _buildStageStepper(stages),

        const SizedBox(height: 16),

        // ── Stage Summary Banner ──
        _buildStageHeader(currentStage),

        const SizedBox(height: 16),

        // ── Team Progression List ──
        if (currentStage.teams.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text('No team data for this stage yet.',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: currentStage.teams.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final team = currentStage.teams[index];
              return _BracketTeamTile(
                team: team,
                accentColor: widget.accentColor,
              );
            },
          ),

        const SizedBox(height: 24),

        // ── Roadmap Progression Info Footer ──
        _buildRoadmapSummaryCard(stages),
      ],
    );
  }

  // ── Stage Stepper Navigation ──
  Widget _buildStageStepper(List<BracketStageModel> stages) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(stages.length, (index) {
          final stage = stages[index];
          final isSelected = index == _selectedStageIndex;
          final isLast = index == stages.length - 1;

          return Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedStageIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? widget.accentColor.withValues(alpha: 0.2)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? widget.accentColor : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: widget.accentColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? widget.accentColor
                              : AppColors.surfaceMuted,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        stage.stageName,
                        style: AppTextStyles.bodySm.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textMuted.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }

  // ── Stage Header ──
  Widget _buildStageHeader(BracketStageModel stage) {
    final activeCount = stage.teams.where((t) => !t.isEliminated).length;
    final elimCount = stage.teams.where((t) => t.isEliminated).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded,
              color: widget.accentColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.stageName.toUpperCase(),
                  style: AppTextStyles.headingMd.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${stage.teams.length} Teams Total • $activeCount Qualified • $elimCount Eliminated',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Progression Summary Card ──
  Widget _buildRoadmapSummaryCard(List<BracketStageModel> stages) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            widget.accentColor.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alt_route_rounded,
                  color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                'TOURNAMENT ROADMAP',
                style: AppTextStyles.headingMd.copyWith(color: AppColors.gold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Teams are filtered out round-by-round. Eliminated teams (❌) are removed from the next stage until the Champion is crowned!',
            style: AppTextStyles.bodySm,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: stages.map((s) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceMuted,
                      border: Border.all(color: widget.accentColor),
                    ),
                    child: Text(
                      '${s.teams.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.stageName.split(' ').first,
                    style: AppTextStyles.caption,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Single Team Bracket Card Widget ──
class _BracketTeamTile extends StatelessWidget {
  const _BracketTeamTile({
    required this.team,
    required this.accentColor,
  });

  final BracketTeamModel team;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isEliminated = team.isEliminated;
    final isWinner = team.isWinner;
    final isQualified = team.isQualified;

    final borderColor = isWinner
        ? AppColors.gold
        : isEliminated
            ? AppColors.error.withValues(alpha: 0.4)
            : isQualified
                ? AppColors.success.withValues(alpha: 0.6)
                : AppColors.border;

    final bgColor = isWinner
        ? AppColors.gold.withValues(alpha: 0.12)
        : isEliminated
            ? AppColors.error.withValues(alpha: 0.05)
            : AppColors.surface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isWinner ? 1.5 : 1),
      ),
      child: Row(
        children: [
          // ── Rank Badge / Crown ──
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isWinner
                  ? AppColors.gold
                  : isEliminated
                      ? AppColors.error.withValues(alpha: 0.2)
                      : AppColors.surfaceMuted,
            ),
            alignment: Alignment.center,
            child: isWinner
                ? const Icon(Icons.emoji_events, color: Colors.black, size: 16)
                : Text(
                    '${team.rank > 0 ? team.rank : '#'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isEliminated ? AppColors.error : Colors.white,
                    ),
                  ),
          ),

          const SizedBox(width: 12),

          // ── Team Info & Name ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        team.name,
                        style: AppTextStyles.bodyLg.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isEliminated
                              ? AppColors.textMuted
                              : Colors.white,
                          decoration: isEliminated
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: AppColors.error,
                        ),
                      ),
                    ),
                    if (isWinner) ...[
                      const SizedBox(width: 6),
                      const Text('👑 WINNER',
                          style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${team.points} pts • ${team.kills} kills',
                  style: AppTextStyles.caption.copyWith(
                    color: isEliminated
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── Status Tag / Cross Mark (❌) ──
          if (isWinner)
            _StatusChip(
              label: 'CHAMPION',
              icon: Icons.workspace_premium_rounded,
              color: AppColors.gold,
            )
          else if (isEliminated)
            _StatusChip(
              label: 'ELIMINATED',
              icon: Icons.cancel_rounded,
              color: AppColors.error,
              isCrossMark: true,
            )
          else if (isQualified)
            _StatusChip(
              label: 'QUALIFIED',
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
            )
          else
            _StatusChip(
              label: 'PLAYING',
              icon: Icons.sports_esports_rounded,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.color,
    this.isCrossMark = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isCrossMark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
