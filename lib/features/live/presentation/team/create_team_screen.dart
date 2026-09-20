import 'package:blastx_esports/core/theme/app_colors.dart';
import 'package:blastx_esports/core/theme/app_text_styles.dart';
import 'package:blastx_esports/features/live/presentation/widgets/player_info_form.dart';
import 'package:blastx_esports/features/live/providers/team_provider.dart';
import 'package:blastx_esports/shared/widgets/custom_button.dart';
import 'package:blastx_esports/shared/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key, required this.tournamentId});
  final String tournamentId;

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _teamName = TextEditingController();
  final _tag = TextEditingController();
  final _player = TextEditingController();
  final _ign = TextEditingController();
  final _uid = TextEditingController();
  String? _localError;

  @override
  void initState() {
    super.initState();
    Future.microtask(
            () => ref.read(teamProvider(widget.tournamentId).notifier).clearError());
  }

  @override
  void dispose() {
    for (final c in [_teamName, _tag, _player, _ign, _uid]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _teamName.text.trim();
    final tag = _tag.text.trim().toUpperCase();
    String? err;
    if (name.length < 3) {
      err = 'Team name must be at least 3 characters.';
    } else if (tag.isNotEmpty && (tag.length < 2 || tag.length > 5)) {
      err = 'Team tag must be 2–5 characters.';
    } else {
      err = PlayerInfoForm.validate(_player.text, _ign.text, _uid.text);
    }
    setState(() => _localError = err);
    if (err != null) return;

    final ok = await ref
        .read(teamProvider(widget.tournamentId).notifier)
        .createTeam(
      teamName: name,
      tag: tag,
      playerName: _player.text.trim(),
      ign: _ign.text.trim(),
      uid: _uid.text.trim(),
    );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 14),
    child: Text(t, style: AppTextStyles.overline),
  );

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(teamProvider(widget.tournamentId));
    final error = _localError ?? s.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CREATE TEAM', style: AppTextStyles.display),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded,
                      color: AppColors.gold, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        'You will become the Captain. The entry fee is paid by you, not by each player.',
                        style: AppTextStyles.bodySm),
                  ),
                ],
              ),
            ),
            _label('TEAM NAME'),
            CustomTextField(
                controller: _teamName, hintText: 'e.g. BLX Warriors', maxLength: 20),
            _label('TEAM TAG (OPTIONAL)'),
            CustomTextField(controller: _tag, hintText: 'e.g. BLX', maxLength: 5),
            const SizedBox(height: 22),
            Text('YOUR FREE FIRE DETAILS', style: AppTextStyles.headingMd),
            PlayerInfoForm(
                nameController: _player, ignController: _ign, uidController: _uid),
            if (error != null) ...[
              const SizedBox(height: 14),
              Text(error,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
            ],
            const SizedBox(height: 24),
            CustomButton(
                text: 'CREATE TEAM', isLoading: s.isLoading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}