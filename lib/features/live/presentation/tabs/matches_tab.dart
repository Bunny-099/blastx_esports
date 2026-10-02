import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// ============================================================
/// MATCHES TAB (PLACEHOLDER)
/// ============================================================

class MatchesTab extends StatefulWidget {
  const MatchesTab({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  State<MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends State<MatchesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
              'Matches Coming Soon',
              style: AppTextStyles.headingMd,
            ),
            const SizedBox(height: 8),
            Text(
              'Match schedules and room details will appear here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
