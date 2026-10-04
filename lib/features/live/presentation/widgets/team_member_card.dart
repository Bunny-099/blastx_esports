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
    this.onAcceptInvite,
    this.onRejectInvite,
  });

  final String slotLabel; // e.g. "1", "S1"
  final TeamMemberModel? member;
  final bool isMe;
  final VoidCallback? onRemove; // shown only for captain controls
  final VoidCallback? onAcceptInvite;
  final VoidCallback? onRejectInvite;

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
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: m.isCaptain
              ? AppColors.glowLight.withValues(alpha: 0.5)
              : (m.isPending ? AppColors.glowSoft.withValues(alpha: 0.6) : AppColors.borderSubtle),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surfaceNavy,
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
                          const _Badge('CAPTAIN', AppColors.glowLight),
                        if (m.isPending)
                          const _Badge('INVITED • PENDING', AppColors.glowSoft)
                        else
                          _Badge(
                            m.isSubstitute ? 'SUB' : 'MAIN',
                            m.isSubstitute ? AppColors.glowSoft : AppColors.primaryNeon,
                          ),
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
              if (onRemove != null && !m.isPending)
                IconButton(
                  tooltip: 'Remove',
                  onPressed: onRemove,
                  icon: const Icon(Icons.person_remove_rounded,
                      color: AppColors.primaryDeep, size: 20),
                ),
            ],
          ),

          // Accept / Reject Actions for invited pending member
          if (m.isPending && (isMe || onAcceptInvite != null)) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNeon,
                      foregroundColor: AppColors.bgNavy,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: onAcceptInvite,
                    child: Text('ACCEPT', style: AppTextStyles.button.copyWith(color: AppColors.bgNavy, fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: onRejectInvite,
                    child: Text('REJECT', style: AppTextStyles.button.copyWith(color: AppColors.error, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _empty() => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.surfaceNavy,
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
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text,
            style: AppTextStyles.caption
                .copyWith(color: color, fontSize: 9.5, fontWeight: FontWeight.w800)),
      );
}
