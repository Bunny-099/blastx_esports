import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Popup dialog shown when a regular member attempts to register or join a tournament while in a team.
void showAskLeaderDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.borderCyan),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceNavy,
                ),
                child: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.accentOrange,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'please ask team leader to register the tournament',
            textAlign: TextAlign.center,
            style: AppTextStyles.headingLg.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Only the Team Leader or Manager can register your squad for tournaments.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNeon,
              foregroundColor: AppColors.bgNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(120, 44),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: AppTextStyles.button.copyWith(color: AppColors.bgNavy)),
          ),
        ],
      ),
    ),
  );
}
