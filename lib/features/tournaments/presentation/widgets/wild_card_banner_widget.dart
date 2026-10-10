import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../live/data/models/tournament_matches_model.dart';

/// ============================================================
/// WILD CARD BANNER WIDGET
/// Displays real-time Wild Card 8-slot tracker & direct entry CTA
/// ============================================================

class WildCardBannerWidget extends StatelessWidget {
  const WildCardBannerWidget({
    super.key,
    required this.wildCardWindow,
    this.onClaimPressed,
  });

  final WildCardWindowModel wildCardWindow;
  final VoidCallback? onClaimPressed;

  @override
  Widget build(BuildContext context) {
    final isOpen = wildCardWindow.isOpen;
    final claimed = wildCardWindow.claimedSlots;
    final max = wildCardWindow.maxSlots;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOpen
              ? [
                  AppColors.accentOrange.withValues(alpha: 0.25),
                  AppColors.primaryNeon.withValues(alpha: 0.15),
                ]
              : [
                  AppColors.surfaceMuted,
                  AppColors.surface,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOpen ? AppColors.accentOrange : AppColors.borderSubtle,
          width: isOpen ? 1.5 : 1.0,
        ),
        boxShadow: isOpen
            ? [
                BoxShadow(
                  color: AppColors.accentOrange.withValues(alpha: 0.2),
                  blurRadius: 14,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOpen ? AppColors.accentOrange : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOpen ? Icons.local_fire_department_rounded : Icons.lock_clock_rounded,
                      color: isOpen ? Colors.black : AppColors.textMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOpen ? 'WILD CARD OPEN' : 'WILD CARD CLOSED',
                      style: AppTextStyles.caption.copyWith(
                        color: isOpen ? Colors.black : AppColors.textMuted,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Real-time Slot Tracker
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgNavy,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  '[$claimed / $max Slots Claimed]',
                  style: AppTextStyles.caption.copyWith(
                    color: isOpen ? AppColors.primaryNeon : AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Banner Text
          Text(
            isOpen
                ? wildCardWindow.bannerText
                : 'Wild Card Entry is currently closed ($claimed/$max Slots Claimed).',
            style: AppTextStyles.bodyLg.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 14,
            ),
          ),

          if (isOpen && onClaimPressed != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onClaimPressed,
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: Text('CLAIM WILD CARD SLOT ($claimed/$max FILLED)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: AppTextStyles.button.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
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
