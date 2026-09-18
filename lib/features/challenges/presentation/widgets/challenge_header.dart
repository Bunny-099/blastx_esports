import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ChallengeHeader extends StatefulWidget {
  const ChallengeHeader({super.key});

  @override
  State<ChallengeHeader> createState() => _ChallengeHeaderState();
}

class _ChallengeHeaderState extends State<ChallengeHeader> {
  late Timer _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _calculateTimeLeft();
      });
    });
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _timeLeft = tomorrow.difference(now);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DAILY',
                style: AppTextStyles.overline.copyWith(color: AppColors.primary),
              ),
              Text(
                'CHALLENGES',
                style: AppTextStyles.display.copyWith(height: 1.1),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(
                  'RESETS IN',
                  style: AppTextStyles.caption.copyWith(fontSize: 8),
                ),
                Text(
                  _formatDuration(_timeLeft),
                  style: AppTextStyles.headingMd.copyWith(
                    color: AppColors.gold,
                    fontFamily: 'Courier', // Monospace for timer
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
