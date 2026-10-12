import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blastix_esports/core/theme/app_colors.dart';
import 'package:blastix_esports/core/theme/app_text_styles.dart';
import 'package:blastix_esports/core/transitions/fire_page_route.dart';
import 'package:blastix_esports/features/live/presentation/tournament_detail_screen.dart';
import 'package:blastix_esports/features/live/presentation/widgets/player_info_form.dart';
import 'package:blastix_esports/features/live/providers/live_provider.dart';
import 'package:blastix_esports/features/live/providers/team_provider.dart';
import 'package:blastix_esports/features/profile/providers/profile_provider.dart';
import 'package:blastix_esports/shared/widgets/custom_button.dart';

/// Screen for Solo tournament registration without creating a team.
class SoloRegisterScreen extends ConsumerStatefulWidget {
  const SoloRegisterScreen({
    super.key,
    required this.tournamentId,
  });

  final String tournamentId;

  @override
  ConsumerState<SoloRegisterScreen> createState() => _SoloRegisterScreenState();
}

class _SoloRegisterScreenState extends ConsumerState<SoloRegisterScreen> {
  final _playerController = TextEditingController();
  final _uidController = TextEditingController();

  String? _localError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
    for (final c in [_playerController, _uidController]) {
      c.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  void _prefillFromProfile() {
    final user = ref.read(profileProvider).user;
    if (user != null) {
      if (_playerController.text.trim().isEmpty) {
        _playerController.text = user.gameProfile?.inGameName ?? user.name;
      }
      if (_uidController.text.trim().isEmpty) {
        _uidController.text = user.gameProfile?.inGameUid ?? '';
      }
    }
  }

  @override
  void dispose() {
    _playerController.dispose();
    _uidController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final player = _playerController.text.trim();
    final uid = _uidController.text.trim();

    final err = PlayerInfoForm.validate(player, uid);
    setState(() => _localError = err);
    if (err != null) return;

    final tournament = ref.read(tournamentByIdProvider(widget.tournamentId));
    if (tournament != null &&
        tournament.entryFee > 0 &&
        !tournament.formattedEntryFee.toLowerCase().contains('free')) {
      setState(() {
        _localError = 'Paid entry not available yet';
      });
      return;
    }

    setState(() => _isSubmitting = true);

    final ok = await ref
        .read(teamProvider(widget.tournamentId).notifier)
        .registerSolo(ign: player, uid: uid);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      Navigator.of(context).pushReplacement(
        FirePageRoute(
          page: TournamentDetailScreen(
            tournamentId: widget.tournamentId,
            initialTabIndex: 4, // Match tab
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ProfileState>(profileProvider, (previous, next) {
      if (next.user != null) {
        _prefillFromProfile();
      }
    });

    final tournament = ref.watch(tournamentByIdProvider(widget.tournamentId));
    final teamState = ref.watch(teamProvider(widget.tournamentId));
    final error = _localError ?? teamState.error;

    final entryFeeLabel = tournament?.formattedEntryFee ?? 'Free';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('SOLO REGISTRATION', style: AppTextStyles.headingLg),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('REGISTER FOR TOURNAMENT', style: AppTextStyles.display),
            const SizedBox(height: 4),
            Text(tournament?.displayTitle ?? '', style: AppTextStyles.bodyLg),
            const SizedBox(height: 16),

            // Tournament Info Summary Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sports_esports_rounded,
                          color: AppColors.primaryNeon, size: 20),
                      const SizedBox(width: 10),
                      Text('Mode:', style: AppTextStyles.bodySm),
                      const Spacer(),
                      Text('SOLO',
                          style: AppTextStyles.bodyLg
                              .copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 20),
                  Row(
                    children: [
                      const Icon(Icons.confirmation_number_rounded,
                          color: AppColors.primaryNeon, size: 20),
                      const SizedBox(width: 10),
                      Text('Entry Fee:', style: AppTextStyles.bodySm),
                      const Spacer(),
                      Text(entryFeeLabel,
                          style: AppTextStyles.bodyLg.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNeon,
                          )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('YOUR FREE FIRE DETAILS', style: AppTextStyles.headingMd),
            const SizedBox(height: 12),
            PlayerInfoForm(
              nameController: _playerController,
              uidController: _uidController,
            ),

            if (error != null) ...[
              const SizedBox(height: 14),
              Text(error,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
            color: AppColors.surfaceNavy,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: CustomButton(
            text: 'REGISTER NOW',
            isLoading: _isSubmitting || teamState.isLoading,
            onPressed: (_isSubmitting || teamState.isLoading) ? null : _submit,
          ),
        ),
      ),
    );
  }
}
