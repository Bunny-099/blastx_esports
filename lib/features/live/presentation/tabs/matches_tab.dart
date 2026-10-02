import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/tournament_model.dart';
import '../../providers/matches_provider.dart';

/// ============================================================
/// MATCHES TAB — Vertical Timeline Edition
/// ============================================================
/// Displays tournament match schedules grouped by round.
/// Features:
/// - Top "Now Playing" highlight strip for live streams
/// - Vertical timeline with status indicators (orange live, grey upcoming, green check completed)
/// - Stream URL launcher integration via url_launcher
/// - Auto-polling every 30s when live matches exist
/// - Shimmer, error + retry, empty states & pull-to-refresh
/// ============================================================

class MatchesTab extends ConsumerStatefulWidget {
  const MatchesTab({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  ConsumerState<MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends ConsumerState<MatchesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> _launchStream(String urlString) async {
    final Uri? uri = Uri.tryParse(urlString);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open stream link'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final asyncMatches = ref.watch(matchesProvider(widget.tournamentId));

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(matchesProvider(widget.tournamentId).notifier).refresh(),
      color: AppColors.accentOrange,
      backgroundColor: AppColors.surface,
      child: asyncMatches.when(
        loading: () => const _MatchesShimmerState(),
        error: (err, stack) => _MatchesErrorState(
          onRetry: () => ref
              .read(matchesProvider(widget.tournamentId).notifier)
              .refresh(),
        ),
        data: (matches) {
          if (matches.isEmpty) {
            return _MatchesEmptyState(
              onRefresh: () => ref
                  .read(matchesProvider(widget.tournamentId).notifier)
                  .refresh(),
            );
          }

          // Group matches by round preserving encounter order
          final grouped = <String, List<MatchModel>>{};
          for (final m in matches) {
            final roundName = m.round.isNotEmpty ? m.round : 'General Round';
            grouped.putIfAbsent(roundName, () => []).add(m);
          }

          // Find live match for top highlight card if available
          MatchModel? liveMatch;
          try {
            liveMatch = matches.firstWhere((m) => m.isLive);
          } catch (_) {
            liveMatch = null;
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              // 1. Top Highlight "Now Playing" Banner if a live match exists
              if (liveMatch != null) ...[
                _NowPlayingHighlightCard(
                  match: liveMatch,
                  onWatchStream: liveMatch.streamUrl != null &&
                          liveMatch.streamUrl!.isNotEmpty
                      ? () => _launchStream(liveMatch!.streamUrl!)
                      : null,
                ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),
                const SizedBox(height: 20),
              ],

              // 2. Grouped Rounds Timeline
              ...grouped.entries.toList().asMap().entries.map((entry) {
                final roundIndex = entry.key;
                final roundName = entry.value.key;
                final roundMatches = entry.value.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Round Section Header
                    _RoundSectionHeader(roundName: roundName),
                    const SizedBox(height: 12),

                    // Timeline Matches List
                    ...roundMatches.asMap().entries.map((mEntry) {
                      final matchIndex = mEntry.key;
                      final match = mEntry.value;
                      final isLastInRound = matchIndex == roundMatches.length - 1;

                      return _TimelineMatchItem(
                        match: match,
                        isLastInRound: isLastInRound,
                        onWatchStream: match.streamUrl != null &&
                                match.streamUrl!.isNotEmpty
                            ? () => _launchStream(match.streamUrl!)
                            : null,
                      )
                          .animate(delay: (50 * (roundIndex * 2 + matchIndex)).ms)
                          .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                          .slideY(
                            begin: 0.1,
                            end: 0,
                            duration: 350.ms,
                            curve: Curves.easeOutCubic,
                          );
                    }),
                    const SizedBox(height: 16),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Top "Now Playing" Banner Highlight Card
/// ------------------------------------------------------------
class _NowPlayingHighlightCard extends StatelessWidget {
  const _NowPlayingHighlightCard({
    required this.match,
    this.onWatchStream,
  });

  final MatchModel match;
  final VoidCallback? onWatchStream;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF3B30).withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF3B30).withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 4),
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
                  color: const Color(0xFFFF3B30).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF3B30).withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _PulsingLiveDot(),
                    const SizedBox(width: 6),
                    Text(
                      'NOW PLAYING',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFFFF3B30),
                        fontWeight: FontWeight.w900,
                        fontSize: 10.5,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Match #${match.matchNumber}',
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            '${match.round} • ${match.map}',
            style: AppTextStyles.headingMd.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Live action in progress. Tune in to watch live gameplay!',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),

          if (onWatchStream != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onWatchStream,
                icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                label: const Text('Watch Stream'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: AppTextStyles.button.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Round Section Header
/// ------------------------------------------------------------
class _RoundSectionHeader extends StatelessWidget {
  const _RoundSectionHeader({required this.roundName});

  final String roundName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.accentOrange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          roundName.toUpperCase(),
          style: AppTextStyles.overline.copyWith(
            color: AppColors.accentOrange,
            fontSize: 12,
            letterSpacing: 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// ------------------------------------------------------------
/// Timeline Item Widget (Dot/Line + Match Card)
/// ------------------------------------------------------------
class _TimelineMatchItem extends StatelessWidget {
  const _TimelineMatchItem({
    required this.match,
    required this.isLastInRound,
    this.onWatchStream,
  });

  final MatchModel match;
  final bool isLastInRound;
  final VoidCallback? onWatchStream;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Node & Connector Line Column
          SizedBox(
            width: 32,
            child: Column(
              children: [
                const SizedBox(height: 18),
                _buildTimelineDot(match.status),
                if (!isLastInRound)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: match.isLive
                          ? AppColors.accentOrange.withValues(alpha: 0.6)
                          : AppColors.borderSubtle,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Match Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MatchCard(
                match: match,
                onWatchStream: onWatchStream,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDot(MatchStatus status) {
    switch (status) {
      case MatchStatus.live:
        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentOrange,
            boxShadow: [
              BoxShadow(
                color: AppColors.accentOrange.withValues(alpha: 0.6),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      case MatchStatus.completed:
        return const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF34C759),
          size: 16,
        );
      case MatchStatus.upcoming:
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceMuted,
            border: Border.all(
              color: AppColors.textMuted.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
        );
    }
  }
}

/// ------------------------------------------------------------
/// Individual Match Card Widget
/// ------------------------------------------------------------
class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.match,
    this.onWatchStream,
  });

  final MatchModel match;
  final VoidCallback? onWatchStream;

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]}, $hour:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final isLive = match.isLive;
    final isCompleted = match.status == MatchStatus.completed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLive
              ? AppColors.accentOrange.withValues(alpha: 0.5)
              : AppColors.border,
          width: isLive ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header: Match Number, Map, & Status Badge
          Row(
            children: [
              Text(
                'Match #${match.matchNumber}',
                style: AppTextStyles.headingMd.copyWith(fontSize: 15),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  match.map.isNotEmpty ? match.map : 'Bermuda',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              _StatusChip(status: match.status),
            ],
          ),
          const SizedBox(height: 8),

          // Scheduled Start / End Time
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 13,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                isCompleted && match.endedAt != null
                    ? 'Ended: ${_formatDateTime(match.endedAt!)}'
                    : 'Scheduled: ${_formatDateTime(match.startsAt)}',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),

          // Completed Match Results: Winner & Top MVP
          if (isCompleted &&
              (match.winnerTeamName != null || match.topKillerName != null)) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bgNavy.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSubtle, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (match.winnerTeamName != null &&
                      match.winnerTeamName!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          size: 14,
                          color: AppColors.glowSoft,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Winner: ',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          match.winnerTeamName!,
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.glowLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  if (match.winnerTeamName != null &&
                      match.topKillerName != null &&
                      match.topKillerName!.isNotEmpty)
                    const SizedBox(height: 4),
                  if (match.topKillerName != null &&
                      match.topKillerName!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 14,
                          color: AppColors.accentOrange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Top MVP: ',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          match.topKillerName!,
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.accentOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],

          // Watch CTA Button (if streamUrl exists)
          if (onWatchStream != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onWatchStream,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: isLive
                      ? AppColors.accentOrange.withValues(alpha: 0.15)
                      : AppColors.surfaceMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isLive
                          ? AppColors.accentOrange.withValues(alpha: 0.5)
                          : AppColors.border,
                      width: 0.8,
                    ),
                  ),
                ),
                icon: Icon(
                  Icons.play_circle_fill_rounded,
                  size: 15,
                  color: isLive ? AppColors.accentOrange : AppColors.primaryLight,
                ),
                label: Text(
                  isLive ? 'Watch Live' : 'Watch Replay',
                  style: AppTextStyles.caption.copyWith(
                    color: isLive ? AppColors.accentOrange : AppColors.primaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Status Chip Badge Widget
/// ------------------------------------------------------------
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final MatchStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MatchStatus.live:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFF3B30).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFF3B30).withValues(alpha: 0.6),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _PulsingLiveDot(),
              const SizedBox(width: 4),
              Text(
                'LIVE',
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFFFF3B30),
                  fontWeight: FontWeight.w900,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        );

      case MatchStatus.completed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0x2234C759),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF34C759).withValues(alpha: 0.5),
              width: 0.8,
            ),
          ),
          child: Text(
            'COMPLETED',
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFF34C759),
              fontWeight: FontWeight.w800,
              fontSize: 9.5,
            ),
          ),
        );

      case MatchStatus.upcoming:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderSubtle,
              width: 0.8,
            ),
          ),
          child: Text(
            'UPCOMING',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 9.5,
            ),
          ),
        );
    }
  }
}

/// ------------------------------------------------------------
/// Pulsing Red Live Dot Indicator
/// ------------------------------------------------------------
class _PulsingLiveDot extends StatefulWidget {
  const _PulsingLiveDot();

  @override
  State<_PulsingLiveDot> createState() => _PulsingLiveDotState();
}

class _PulsingLiveDotState extends State<_PulsingLiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Opacity(
          opacity: 0.35 + (_ctrl.value * 0.65),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFFF3B30),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

/// ------------------------------------------------------------
/// Shimmer Loading Skeleton State
/// ------------------------------------------------------------
class _MatchesShimmerState extends StatelessWidget {
  const _MatchesShimmerState();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceMuted,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 32,
                  child: Center(
                    child: CircleAvatar(
                      radius: 6,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Empty Matches State
/// ------------------------------------------------------------
class _MatchesEmptyState extends StatelessWidget {
  const _MatchesEmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.sports_esports_rounded,
                size: 40,
                color: AppColors.accentOrange,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Matches Scheduled',
              style: AppTextStyles.headingMd,
            ),
            const SizedBox(height: 6),
            Text(
              'Match schedules and room details will appear here as soon as they are announced.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primaryLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Error Matches State
/// ------------------------------------------------------------
class _MatchesErrorState extends StatelessWidget {
  const _MatchesErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.primary,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              "Couldn't load matches",
              style: AppTextStyles.headingMd,
            ),
            const SizedBox(height: 6),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primaryLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
