import 'package:blastix_esports/core/theme/app_colors.dart';
import 'package:blastix_esports/core/theme/app_text_styles.dart';
import 'package:blastix_esports/features/live/data/models/team_member_model.dart';
import 'package:flutter/material.dart';

/// Player row for the roster. Pass `member: null` for an empty slot.
class TeamMemberCard extends StatelessWidget {
  const TeamMemberCard({
    super.key,
    required this.slotLabel,
    this.member,
    this.isMe = false,
    this.onRemove,
  });

  final String slotLabel; // e.g. "1", "S1"
  final TeamMemberModel? member;
  final bool isMe;
  final VoidCallback? onRemove; // shown only for captain controls

  @override
  Widget build(BuildContext context) {
    final m = member;
    if (m == null) return _empty();

    final details = [
      if (m.ign.isNotEmpty) 'IGN: ${m.ign}',
      if (m.uid.isNotEmpty) 'UID: ${m.uid}',
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: m.isCaptain
                ? AppColors.gold.withOpacity(0.5)
                : AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceMuted,
            backgroundImage:
            m.avatarUrl.isNotEmpty ? NetworkImage(m.avatarUrl) : null,
            child: m.avatarUrl.isEmpty
                ? Text(
              m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
              style: AppTextStyles.headingMd,
            )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(isMe ? '${m.name} (You)' : m.name,
                        style: AppTextStyles.bodyLg
                            .copyWith(fontWeight: FontWeight.w700)),
                    if (m.isCaptain)
                      _Badge('CAPTAIN', AppColors.gold),
                    _Badge(m.isSubstitute ? 'SUB' : 'MAIN',
                        m.isSubstitute ? AppColors.warning : AppColors.success),
                  ],
                ),
                if (details.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(details, style: AppTextStyles.caption),
                  ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Remove',
              onPressed: onRemove,
              icon: const Icon(Icons.person_remove_rounded,
                  color: AppColors.error, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _empty() => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.surface.withOpacity(0.5),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.surfaceMuted,
          child: Text(slotLabel, style: AppTextStyles.caption),
        ),
        const SizedBox(width: 12),
        Text('Waiting for player…', style: AppTextStyles.bodySm),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(text,
        style: AppTextStyles.caption
            .copyWith(color: color, fontSize: 9.5, fontWeight: FontWeight.w800)),
  );
}