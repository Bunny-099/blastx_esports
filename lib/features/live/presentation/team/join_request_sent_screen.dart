import 'package:blastix_esports/core/theme/app_colors.dart';
import 'package:blastix_esports/core/theme/app_text_styles.dart';
import 'package:blastix_esports/features/live/providers/team_provider.dart';
import 'package:blastix_esports/shared/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class JoinRequestSentScreen extends ConsumerStatefulWidget {
  const JoinRequestSentScreen({
    super.key,
    required this.tournamentId,
    required this.requestId,
    required this.teamName,
    this.teamLogoUrl = '',
    this.ownerName = 'Leader',
    this.tournamentName = '',
  });

  final String tournamentId;
  final String requestId;
  final String teamName;
  final String teamLogoUrl;
  final String ownerName;
  final String tournamentName;

  @override
  ConsumerState<JoinRequestSentScreen> createState() => _JoinRequestSentScreenState();
}

class _JoinRequestSentScreenState extends ConsumerState<JoinRequestSentScreen> {
  bool _isCancelling = false;

  Future<void> _cancelRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Cancel Request?', style: AppTextStyles.headingLg),
        content: Text(
          'Are you sure you want to cancel your request to join ${widget.teamName}?',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('No, Keep Request'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text('Yes, Cancel', style: AppTextStyles.button.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isCancelling = true);
    final ok = await ref.read(myPendingRequestsProvider.notifier).cancelRequest(widget.requestId);
    if (!mounted) return;
    setState(() => _isCancelling = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join request cancelled successfully.')),
      );
      Navigator.of(context).pop(false);
    } else {
      final err = ref.read(myPendingRequestsProvider).error ?? 'Failed to cancel request.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // Team Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.surfaceMuted,
                backgroundImage: widget.teamLogoUrl.isNotEmpty ? NetworkImage(widget.teamLogoUrl) : null,
                child: widget.teamLogoUrl.isEmpty
                    ? const Icon(Icons.groups_rounded, color: AppColors.textMuted, size: 40)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                widget.teamName.toUpperCase(),
                style: AppTextStyles.display,
                textAlign: TextAlign.center,
              ),
              if (widget.tournamentName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.tournamentName,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 28),

              // Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.hourglass_top_rounded,
                      color: AppColors.accentOrange,
                      size: 36,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'REQUEST SENT',
                      style: AppTextStyles.headingLg.copyWith(
                        color: AppColors.accentOrange,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Waiting for ${widget.ownerName.isNotEmpty ? widget.ownerName : "owner"} to approve your request.',
                      style: AppTextStyles.bodyLg,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You will receive a notification as soon as your request is reviewed.',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Actions
              CustomButton(
                text: 'CANCEL REQUEST',
                isOutlined: true,
                isLoading: _isCancelling,
                onPressed: _cancelRequest,
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'BACK TO TOURNAMENT',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
