import 'package:blastx_esports/core/theme/app_colors.dart';
import 'package:blastx_esports/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Big tappable card used for "Create a Team" / "Join a Team".
class JoinOptionCard extends StatelessWidget {
  const JoinOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: highlighted ? AppColors.fireGradient : null,
          color: highlighted ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: highlighted ? null : Border.all(color: AppColors.border),
          boxShadow: highlighted
              ? [
            BoxShadow(
                color: AppColors.secondary.withOpacity(0.35),
                blurRadius: 18)
          ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: highlighted
                    ? Colors.white.withOpacity(0.18)
                    : AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon,
                  color: highlighted ? Colors.white : AppColors.primary,
                  size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.headingLg
                          .copyWith(color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.bodySm.copyWith(
                          color: highlighted
                              ? Colors.white.withOpacity(0.85)
                              : AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16,
                color: highlighted ? Colors.white : AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}