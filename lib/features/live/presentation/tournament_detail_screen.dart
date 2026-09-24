import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blastix_esports/core/theme/app_colors.dart';
import 'package:blastix_esports/core/theme/app_text_styles.dart';
import 'package:blastix_esports/core/transitions/fire_page_route.dart';
import 'package:blastix_esports/features/live/data/models/tournament_model.dart';
import 'package:blastix_esports/features/live/presentation/team/join_tournament_screen.dart';
import 'package:blastix_esports/features/live/presentation/widgets/tournament_roadmap_widget.dart';
import 'package:blastix_esports/features/live/providers/live_provider.dart';

/// ============================================================
/// TOURNAMENT DETAIL SCREEN — Command Center Edition
/// Banner -> Quick stats -> Tabs (Overview | Bracket | Matches | Teams | Rules)
/// + sticky bottom CTA (Join / Watch Live / Results)
/// ============================================================

class TournamentDetailScreen extends ConsumerStatefulWidget {
  const TournamentDetailScreen({super.key, required this.tournamentId});
  final String tournamentId;

  @override
  ConsumerState<TournamentDetailScreen> createState() =>
      _TournamentDetailScreenState();
}

class _TournamentDetailScreenState
    extends ConsumerState<TournamentDetailScreen> {
  int _tab = 0;
  static const _tabs = ['Overview', 'Bracket', 'Matches', 'Teams', 'Rules'];

  Color _accentColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tournamentByIdProvider(widget.tournamentId));

    if (t == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
        body: Center(
            child: Text('Tournament not found', style: AppTextStyles.bodyMd)),
      );
    }

    final accent = _accentColor(t.accentColorHex);

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _BottomCta(tournament: t),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, t, accent),
          SliverToBoxAdapter(child: _buildHeader(t, accent)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabsDelegate(
              tabs: _tabs,
              selected: _tab,
              accent: accent,
              onSelect: (i) => setState(() => _tab = i),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey(_tab),
                  child: _tabBody(t, accent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBody(TournamentModel t, Color accent) {
    switch (_tab) {
      case 1:
        return TournamentRoadmapWidget(tournament: t, accentColor: accent);
      case 2:
        return _MatchesTab(t: t, accent: accent);
      case 3:
        return _TeamsTab(t: t, accent: accent);
      case 4:
        return _RulesTab(t: t, accent: accent);
      default:
        return _OverviewTab(t: t, accent: accent);
    }
  }

  // ---------------- App bar / banner ----------------
  SliverAppBar _buildAppBar(
      BuildContext context, TournamentModel t, Color accent) {
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 260,
      stretchTriggerOffset: 140,
      backgroundColor: AppColors.background,
      leading: _GlassIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onTap: () => Navigator.of(context).pop(),
      ),
      actions: [
        _GlassIconButton(icon: Icons.favorite_border_rounded, onTap: () {}),
        _GlassIconButton(icon: Icons.share_rounded, onTap: () {}),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'tournament-banner-${t.id}',
              child: Image.network(
                t.bannerImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: AppColors.surface),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.4),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.65, 1.0],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withValues(alpha: 0.22), Colors.transparent],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
            ),
            Positioned(top: 100, left: 20, child: _StatusPill(t.status)),
          ],
        ),
      ),
    );
  }

  // ---------------- Title / organizer / prize / quick stats ----------------
  Widget _buildHeader(TournamentModel t, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Chip(text: t.game, color: accent),
              if (t.tournamentCode.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('#${t.tournamentCode}', style: AppTextStyles.caption),
              ],
              const Spacer(),
              const Icon(Icons.remove_red_eye_rounded,
                  color: AppColors.textSecondary, size: 15),
              const SizedBox(width: 4),
              Text('${t.formattedViewers} watching',
                  style: AppTextStyles.bodySm),
            ],
          ),
          const SizedBox(height: 12),
          Hero(
            tag: 'tournament-title-${t.id}',
            child: Material(
              type: MaterialType.transparency,
              child: Text(t.name, style: AppTextStyles.headingXl),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Organized by ${t.organizer}', style: AppTextStyles.bodySm),
              if (t.organizerVerified) ...[
                const SizedBox(width: 4),
                Icon(Icons.verified_rounded, size: 15, color: accent),
              ],
            ],
          ),
          const SizedBox(height: 20),
          _GlassPrizeCard(accent: accent, tournament: t),
          const SizedBox(height: 14),
          _QuickStats(t: t, accent: accent),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// ============================================================
/// TABS
/// ============================================================

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.t, required this.accent});
  final TournamentModel t;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (t.announcements.isNotEmpty) ...[
          _Section('Announcements', accent),
          ...t.announcements.map((a) => _AnnouncementTile(text: a)),
        ],
        if (t.prizeDistribution.isNotEmpty || t.booyahBonus > 0 ||
            t.perKillReward > 0) ...[
          _Section('Prize Distribution', accent),
          _Card(
            child: Column(
              children: [
                ...t.prizeDistribution.asMap().entries.map((e) => _KeyValueRow(
                  left: '${_medal(e.key)}${e.value.label}',
                  right: t.money(e.value.amount),
                  rightColor: AppColors.gold,
                )),
                if (t.booyahBonus > 0)
                  _KeyValueRow(
                      left: 'Booyah Bonus', right: t.money(t.booyahBonus)),
                if (t.perKillReward > 0)
                  _KeyValueRow(
                      left: 'Per Kill', right: t.money(t.perKillReward)),
              ],
            ),
          ),
        ],
        if (t.pointsSystem.isNotEmpty) ...[
          _Section('Points System', accent),
          _Card(
            child: Column(
              children: t.pointsSystem
                  .map((p) =>
                  _KeyValueRow(left: p.label, right: p.points))
                  .toList(),
            ),
          ),
        ],
        if (t.schedule.isNotEmpty) ...[
          _Section('Schedule', accent),
          _Timeline(steps: t.schedule, accent: accent),
        ],
        _Section('Organizer', accent),
        _Card(
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surfaceMuted,
                child: Icon(Icons.shield_rounded, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.organizer,
                        style: AppTextStyles.bodyLg
                            .copyWith(fontWeight: FontWeight.w700)),
                    if (t.organizerVerified)
                      Text('Verified Organizer', style: AppTextStyles.caption),
                  ],
                ),
              ),
              TextButton(onPressed: () {}, child: const Text('View')),
            ],
          ),
        ),
        _Section('Need help?', accent),
        _Card(
          child: Row(
            children: [
              Icon(Icons.support_agent_rounded, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Payment, match or room issue? Contact support.',
                    style: AppTextStyles.bodySm),
              ),
              TextButton(onPressed: () {}, child: const Text('Contact')),
            ],
          ),
        ),
      ],
    );
  }

  String _medal(int i) => i == 0 ? '🥇 ' : i == 1 ? '🥈 ' : i == 2 ? '🥉 ' : '';
}

class _MatchesTab extends StatelessWidget {
  const _MatchesTab({required this.t, required this.accent});
  final TournamentModel t;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (t.matches.isEmpty) {
      return const _Empty('Matches will appear here once scheduled.');
    }
    return Column(
      children:
      t.matches.map((m) => _MatchTile(match: m, accent: accent)).toList(),
    );
  }
}

class _TeamsTab extends StatelessWidget {
  const _TeamsTab({required this.t, required this.accent});
  final TournamentModel t;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (t.teams.isEmpty) {
      return const _Empty('No teams registered yet.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Text('${t.teamsFilled} teams registered',
              style: AppTextStyles.bodySm),
        ),
        ...t.teams.map((tm) => _TeamTile(team: tm, accent: accent)),
      ],
    );
  }
}

class _RulesTab extends StatelessWidget {
  const _RulesTab({required this.t, required this.accent});
  final TournamentModel t;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (t.rules.isEmpty) {
      return const _Empty('Organizer has not added rules yet.');
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: t.rules.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${e.key + 1}.',
                      style: AppTextStyles.bodyMd.copyWith(color: accent)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.value, style: AppTextStyles.bodyMd)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// ============================================================
/// PINNED TAB BAR
/// ============================================================

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  _TabsDelegate({
    required this.tabs,
    required this.selected,
    required this.accent,
    required this.onSelect,
  });
  final List<String> tabs;
  final int selected;
  final Color accent;
  final ValueChanged<int> onSelect;

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tabs.length,
        itemBuilder: (context, i) {
          final active = i == selected;
          return GestureDetector(
            onTap: () => onSelect(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? accent.withValues(alpha: 0.18) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active ? accent : AppColors.border, width: 1),
              ),
              child: Text(
                tabs[i],
                style: AppTextStyles.caption.copyWith(
                  color: active ? accent : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabsDelegate old) =>
      old.selected != selected || old.accent != accent;
}

/// ============================================================
/// BOTTOM CTA
/// ============================================================

class _BottomCta extends StatelessWidget {
  const _BottomCta({required this.tournament});
  final TournamentModel tournament;

  @override
  Widget build(BuildContext context) {
    final t = tournament;

    // Hide bottom CTA for live tournaments as per user request
    if (t.status == TournamentStatus.live) {
      return const SizedBox.shrink();
    }

    late final String label;
    late final IconData icon;
    switch (t.status) {
      case TournamentStatus.upcoming:
        label = t.isFree ? 'JOIN NOW • FREE' : 'JOIN NOW • ${t.formattedEntryFee}';
        icon = Icons.sports_esports_rounded;
        break;
      case TournamentStatus.live:
        label = 'WATCH LIVE';
        icon = Icons.play_circle_fill_rounded;
        break;
      case TournamentStatus.completed:
        label = 'VIEW RESULTS';
        icon = Icons.emoji_events_rounded;
        break;
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: GestureDetector(
          onTap: () {
            if (t.status == TournamentStatus.upcoming) {
              Navigator.of(context).push(
                FirePageRoute(
                  page: JoinTournamentScreen(tournamentId: t.id),
                ),
              );
            }
            // TODO: hook up stream / results navigation
          },
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.fireGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.4),
                    blurRadius: 16),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.bgNavy, size: 20),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.bgNavy,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// SMALL REUSABLE WIDGETS
/// ============================================================

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.t, required this.accent});
  final TournamentModel t;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[
      (Icons.groups_rounded, 'Teams', t.teamsFilled),
      if (t.mode.isNotEmpty) (Icons.sports_esports_rounded, 'Mode', t.mode),
      if (t.mapName.isNotEmpty) (Icons.map_rounded, 'Map', t.mapName),
      if (t.matchType.isNotEmpty) (Icons.bolt_rounded, 'Type', t.matchType),
      (Icons.confirmation_number_rounded, 'Entry', t.formattedEntryFee),
      (Icons.schedule_rounded, 'Starts', _fmt(t.startTime)),
    ];

    return LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - 10) / 2;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items
            .map((i) => SizedBox(
          width: w,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(i.$1, color: accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(i.$2, style: AppTextStyles.caption),
                      Text(i.$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMd
                              .copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ))
            .toList(),
      );
    });
  }

  String _fmt(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ap = d.hour >= 12 ? 'PM' : 'AM';
    final min = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${m[d.month - 1]}, $h:$min $ap';
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.steps, required this.accent});
  final List<ScheduleStep> steps;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: List.generate(steps.length, (i) {
          final s = steps[i];
          final last = i == steps.length - 1;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: s.done ? accent : Colors.transparent,
                        border: Border.all(
                            color: s.done ? accent : AppColors.textMuted,
                            width: 2),
                      ),
                    ),
                    if (!last)
                      Expanded(
                        child: Container(width: 2, color: AppColors.border),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title,
                            style: AppTextStyles.bodyMd
                                .copyWith(fontWeight: FontWeight.w700)),
                        Text(s.time, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📢 '),
          Expanded(child: Text(text, style: AppTextStyles.bodySm)),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow(
      {required this.left, required this.right, this.rightColor});
  final String left;
  final String right;
  final Color? rightColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(left, style: AppTextStyles.bodyMd)),
          Text(right,
              style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w700,
                  color: rightColor ?? Colors.white)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Center(child: Text(text, style: AppTextStyles.bodySm)),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color, width: 1),
    ),
    child: Text(text, style: AppTextStyles.caption.copyWith(color: color)),
  );
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.accent);
  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: AppColors.fireGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(title, style: AppTextStyles.headingMd),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Icon(icon, color: Colors.white, size: 17),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);
  final TournamentStatus status;

  @override
  Widget build(BuildContext context) {
    final live = status == TournamentStatus.live;
    final label = switch (status) {
      TournamentStatus.live => 'LIVE NOW',
      TournamentStatus.upcoming => 'UPCOMING',
      TournamentStatus.completed => 'COMPLETED',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: live ? AppColors.fireGradient : null,
        color: live ? null : Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: live ? null : Border.all(color: Colors.white24),
        boxShadow: live
            ? [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.5), blurRadius: 12)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (live) ...[
            const Icon(Icons.circle, color: Colors.white, size: 8),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _GlassPrizeCard extends StatelessWidget {
  const _GlassPrizeCard({required this.accent, required this.tournament});
  final Color accent;
  final TournamentModel tournament;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppColors.glassBorder(accent),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(gradient: AppColors.glassFill),
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (b) => AppColors.goldGradient.createShader(b),
                  child: const Icon(Icons.emoji_events_rounded,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Prize Pool', style: AppTextStyles.bodySm),
                    const SizedBox(height: 2),
                    Text(tournament.formattedPrizePool,
                        style: AppTextStyles.headingLg
                            .copyWith(color: AppColors.gold)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match, required this.accent});
  final MatchModel match;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
              Text(match.round, style: AppTextStyles.bodySm),
              const Spacer(),
              if (match.isLive)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('LIVE',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.error)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(match.teamA.name,
                    style: AppTextStyles.bodyLg
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
              Text('${match.teamA.score}  -  ${match.teamB.score}',
                  style: AppTextStyles.headingMd.copyWith(color: accent)),
              Expanded(
                child: Text(match.teamB.name,
                    textAlign: TextAlign.end,
                    style: AppTextStyles.bodyLg
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (match.mapOrMode != null) ...[
            const SizedBox(height: 8),
            Text(match.mapOrMode!, style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }
}

class _TeamTile extends StatelessWidget {
  const _TeamTile({required this.team, required this.accent});
  final TeamModel team;
  final Color accent;

  Color get _statusColor => switch (team.status) {
    TeamStatus.winning => AppColors.success,
    TeamStatus.losing => AppColors.warning,
    TeamStatus.eliminated => AppColors.error,
    TeamStatus.qualified => AppColors.secondary,
    TeamStatus.playing => AppColors.textSecondary,
  };

  String get _statusLabel => switch (team.status) {
    TeamStatus.winning => 'Winning',
    TeamStatus.losing => 'Losing',
    TeamStatus.eliminated => 'Eliminated',
    TeamStatus.qualified => 'Qualified',
    TeamStatus.playing => 'Playing',
  };

  @override
  Widget build(BuildContext context) {
    final sub = [
      if (team.captain.isNotEmpty) 'Captain: ${team.captain}',
      if (team.playersCount > 0) '${team.playersCount} players',
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceMuted,
            backgroundImage:
            team.logoUrl.isNotEmpty ? NetworkImage(team.logoUrl) : null,
            child: team.logoUrl.isEmpty
                ? const Icon(Icons.groups_rounded,
                color: AppColors.textMuted, size: 18)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team.name,
                    style: AppTextStyles.bodyLg
                        .copyWith(fontWeight: FontWeight.w700)),
                if (sub.isNotEmpty) Text(sub, style: AppTextStyles.caption),
              ],
            ),
          ),
          Text('${team.score}', style: AppTextStyles.bodySm),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_statusLabel,
                style: AppTextStyles.caption.copyWith(color: _statusColor)),
          ),
        ],
      ),
    );
  }
}