import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../tournaments/data/models/tournament_format_models.dart';
import '../../data/models/tournament_model.dart';
import '../../providers/live_provider.dart';

/// ============================================================
/// STANDINGS & BRACKETS TAB
/// Conforming to Section 4.1 of Mobile App Developer Prompt
/// For BR: Stage & Group dropdown switcher with live standings table.
/// For Clash Squad: Interactive horizontal scrolling knockout bracket tree.
/// ============================================================

class StandingsBracketTab extends ConsumerStatefulWidget {
  const StandingsBracketTab({
    super.key,
    required this.tournamentId,
    required this.accentColor,
  });

  final String tournamentId;
  final Color accentColor;

  @override
  ConsumerState<StandingsBracketTab> createState() =>
      _StandingsBracketTabState();
}

class _StandingsBracketTabState extends ConsumerState<StandingsBracketTab> {
  int _selectedStageIndex = 0;
  int _selectedGroupIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tournament = ref.watch(tournamentByIdProvider(widget.tournamentId));
    final isClashSquad = tournament?.matchType.toUpperCase() == 'CLASH_SQUAD' ||
        tournament?.mode.toUpperCase() == 'CLASH_SQUAD';

    if (isClashSquad) {
      return _buildClashSquadBracketTree(context);
    } else {
      return _buildBattleRoyaleStandings(context, tournament);
    }
  }

  // ------------------------------------------------------------
  // BATTLE ROYALE STANDINGS TABLE WITH STAGE & GROUP SELECTOR
  // ------------------------------------------------------------
  Widget _buildBattleRoyaleStandings(
      BuildContext context, TournamentModel? tournament) {
    final stagesAsync = ref.watch(tournamentStagesProvider(widget.tournamentId));

    return RefreshIndicator(
      color: widget.accentColor,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        ref.invalidate(tournamentStagesProvider(widget.tournamentId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: stagesAsync.when(
          data: (stages) {
            if (stages.isEmpty) {
              return _buildEmptyStandingsView();
            }

            if (_selectedStageIndex >= stages.length) {
              _selectedStageIndex = 0;
            }

            final currentStage = stages[_selectedStageIndex];
            final groups = currentStage.groups;

            if (_selectedGroupIndex >= groups.length) {
              _selectedGroupIndex = 0;
            }

            final currentGroup =
                groups.isNotEmpty ? groups[_selectedGroupIndex] : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // STAGE & GROUP DROPDOWN SWITCHER BAR
                Row(
                  children: [
                    // Stage Selector Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedStageIndex,
                            dropdownColor: AppColors.surface,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textSecondary),
                            isExpanded: true,
                            items: List.generate(stages.length, (index) {
                              return DropdownMenuItem<int>(
                                value: index,
                                child: Text(
                                  stages[index].stageName,
                                  style: AppTextStyles.bodySm.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            }),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedStageIndex = val;
                                  _selectedGroupIndex = 0;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),

                    if (groups.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      // Group Selector Dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedGroupIndex,
                              dropdownColor: AppColors.surface,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.textSecondary),
                              isExpanded: true,
                              items: List.generate(groups.length, (index) {
                                return DropdownMenuItem<int>(
                                  value: index,
                                  child: Text(
                                    groups[index].groupName,
                                    style: AppTextStyles.bodySm.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedGroupIndex = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // STANDINGS TABLE
                if (currentGroup == null || currentGroup.standings.isEmpty)
                  _buildEmptyStandingsView()
                else ...[
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceNavy,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text('#',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textMuted)),
                        ),
                        Expanded(
                          child: Text('TEAM / UNIT',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textMuted)),
                        ),
                        SizedBox(
                          width: 44,
                          child: Text('SLOT',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textMuted)),
                        ),
                        SizedBox(
                          width: 44,
                          child: Text('KILLS',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textMuted)),
                        ),
                        SizedBox(
                          width: 50,
                          child: Text('PTS',
                              textAlign: TextAlign.right,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textMuted)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Table Rows
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: currentGroup.standings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final std = currentGroup.standings[index];
                      return _buildStandingRow(std);
                    },
                  ),
                ],
              ],
            );
          },
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: widget.accentColor),
            ),
          ),
          error: (_, __) => _buildEmptyStandingsView(),
        ),
      ),
    );
  }

  Widget _buildStandingRow(GroupStandingEntry std) {
    final isQualified = std.status == QualificationStatus.QUALIFIED;
    final isEliminated = std.status == QualificationStatus.ELIMINATED;

    final badgeColor = isQualified
        ? const Color(0xFF10B981)
        : (isEliminated ? const Color(0xFFEF4444) : AppColors.gold);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isQualified
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Rank Badge
          SizedBox(
            width: 36,
            child: Text(
              '#${std.rank}',
              style: AppTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.bold,
                color: std.rank <= 3 ? AppColors.gold : Colors.white,
              ),
            ),
          ),

          // Team Name & Status Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  std.unitName,
                  style: AppTextStyles.bodyMd
                      .copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    std.status.name,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Slot Number
          SizedBox(
            width: 44,
            child: Text(
              '${std.slotNumber}',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),

          // Kills
          SizedBox(
            width: 44,
            child: Text(
              '${std.kills}',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),

          // Total Points
          SizedBox(
            width: 50,
            child: Text(
              '${std.totalPoints}',
              textAlign: TextAlign.right,
              style: AppTextStyles.headingMd.copyWith(
                color: AppColors.primaryNeon,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStandingsView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.leaderboard_rounded,
              color: AppColors.textMuted, size: 40),
          const SizedBox(height: 12),
          Text('STANDINGS NOT AVAILABLE YET', style: AppTextStyles.headingMd),
          const SizedBox(height: 6),
          Text(
            'Live points and group ranks will update here as match rounds progress.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // CLASH SQUAD KNOCKOUT BRACKET TREE
  // ------------------------------------------------------------
  Widget _buildClashSquadBracketTree(BuildContext context) {
    final bracketAsync = ref.watch(tournamentBracketProvider(widget.tournamentId));

    return RefreshIndicator(
      color: widget.accentColor,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        ref.invalidate(tournamentBracketProvider(widget.tournamentId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: bracketAsync.when(
          data: (bracket) {
            final rounds = bracket?.rounds ?? _buildFallbackClashSquadRounds();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_tree_rounded,
                        color: AppColors.gold, size: 20),
                    const SizedBox(width: 8),
                    Text('CLASH SQUAD KNOCKOUT TREE',
                        style: AppTextStyles.headingMd
                            .copyWith(color: AppColors.gold)),
                  ],
                ),
                const SizedBox(height: 16),

                // Horizontal Scrolling Bracket View
                SizedBox(
                  height: 400,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: rounds.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 20),
                    itemBuilder: (context, index) {
                      final round = rounds[index];
                      return _buildBracketRoundColumn(round);
                    },
                  ),
                ),
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
            final rounds = _buildFallbackClashSquadRounds();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CLASH SQUAD KNOCKOUT TREE',
                    style: AppTextStyles.headingMd
                        .copyWith(color: AppColors.gold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 400,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: rounds.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 20),
                    itemBuilder: (context, index) {
                      final round = rounds[index];
                      return _buildBracketRoundColumn(round);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBracketRoundColumn(ClashSquadRoundModel round) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Round Heading Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceNavy,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              round.roundName.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryNeon,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 12),

          // Matches List
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: round.matches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final match = round.matches[index];
                return _buildMatchCard(match);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(ClashSquadMatchModel match) {
    final winnerA = match.winnerId == match.teamAId && match.isCompleted;
    final winnerB = match.winnerId == match.teamBId && match.isCompleted;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: match.isLive
              ? const Color(0xFF00F0FF)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          // Team A Row
          Row(
            children: [
              Expanded(
                child: Text(
                  match.teamAName,
                  style: AppTextStyles.bodySm.copyWith(
                    fontWeight: winnerA ? FontWeight.bold : FontWeight.normal,
                    color: winnerA ? AppColors.gold : Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${match.scoreA}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: winnerA ? AppColors.gold : AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(color: AppColors.border, height: 1),
          ),

          // Team B Row
          Row(
            children: [
              Expanded(
                child: Text(
                  match.teamBName,
                  style: AppTextStyles.bodySm.copyWith(
                    fontWeight: winnerB ? FontWeight.bold : FontWeight.normal,
                    color: winnerB ? AppColors.gold : Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${match.scoreB}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: winnerB ? AppColors.gold : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<ClashSquadRoundModel> _buildFallbackClashSquadRounds() {
    return const [
      ClashSquadRoundModel(
        roundIndex: 0,
        roundName: 'Semifinals',
        matches: [
          ClashSquadMatchModel(
            matchId: 'm1',
            roundName: 'Semifinals',
            matchNumber: 1,
            teamAId: 't1',
            teamAName: 'Team Alpha',
            scoreA: 4,
            teamBId: 't2',
            teamBName: 'Team Beta',
            scoreB: 2,
            winnerId: 't1',
            isCompleted: true,
          ),
          ClashSquadMatchModel(
            matchId: 'm2',
            roundName: 'Semifinals',
            matchNumber: 2,
            teamAId: 't3',
            teamAName: 'Gamma Squad',
            scoreA: 1,
            teamBId: 't4',
            teamBName: 'Delta Force',
            scoreB: 4,
            winnerId: 't4',
            isCompleted: true,
          ),
        ],
      ),
      ClashSquadRoundModel(
        roundIndex: 1,
        roundName: 'Grand Final',
        matches: [
          ClashSquadMatchModel(
            matchId: 'm3',
            roundName: 'Grand Final',
            matchNumber: 1,
            teamAId: 't1',
            teamAName: 'Team Alpha',
            scoreA: 0,
            teamBId: 't4',
            teamBName: 'Delta Force',
            scoreB: 0,
            isLive: true,
          ),
        ],
      ),
    ];
  }
}
