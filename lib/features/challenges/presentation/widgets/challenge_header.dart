import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ChallengeHeader extends StatelessWidget {
  const ChallengeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DAILY',
            style: AppTextStyles.overline.copyWith(color: AppColors.primaryNeon),
          ),
          Text(
            'CHALLENGES',
            style: AppTextStyles.display.copyWith(height: 1.1),
          ),
        ],
      ),
    );
  }
}
