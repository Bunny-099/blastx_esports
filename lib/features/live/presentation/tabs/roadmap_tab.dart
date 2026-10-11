import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../tournaments/data/models/tournament_format_models.dart';
import '../../data/models/tournament_model.dart';
import '../../providers/live_provider.dart';

/// ============================================================
/// ROADMAP TAB
/// Interactive multi-stage progress flow (Stage 1 -> Stage 2 -> Grand Final)
/// Displays lobby counts, units per lobby, and qualification cutoffs.
/// ============================================================

class RoadmapTab extends ConsumerStatefulWidget {
  const RoadmapTab({
    super.key,
    required this.tournament,
    required this.accentColor,
  });

  final TournamentModel tournament;
  final Color accentColor;

  @override
  ConsumerState<RoadmapTab> createState() => _RoadmapTabState();
}

class _RoadmapTabState extends ConsumerState<RoadmapTab>
    with AutomaticKeepAliveClientMixin {
  int _selectedStageIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final stagesAsync = ref.watch(tournamentStagesProvider(widget.tournament.id));

    return RefreshIndicator(
      color: widget.accentColor,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        ref.invalidate(tournamentStagesProvider(widget.tournament.id));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: stagesAsync.when(
          data: (apiStages) {
            final stages = apiStages.isNotEmpty
                ? apiStages
                : _buildFallbackStagesFromTournament(widget.tournament);

            if (stages.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Roadmap details not available yet.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
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
                // ── Stage Navigation Stepper Bar ──
                _buildStageStepper(stages),

                const SizedBox(height: 16),

                // ── Stage Details Summary Banner ──
                _buildStageHeader(currentStage),

                const SizedBox(height: 16),

                // ── Groups & Lobbies Grid ──
                if (currentStage.groups.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.groups_rounded,
                            color: AppColors.textMuted, size: 36),
                        const SizedBox(height: 10),
                        Text(
                          '${currentStage.lobbyCount} Lobbies (${currentStage.unitsPerLobby} units/lobby)',
                          style: AppTextStyles.bodyLg
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Top ${currentStage.qualifiersPerLobby} from each lobby advance to the next stage!',
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: currentStage.groups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final group = currentStage.groups[index];
                      return _GroupCard(
                        group: group,
                        qualifiersCutoff: currentStage.qualifiersPerLobby,
                        accentColor: widget.accentColor,
                      );
                    },
                  ),

                const SizedBox(height: 24),

                // ── Bottom Roadmap Info Card ──
                _buildRoadmapSummaryCard(stages),
              ],
            );
          },
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: widget.accentColor),
            ),
          ),
          error: (_, __) {
            final stages = _buildFallbackStagesFromTournament(widget.tournament);
            if (stages.isNotEmpty) {
              final currentStage = stages[_selectedStageIndex.clamp(0, stages.length - 1)];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStageStepper(stages),
                  const SizedBox(height: 16),
                  _buildStageHeader(currentStage),
                  const SizedBox(height: 16),
                  _buildRoadmapSummaryCard(stages),
                ],
              );
            }
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('Unable to load roadmap',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            );
          },
        ),
      ),
    );
  }

  List<TournamentStageModel> _buildFallbackStagesFromTournament(TournamentModel t) {
    if (t.stages.isNotEmpty) {
      return t.stages.map((s) {
        return TournamentStageModel(
          stageNumber: s.stageNumber,
          stageName: s.stageName,
          status: s.isCompleted
              ? StageStatus.COMPLETED
              : (s.isCurrentStage ? StageStatus.LIVE : StageStatus.SCHEDULED),
          lobbyCount: s.teams.length > 24 ? 2 : 1,
          unitsPerLobby: 12,
          qualifiersPerLobby: 3,
          isGrandFinal: s.stageName.toLowerCase().contains('grand') || s.stageName.toLowerCase().contains('final'),
          isCompleted: s.isCompleted,
          isActive: s.isCurrentStage,
          groups: [
            TournamentGroupModel(
              id: s.stageId,
              groupNumber: 1,
              groupName: 'Group A',
              standings: s.teams.map((bt) {
                return GroupStandingEntry(
                  rank: bt.rank,
                  unitId: bt.id,
                  unitName: bt.name,
                  avatarUrl: bt.logoUrl,
                  slotNumber: bt.rank,
                  matchesPlayed: 1,
                  kills: bt.kills,
                  placementPoints: bt.points - (bt.kills),
                  totalPoints: bt.points,
                  status: bt.isWinner || bt.isQualified
                      ? QualificationStatus.QUALIFIED
                      : (bt.isEliminated ? QualificationStatus.ELIMINATED : QualificationStatus.PENDING),
                );
              }).toList(),
            ),
          ],
        );
      }).toList();
    }

    return const [
      TournamentStageModel(
        stageNumber: 1,
        stageName: 'Round 1 (Qualifiers)',
        status: StageStatus.LIVE,
        lobbyCount: 8,
        unitsPerLobby: 12,
        qualifiersPerLobby: 3,
        isGrandFinal: false,
        isActive: true,
        groups: [],
      ),
      TournamentStageModel(
        stageNumber: 2,
        stageName: 'Semi-Finals',
        status: StageStatus.SCHEDULED,
        lobbyCount: 2,
        unitsPerLobby: 12,
        qualifiersPerLobby: 6,
        isGrandFinal: false,
        groups: [],
      ),
      TournamentStageModel(
        stageNumber: 3,
        stageName: 'Grand Final',
        status: StageStatus.SCHEDULED,
        lobbyCount: 1,
        unitsPerLobby: 12,
        qualifiersPerLobby: 1,
        isGrandFinal: true,
        groups: [],
      ),
    ];
  }

  // ── Stage Navigation Stepper ──
  Widget _buildStageStepper(List<TournamentStageModel> stages) {
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
                          '${stage.stageNumber}',
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
                      if (stage.status == StageStatus.LIVE) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
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
  Widget _buildStageHeader(TournamentStageModel stage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded,
              color: widget.accentColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.stageName.toUpperCase(),
                  style: AppTextStyles.headingMd.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  '${stage.lobbyCount} Lobbies • ${stage.unitsPerLobby} Teams/Lobby • Top ${stage.qualifiersPerLobby} Qualify',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: stage.status == StageStatus.LIVE
                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                  : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: stage.status == StageStatus.LIVE
                    ? const Color(0xFF10B981)
                    : AppColors.border,
              ),
            ),
            child: Text(
              stage.status.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: stage.status == StageStatus.LIVE
                    ? const Color(0xFF10B981)
                    : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Progression Summary Card ──
  Widget _buildRoadmapSummaryCard(List<TournamentStageModel> stages) {
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
                'STAGE PROGRESSION FLOW',
                style: AppTextStyles.headingMd.copyWith(color: AppColors.gold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Teams advance round-by-round through group stage lobbies based on total kills and placement points.',
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
                      '${s.lobbyCount * s.unitsPerLobby}',
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

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.qualifiersCutoff,
    required this.accentColor,
  });

  final TournamentGroupModel group;
  final int qualifiersCutoff;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                group.groupName,
                style: AppTextStyles.headingLg.copyWith(fontSize: 16),
              ),
              const Spacer(),
              Text(
                '${group.standings.length} Teams',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          if (group.standings.isNotEmpty) ...[
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: group.standings.take(5).length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) {
                final std = group.standings[i];
                final isQualified = std.rank <= qualifiersCutoff ||
                    std.status == QualificationStatus.QUALIFIED;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isQualified
                        ? const Color(0xFF10B981).withValues(alpha: 0.08)
                        : AppColors.surfaceMuted.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text('#${std.rank}',
                            style: AppTextStyles.caption
                                .copyWith(fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: Text(
                          std.unitName,
                          style: AppTextStyles.bodySm
                              .copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${std.totalPoints} pts',
                        style: AppTextStyles.caption.copyWith(
                          color: isQualified
                              ? const Color(0xFF10B981)
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isQualified
                              ? const Color(0xFF10B981).withValues(alpha: 0.2)
                              : AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isQualified ? 'QUALIFIED' : 'ELIMINATED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isQualified
                                ? const Color(0xFF10B981)
                                : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
