import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/transitions/fire_page_route.dart';
import '../../data/models/match_center_model.dart';
import '../../providers/live_provider.dart';
import '../../providers/matches_provider.dart';
import '../match_detail_screen.dart';

/// ============================================================
/// MATCH TAB — Section 5 Match Center Redesign
/// Displays:
/// (a) "My status" card (Active/Qualified/Eliminated with round, rank, points, kills)
///     and non-playing note ("Only the Playing 4 get room details")
/// (b) Collapsible round sections with match cards:
///     match number, group, map, time, status chip, my result when completed,
///     and a lock icon when room_state is NOT_ELIGIBLE.
/// Tapping a match card opens MatchDetailScreen.
/// ============================================================

class MyLobbyTab extends ConsumerStatefulWidget {
  const MyLobbyTab({
    super.key,
    required this.tournamentId,
    required this.accentColor,
  });

  final String tournamentId;
  final Color accentColor;

  @override
  ConsumerState<MyLobbyTab> createState() => _MyLobbyTabState();
}

class _MyLobbyTabState extends ConsumerState<MyLobbyTab> {
  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final matchCenterAsync = ref.watch(matchCenterProvider(widget.tournamentId));
    final tournament = ref.watch(tournamentByIdProvider(widget.tournamentId));

    return RefreshIndicator(
      color: widget.accentColor,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        ref.read(matchCenterProvider(widget.tournamentId).notifier).refresh();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: matchCenterAsync.when(
          data: (matchCenter) => _buildMatchCenterContent(matchCenter, tournament),
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: widget.accentColor),
            ),
          ),
          error: (err, stack) => _buildFallbackState(tournament),
        ),
      ),
    );
  }

  Widget _buildMatchCenterContent(MatchCenterModel matchCenter, dynamic tournament) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // (a) MY STATUS CARD
        _buildMyStatusCard(matchCenter),

        const SizedBox(height: 20),

        // Non-playing member banner if nonPlaying
        if (matchCenter.myAccess.isNonPlaying) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.accentOrange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Only the Playing 4 get room details.',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // (b) ROUNDS & MATCHES SECTION
        if (matchCenter.rounds.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'TOURNAMENT MATCHES & ROUNDS',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...matchCenter.rounds.map((round) => _buildRoundSection(round, matchCenter.myAccess)),
        ] else ...[
          _buildNoMatchesState(),
        ],
      ],
    );
  }

  // ── (a) MY STATUS CARD ──
  Widget _buildMyStatusCard(MatchCenterModel matchCenter) {
    final myStatus = matchCenter.myStatus;
    final state = myStatus?.state ?? MatchCenterState.active;

    final badgeColor = switch (state) {
      MatchCenterState.active => AppColors.primaryNeon,
      MatchCenterState.qualified => const Color(0xFF10B981),
      MatchCenterState.eliminated => AppColors.error,
      MatchCenterState.disqualified => AppColors.error,
      MatchCenterState.completed => AppColors.gold,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF151722),
            widget.accentColor.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor),
                ),
                child: Text(
                  'STATUS: ${state.label}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
              const Spacer(),
              if (myStatus?.rank != null)
                Text(
                  'Rank #${myStatus!.rank}',
                  style: AppTextStyles.bodyLg.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (myStatus?.currentRound != null) ...[
            Text(
              'Current Round: ${myStatus!.currentRound}',
              style: AppTextStyles.headingXl.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 10),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatColumn(label: 'RANK', value: myStatus?.rank != null ? '#${myStatus!.rank}' : 'N/A'),
              _StatColumn(label: 'TOTAL POINTS', value: '${myStatus?.totalPoints ?? 0}'),
              _StatColumn(label: 'TOTAL KILLS', value: '${myStatus?.totalKills ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  // ── (b) COLLAPSIBLE ROUND SECTION ──
  Widget _buildRoundSection(MatchCenterRoundModel round, MyAccess myAccess) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          round.name.toUpperCase(),
          style: AppTextStyles.headingMd.copyWith(fontSize: 15),
        ),
        subtitle: Text(
          '${round.matches.length} Matches',
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        ),
        iconColor: widget.accentColor,
        collapsedIconColor: AppColors.textMuted,
        children: round.matches.map((match) => _buildMatchCard(match, myAccess)).toList(),
      ),
    );
  }

  // ── INDIVIDUAL MATCH CARD ──
  Widget _buildMatchCard(MatchCenterMatchItemModel match, MyAccess myAccess) {
    final isNotEligible = match.roomState == RoomState.notEligible || myAccess.isNonPlaying;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          FirePageRoute(
            page: MatchDetailScreen(
              tournamentId: widget.tournamentId,
              matchKey: match.matchKey,
              initialMatch: match,
              myAccess: myAccess,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgNavy,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: match.status == MatchUnitStatus.live
                ? AppColors.primaryNeon
                : AppColors.borderSubtle,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Match #${match.matchNumber} • ${match.groupName}',
                  style: AppTextStyles.headingMd.copyWith(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    match.map,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 9.5,
                    ),
                  ),
                ),
                const Spacer(),
                if (isNotEligible)
                  const Icon(Icons.lock_rounded, size: 16, color: AppColors.textMuted)
                else
                  _MatchStatusChip(status: match.status),
              ],
            ),
            const SizedBox(height: 6),

            Row(
              children: [
                Text(
                  _formatTime(match.scheduledAt),
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
              ],
            ),

            // Completed Result Banner if present
            if (match.myResult != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Result: #${match.myResult!.placement} • ${match.myResult!.kills} Kills • ${match.myResult!.totalPoints} Pts',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoMatchesState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.sports_esports_rounded, color: AppColors.accentOrange, size: 36),
          const SizedBox(height: 12),
          Text(
            'NO MATCHES SCHEDULED YET',
            style: AppTextStyles.headingMd,
          ),
          const SizedBox(height: 6),
          Text(
            'Your match schedule and group assignments will appear here once published by the organizer.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackState(dynamic tournament) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.shield_rounded, color: widget.accentColor, size: 40),
          const SizedBox(height: 16),
          Text(
            'TOURNAMENT MATCH CENTER',
            style: AppTextStyles.headingLg,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Match schedule and group assignments will be loaded live.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.headingMd.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _MatchStatusChip extends StatelessWidget {
  const _MatchStatusChip({required this.status});
  final MatchUnitStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MatchUnitStatus.scheduled => AppColors.accentOrange,
      MatchUnitStatus.live => AppColors.error,
      MatchUnitStatus.completed => AppColors.primaryNeon,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }
}
