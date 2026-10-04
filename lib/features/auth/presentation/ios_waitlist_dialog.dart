import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pushable_button/pushable_button.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

class IosWaitlistDialog extends StatelessWidget {
  const IosWaitlistDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const IosWaitlistDialog(),
    );
  }

  Future<void> _launchDiscord() async {
    final Uri url = Uri.parse('https://discord.gg/blastix');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryNeon.withValues(alpha: 0.15),
                border: Border.all(
                  color: AppColors.primaryNeon.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: const Text('🚀', style: TextStyle(fontSize: 42)),
            ),
            const SizedBox(height: 20),
            Text(
              'BlastiX Arena for iPhone is Coming Soon! 🚀',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Thank you for signing up! We have added you to our early access list. As soon as the iOS version is released, we will send an invite & download link to your email.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            PushableButton(
              onPressed: _launchDiscord,
              hslColor: HSLColor.fromColor(AppColors.primaryNeon),
              height: 50,
              elevation: 4,
              child: Center(
                child: Text(
                  'Join Discord / Stay Tuned',
                  style: GoogleFonts.poppins(
                    color: AppColors.bgNavy,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Got It',
                style: GoogleFonts.poppins(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
