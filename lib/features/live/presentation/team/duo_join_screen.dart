import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blastix_esports/core/theme/app_colors.dart';
import 'package:blastix_esports/core/theme/app_text_styles.dart';
import 'package:blastix_esports/core/transitions/fire_page_route.dart';
import 'package:blastix_esports/features/live/data/models/team_model.dart';
import 'package:blastix_esports/features/live/presentation/team/create_team_screen.dart';
import 'package:blastix_esports/features/live/presentation/team/join_team_screen.dart';
import 'package:blastix_esports/features/live/presentation/team/team_lobby_screen.dart';
import 'package:blastix_esports/features/live/presentation/widgets/join_option_card.dart';
import 'package:blastix_esports/features/live/providers/live_provider.dart';
import 'package:blastix_esports/features/live/providers/team_provider.dart';

/// Screen for Duo tournament flow: Create Duo Team or Join with Team Code.
class DuoJoinScreen extends ConsumerStatefulWidget {
  const DuoJoinScreen({super.key, required this.tournamentId});
  final String tournamentId;

  @override
  ConsumerState<DuoJoinScreen> createState() => _DuoJoinScreenState();
}

class _DuoJoinScreenState extends ConsumerState<DuoJoinScreen> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_checkExistingTeam);
  }

  Future<void> _checkExistingTeam() async {
    await Future.wait([
      ref.read(teamProvider(widget.tournamentId).notifier).loadMyTeam(),
      ref.read(myPendingRequestsProvider.notifier).fetchPendingRequests(),
    ]);
    if (!mounted) return;
    if (ref.read(teamProvider(widget.tournamentId)).team != null) {
      _openLobby(replace: true);
    } else {
      setState(() => _checking = false);
    }
  }

  void _openLobby({bool replace = false}) {
    final route = FirePageRoute(
        page: TeamLobbyScreen(tournamentId: widget.tournamentId));
    final nav = Navigator.of(context);
    replace ? nav.pushReplacement(route) : nav.push(route);
  }

  Future<void> _open(Widget page) async {
    final ok = await Navigator.of(context).push(FirePageRoute(page: page));
    if (ok == true && mounted) _openLobby(replace: true);
  }

  Future<void> _cancelRequest(JoinRequest req) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Cancel Request?', style: AppTextStyles.headingLg),
        content: Text(
          'Are you sure you want to cancel your request to join ${req.teamName}?',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text('Yes, Cancel', style: AppTextStyles.button.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final ok = await ref.read(myPendingRequestsProvider.notifier).cancelRequest(req.id);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join request cancelled.')),
      );
    } else {
      final err = ref.read(myPendingRequestsProvider).error ?? 'Failed to cancel request.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tournamentByIdProvider(widget.tournamentId));
    final error = ref.watch(teamProvider(widget.tournamentId)).error;
    final myPendingState = ref.watch(myPendingRequestsProvider);

    JoinRequest? pendingRequest;
    for (final req in myPendingState.pendingRequests) {
      if (req.tournamentId == widget.tournamentId) {
        pendingRequest = req;
        break;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
      body: _checking && error == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DUO TOURNAMENT', style: AppTextStyles.display),
                  const SizedBox(height: 4),
                  Text(t?.name ?? '', style: AppTextStyles.bodyMd),
                  const SizedBox(height: 8),
                  Text('2 Playing Members • No Substitutes',
                      style: AppTextStyles.bodySm),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error,
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.error)),
                  ],
                  const SizedBox(height: 20),

                  // Pending Join Request Card
                  if (pendingRequest != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.accentOrange.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.hourglass_top_rounded,
                                  color: AppColors.accentOrange, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'PENDING REQUEST SENT',
                                style: AppTextStyles.headingMd.copyWith(
                                    color: AppColors.accentOrange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Team: ${pendingRequest.teamName}',
                            style: AppTextStyles.headingLg,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Waiting for team leader approval.',
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Spacer(),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                ),
                                onPressed: () => _cancelRequest(pendingRequest!),
                                icon: const Icon(Icons.close_rounded, size: 16),
                                label: const Text('CANCEL REQUEST'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Option 1: CREATE DUO TEAM
                  JoinOptionCard(
                    icon: Icons.group_add_rounded,
                    title: 'CREATE DUO TEAM',
                    subtitle: 'You are the Leader. Share your Team Code with your partner.',
                    highlighted: true,
                    onTap: () {
                      _open(CreateTeamScreen(
                        tournamentId: widget.tournamentId,
                        isDuoMode: true,
                      ));
                    },
                  ),
                  const SizedBox(height: 16),

                  // Option 2: JOIN WITH TEAM CODE
                  JoinOptionCard(
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'JOIN WITH TEAM CODE',
                    subtitle: 'Enter a duo team code from your partner',
                    onTap: () {
                      _open(JoinTeamScreen(
                        tournamentId: widget.tournamentId,
                      ));
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
