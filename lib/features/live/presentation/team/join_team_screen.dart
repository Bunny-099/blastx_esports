import 'package:blastx_esports/core/theme/app_colors.dart';
import 'package:blastx_esports/core/theme/app_text_styles.dart';
import 'package:blastx_esports/core/transitions/fire_page_route.dart';
import 'package:blastx_esports/features/live/presentation/team/team_preview_screen.dart';
import 'package:blastx_esports/features/live/providers/team_provider.dart';
import 'package:blastx_esports/shared/widgets/custom_button.dart';
import 'package:blastx_esports/shared/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class JoinTeamScreen extends ConsumerStatefulWidget {
  const JoinTeamScreen({super.key, required this.tournamentId});
  final String tournamentId;

  @override
  ConsumerState<JoinTeamScreen> createState() => _JoinTeamScreenState();
}

class _JoinTeamScreenState extends ConsumerState<JoinTeamScreen> {
  final _code = TextEditingController();
  String? _localError;

  @override
  void initState() {
    super.initState();
    Future.microtask(
            () => ref.read(teamProvider(widget.tournamentId).notifier).clearError());
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    final code = _code.text.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{4,10}$').hasMatch(code)) {
      setState(() => _localError = 'Enter a valid team code (letters and numbers).');
      return;
    }
    setState(() => _localError = null);

    final ok =
    await ref.read(teamProvider(widget.tournamentId).notifier).lookupTeam(code);
    if (!ok || !mounted) return;

    final joined = await Navigator.of(context).push(
        FirePageRoute(page: TeamPreviewScreen(tournamentId: widget.tournamentId)));
    if (joined == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(teamProvider(widget.tournamentId));
    final error = _localError ?? s.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('JOIN A TEAM', style: AppTextStyles.display),
            const SizedBox(height: 6),
            Text('Ask your captain for the team code.',
                style: AppTextStyles.bodyMd),
            const SizedBox(height: 24),
            Text('ENTER TEAM CODE', style: AppTextStyles.overline),
            const SizedBox(height: 6),
            CustomTextField(controller: _code, hintText: 'e.g. BLX7K29', maxLength: 10),
            if (error != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(error,
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.error)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            CustomButton(text: 'FIND TEAM', isLoading: s.isLoading, onPressed: _find),
          ],
        ),
      ),
    );
  }
}