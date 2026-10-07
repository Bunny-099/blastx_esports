import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/leaderboard_model.dart';
import '../../providers/leaderboard_provider.dart';
import '../../providers/live_provider.dart';

/// ============================================================
/// LEADERBOARD TAB — Real-time Free Fire Tournament Standings
/// ============================================================
/// - Top 3 Podium for Gold, Silver, Bronze contenders
/// - Ranked list with team logo, kills, placement points, total points
/// - Rank change indicators (green ▲, red ▼, grey -)
/// - Live 20s polling when tournament is LIVE and tab is visible
/// - "Last updated Xs ago" live ticker & pulsing LIVE badge
/// - Shimmer loading, Error with Retry, Empty state, Pull-to-refresh
/// ============================================================

class LeaderboardTab extends ConsumerStatefulWidget {
  const LeaderboardTab({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  ConsumerState<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends ConsumerState<LeaderboardTab>
    with AutomaticKeepAliveClientMixin {
  Timer? _tickerTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  String _formatLastUpdated(DateTime? dt) {
    if (dt == null) return 'Just now';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 5) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Sync tab visibility with Riverpod provider for 20s polling
    final isVisible = TickerMode.valuesOf(context).enabled;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(leaderboardProvider(widget.tournamentId).notifier).setTabVisibility(isVisible);
      }
    });

    final leaderboardAsync = ref.watch(leaderboardProvider(widget.tournamentId));
    final tournament = ref.watch(tournamentByIdProvider(widget.tournamentId));
    final notifier = ref.read(leaderboardProvider(widget.tournamentId).notifier);

    final lastUpdatedText = _formatLastUpdated(notifier.lastRefreshedAt);
    final isLive = tournament?.isLive ?? false;

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: leaderboardAsync.when(
        data: (data) {
          if (data.entries.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: _EmptyState(onRefresh: () => notifier.refresh()),
              ),
            );
          }

          final entries = data.entries;
          final top3 = entries.take(3).toList();
          final remaining = entries.skip(3).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // 1. Meta Bar: Round Name, Last Updated Ticker, Live Indicator
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceNavy,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Text(
                              data.round.isNotEmpty ? data.round : 'Grand Final',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isLive) ...[
                            const _LiveDot(),
                            const SizedBox(width: 6),
                            Text(
                              'LIVE',
                              style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFFFF3B30),
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'Updated $lastUpdatedText',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Podium Section for Top 3
              if (top3.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: _PodiumView(top3: top3),
                  ),
                ),

              // 3. Table Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceNavy.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          child: Text('#', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                        ),
                        Expanded(
                          child: Text('TEAM', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                        ),
                        SizedBox(
                          width: 48,
                          child: Text('KILLS', textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                        ),
                        SizedBox(
                          width: 58,
                          child: Text('PTS', textAlign: TextAlign.right, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Remaining Ranked Teams List (#4 onwards)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = remaining[index];
                      return Padding(
                        key: ValueKey(entry.teamId),
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _LeaderboardRow(entry: entry),
                      )
                          .animate(delay: (40 * index).ms)
                          .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                          .slideY(begin: 0.08, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
                    },
                    childCount: remaining.length,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          itemCount: 6,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _RowShimmer(),
          ),
        ),
        error: (error, stack) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: _ErrorState(onRetry: () => notifier.refresh()),
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// PODIUM VIEW (Top 3 Teams)
/// ============================================================

class _PodiumView extends StatelessWidget {
  const _PodiumView({required this.top3});

  final List<LeaderboardEntry> top3;

  @override
  Widget build(BuildContext context) {
    if (top3.isEmpty) return const SizedBox.shrink();
    final first = top3.firstWhere((e) => e.rank == 1, orElse: () => top3.first);
    final second = top3.length > 1 ? top3.firstWhere((e) => e.rank == 2, orElse: () => top3[1]) : null;
    final third = top3.length > 2 ? top3.firstWhere((e) => e.rank == 3, orElse: () => top3[2]) : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd Place (Silver)
        Expanded(
          child: second != null
              ? _PodiumCard(
                  entry: second,
                  accentColor: const Color(0xFFC0C0C0),
                  rankLabel: '2nd',
                  height: 154,
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 8),

        // 1st Place (Gold)
        Expanded(
          child: _PodiumCard(
            entry: first,
            accentColor: const Color(0xFFFFD700),
            rankLabel: '1st',
            isCenter: true,
            height: 174,
          ),
        ),
        const SizedBox(width: 8),

        // 3rd Place (Bronze)
        Expanded(
          child: third != null
              ? _PodiumCard(
                  entry: third,
                  accentColor: const Color(0xFFCD7F32),
                  rankLabel: '3rd',
                  height: 144,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.entry,
    required this.accentColor,
    required this.rankLabel,
    required this.height,
    this.isCenter = false,
  });

  final LeaderboardEntry entry;
  final Color accentColor;
  final String rankLabel;
  final double height;
  final bool isCenter;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: isCenter ? 0.6 : 0.3),
          width: isCenter ? 1.4 : 1.0,
        ),
        boxShadow: isCenter
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Crown / Rank Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCenter ? Icons.emoji_events_rounded : Icons.workspace_premium_rounded,
                color: accentColor,
                size: isCenter ? 18 : 15,
              ),
              const SizedBox(width: 4),
              Text(
                rankLabel,
                style: AppTextStyles.caption.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: isCenter ? 12 : 10.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Team Avatar
          _TeamAvatar(logoUrl: entry.logoUrl, teamName: entry.teamName, size: isCenter ? 40 : 34),
          const SizedBox(height: 6),

          // Team Name
          Text(
            entry.teamName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isCenter ? 13 : 11.5,
            ),
          ),
          const SizedBox(height: 4),

          // Total Points & Kills
          Text(
            '${entry.totalPoints} pts',
            style: AppTextStyles.caption.copyWith(
              color: isCenter ? AppColors.primaryNeon : AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '${entry.kills} kills',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// LEADERBOARD ROW (#4 and below)
/// ============================================================

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Rank # and Rank Change Indicator
          SizedBox(
            width: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '#${entry.rank}',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                _RankChangeIndicator(change: entry.rankChange),
              ],
            ),
          ),

          // Team Logo Avatar
          _TeamAvatar(logoUrl: entry.logoUrl, teamName: entry.teamName, size: 32),
          const SizedBox(width: 10),

          // Team Name & Status Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.teamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLg.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (entry.status != LeaderboardEntryStatus.active) ...[
                  const SizedBox(height: 2),
                  _StatusChip(status: entry.status),
                ],
              ],
            ),
          ),

          // Kills
          SizedBox(
            width: 48,
            child: Text(
              '${entry.kills}',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // Total Points
          SizedBox(
            width: 58,
            child: Text(
              '${entry.totalPoints}',
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
}

/// ============================================================
/// TEAM AVATAR WITH INITIALS FALLBACK
/// ============================================================

class _TeamAvatar extends StatelessWidget {
  const _TeamAvatar({
    required this.logoUrl,
    required this.teamName,
    this.size = 36,
  });

  final String logoUrl;
  final String teamName;
  final double size;

  String get _initials {
    final parts = teamName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'T';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length.clamp(1, 2)).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 0.8,
        ),
      ),
      child: ClipOval(
        child: logoUrl.isNotEmpty
            ? Image.network(
                logoUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildInitials(),
              )
            : _buildInitials(),
      ),
    );
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        _initials,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primaryNeon,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

/// ============================================================
/// RANK CHANGE INDICATOR (▲2, ▼1, -)
/// ============================================================

class _RankChangeIndicator extends StatelessWidget {
  const _RankChangeIndicator({required this.change});

  final int change;

  @override
  Widget build(BuildContext context) {
    if (change > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_drop_up_rounded, color: Color(0xFF34C759), size: 14),
          Text(
            '$change',
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFF34C759),
              fontWeight: FontWeight.bold,
              fontSize: 9.5,
            ),
          ),
        ],
      );
    } else if (change < 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFFFF3B30), size: 14),
          Text(
            '${change.abs()}',
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFFFF3B30),
              fontWeight: FontWeight.bold,
              fontSize: 9.5,
            ),
          ),
        ],
      );
    } else {
      return Text(
        '-',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textMuted,
          fontSize: 9.5,
        ),
      );
    }
  }
}

/// ============================================================
/// STATUS CHIP (QUALIFIED / ELIMINATED)
/// ============================================================

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final LeaderboardEntryStatus status;

  @override
  Widget build(BuildContext context) {
    final isQualified = status == LeaderboardEntryStatus.qualified;
    final color = isQualified ? const Color(0xFF34C759) : const Color(0xFFFF3B30);
    final label = isQualified ? 'QUALIFIED' : 'ELIMINATED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// ============================================================
/// PULSING LIVE DOT
/// ============================================================

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.35 + (_controller.value * 0.65),
          child: Container(
            width: 7,
            height: 7,
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

/// ============================================================
/// SHIMMER LOADING PLACEHOLDER
/// ============================================================

class _RowShimmer extends StatelessWidget {
  const _RowShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceMuted,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

/// ============================================================
/// EMPTY STATE
/// ============================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.leaderboard_rounded,
                size: 38,
                color: AppColors.accentOrange,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Leaderboard Not Available Yet',
              style: AppTextStyles.headingMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Standings and scores will update in real-time once matches start.',
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
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// ERROR STATE
/// ============================================================

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: AppColors.primary,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            "Couldn't load leaderboard",
            style: AppTextStyles.headingMd,
          ),
          const SizedBox(height: 6),
          Text(
            'Check your connection and try again',
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
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
