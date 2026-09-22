import 'package:blastix_esports/core/theme/app_colors.dart';
import 'package:blastix_esports/core/theme/app_text_styles.dart';
import 'package:blastix_esports/shared/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Team code with COPY and SHARE (WhatsApp-friendly text) actions.
class TeamCodeCard extends StatelessWidget {
  const TeamCodeCard({super.key, required this.code, required this.shareText});

  final String code;
  final String shareText;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Team code copied')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryNeon.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text('TEAM CODE', style: AppTextStyles.overline),
          const SizedBox(height: 6),
          Text(code,
              style: AppTextStyles.display
                  .copyWith(color: AppColors.glowLight, letterSpacing: 4)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'COPY CODE',
                  isOutlined: true,
                  icon: const Icon(Icons.copy_rounded,
                      size: 18, color: AppColors.primaryNeon),
                  onPressed: () => _copy(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomButton(
                  text: 'SHARE',
                  icon: const Icon(Icons.share_rounded,
                      size: 18, color: AppColors.bgNavy),
                  onPressed: () => Share.share(shareText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}