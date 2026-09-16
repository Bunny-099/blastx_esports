import 'dart:ui';

import 'package:blastx_esports/core/theme/app_colors.dart';
import 'package:blastx_esports/core/theme/app_text_styles.dart';
import 'package:blastx_esports/features/live/data/models/tournament_model.dart';
import 'package:blastx_esports/features/live/providers/live_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ⚠️ Replace "blastx_esports" in the imports above with your actual
/// package name from pubspec.yaml (name: field) if different.

/// ============================================================
/// TOURNAMENT DETAIL SCREEN — Premium Glass Edition
/// ============================================================
/// - Hero continuity with the card (banner image + title)
/// - Stretch/zoom + blur parallax on the banner (pull-to-stretch)
/// - Frosted glass prize pool card with gold gradient accents
/// - Dark cinematic gradient overlay fading into the background
/// ============================================================

class TournamentDetailScreen extends ConsumerWidget {
  const TournamentDetailScreen({super.key, required this.tournamentId});

  final String tournamentId;

  Color _accentColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournament = ref.watch(tournamentByIdProvider(tournamentId));

    if (tournament == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
        body: Center(
          child: Text('Tournament not found', style: AppTextStyles.bodyMd),
        ),
      );
    }

    final accent = _accentColor(tournament.accentColorHex);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ---------------- Collapsible / stretchy banner app bar ----------------
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 280,
            stretchTriggerOffset: 140,
            onStretchTrigger: () async {},
            backgroundColor: AppColors.background,
            leading: _GlassIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
            actions: [
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
                    tag: 'tournament-banner-${tournament.id}',
                    child: Image.network(
                      tournament.bannerImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppColors.surface),
                    ),
                  ),
                  // Cinematic fade into the page background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.background.withOpacity(0.4),
                          AppColors.background,
                        ],
                        stops: const [0.0, 0.65, 1.0],
                      ),
                    ),
                  ),
                  // Accent glow wash
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withOpacity(0.22),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                    ),
                  ),
                  if (tournament.isLive)
                    const Positioned(top: 100, left: 20, child: _StatusPill()),
                ],
              ),
            ),
          ),

          // ---------------- Title + organizer + prize pool ----------------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accent, width: 1),
                        ),
                        child: Text(
                          tournament.game,
                          style: AppTextStyles.caption.copyWith(color: accent),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.remove_red_eye_rounded,
                          color: AppColors.textSecondary, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        '${tournament.formattedViewers} watching',
                        style: AppTextStyles.bodySm,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Hero(
                    tag: 'tournament-title-${tournament.id}',
                    child: Material(
                      type: MaterialType.transparency,
                      child: Text(tournament.name, style: AppTextStyles.headingXl),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Organized by ${tournament.organizer}',
                    style: AppTextStyles.bodySm,
                  ),
                  const SizedBox(height: 20),
                  _GlassPrizeCard(accent: accent, tournament: tournament),
                ],
              ),
            ),
          ),

          // ---------------- Matches Section ----------------
          if (tournament.matches.isNotEmpty) ...[
            _SectionTitle(title: 'Matches', accent: accent),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => _MatchTile(
                      match: tournament.matches[index], accent: accent),
                  childCount: tournament.matches.length,
                ),
              ),
            ),
          ],

          // ---------------- Teams Section ----------------
          if (tournament.teams.isNotEmpty) ...[
            _SectionTitle(title: 'Teams', accent: accent),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                      _TeamTile(team: tournament.teams[index], accent: accent),
                  childCount: tournament.teams.length,
                ),
              ),
            ),
          ] else
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Small reusable widgets
/// ------------------------------------------------------------

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
                color: Colors.black.withOpacity(0.35),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.15)),
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
  const _StatusPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColors.fireGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.secondary.withOpacity(0.5), blurRadius: 12),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: Colors.white, size: 8),
          SizedBox(width: 5),
          Text('LIVE NOW',
              style: TextStyle(
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
            decoration: const BoxDecoration(
              gradient: AppColors.glassFill,
            ),
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
                    Text(
                      tournament.formattedPrizePool,
                      style: AppTextStyles.headingLg
                          .copyWith(color: AppColors.gold),
                    ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.accent});
  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
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
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'LIVE',
                    style: AppTextStyles.caption.copyWith(color: AppColors.error),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  match.teamA.name,
                  style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${match.teamA.score}  -  ${match.teamB.score}',
                style: AppTextStyles.headingMd.copyWith(color: accent),
              ),
              Expanded(
                child: Text(
                  match.teamB.name,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w700),
                ),
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

  Color get _statusColor {
    switch (team.status) {
      case TeamStatus.winning:
        return AppColors.success;
      case TeamStatus.losing:
        return AppColors.warning;
      case TeamStatus.eliminated:
        return AppColors.error;
      case TeamStatus.qualified:
        return AppColors.secondary;
      case TeamStatus.playing:
        return AppColors.textSecondary;
    }
  }

  String get _statusLabel {
    switch (team.status) {
      case TeamStatus.winning:
        return 'Winning';
      case TeamStatus.losing:
        return 'Losing';
      case TeamStatus.eliminated:
        return 'Eliminated';
      case TeamStatus.qualified:
        return 'Qualified';
      case TeamStatus.playing:
        return 'Playing';
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: Text(
              team.name,
              style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Text('Score: ${team.score}', style: AppTextStyles.bodySm),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel,
              style: AppTextStyles.caption.copyWith(color: _statusColor),
            ),
          ),
        ],
      ),
    );
  }
}