import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/tournament_model.dart';
import '../widgets/room_details_card.dart';
import '../widgets/tournament_roadmap_widget.dart';

/// ============================================================
/// OVERVIEW TAB
/// Rules, Prize Split, Stages & Bracket, Stream Link, Organizer Info
/// ============================================================

class OverviewTab extends StatefulWidget {
  const OverviewTab({
    super.key,
    required this.tournament,
    required this.accentColor,
    this.viewOnly = false,
  });

  final TournamentModel tournament;
  final Color accentColor;
  final bool viewOnly;

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = widget.tournament;
    final accent = widget.accentColor;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Room Details Card (for Live / Upcoming tournaments) ──
          RoomDetailsCard(
            tournament: t,
            accentColor: accent,
            viewOnly: widget.viewOnly,
          ),

          // ── Stream Link Card (if available) ──
          if (t.streamUrl != null && t.streamUrl!.isNotEmpty) ...[
            _StreamLinkCard(streamUrl: t.streamUrl!, accent: accent),
          ],

          // ── Announcements ──
          if (t.announcements.isNotEmpty) ...[
            _Section('Announcements', accent),
            ...t.announcements.map((a) => _AnnouncementTile(text: a)),
          ],

          // ── Prize Distribution / Split ──
          if (t.prizeDistribution.isNotEmpty ||
              t.booyahBonus > 0 ||
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

          // ── Stages & Bracket Roadmap ──
          _Section('Stages & Bracket', accent),
          TournamentRoadmapWidget(tournament: t, accentColor: accent),

          // ── Points System ──
          if (t.pointsSystem.isNotEmpty) ...[
            _Section('Points System', accent),
            _Card(
              child: Column(
                children: t.pointsSystem
                    .map((p) => _KeyValueRow(left: p.label, right: p.points))
                    .toList(),
              ),
            ),
          ],

          // ── Schedule Timeline ──
          if (t.schedule.isNotEmpty) ...[
            _Section('Schedule', accent),
            _Timeline(steps: t.schedule, accent: accent),
          ],

          // ── Rules & Regulations ──
          if (t.rules.isNotEmpty) ...[
            _Section('Rules & Regulations', accent),
            _Card(
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
          ],

          // ── Organizer Info ──
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

          // ── Need Help? ──
          _Section('Need help?', accent),
          _Card(
            child: Row(
              children: [
                Icon(Icons.support_agent_rounded, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      'Payment, match or room issue? Contact support.',
                      style: AppTextStyles.bodySm),
                ),
                TextButton(onPressed: () {}, child: const Text('Contact')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _medal(int i) => i == 0 ? '🥇 ' : i == 1 ? '🥈 ' : i == 2 ? '🥉 ' : '';
}

class _StreamLinkCard extends StatelessWidget {
  const _StreamLinkCard({required this.streamUrl, required this.accent});
  final String streamUrl;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_circle_fill_rounded,
              color: AppColors.accentOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Live Stream',
                    style: AppTextStyles.bodyLg
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Watch live broadcast on YouTube / Twitch',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Open streamUrl
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentOrange,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'WATCH',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
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
