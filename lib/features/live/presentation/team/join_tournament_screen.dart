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
import 'package:blastix_esports/features/squad/presentation/widgets/ask_leader_dialog.dart';
import 'package:blastix_esports/features/squad/providers/squad_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Entry point of the team flow: Create a Team / Join a Team / Join with Previous Team.
/// If the user already has a team in this tournament, goes straight to it.
/// If the user has a PENDING request, displays a Pending Request card.
class JoinTournamentScreen extends ConsumerStatefulWidget {
  const JoinTournamentScreen({super.key, required this.tournamentId});
  final String tournamentId;

  @override
  ConsumerState<JoinTournamentScreen> createState() =>
      _JoinTournamentScreenState();
}

class _JoinTournamentScreenState extends ConsumerState<JoinTournamentScreen> {
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

  /// Child screens pop with `true` once the user is in a team.
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
    final squadState = ref.watch(squadProvider);
    final myPendingState = ref.watch(myPendingRequestsProvider);

    // Check if user has a pending request for this tournament
    JoinRequest? pendingRequest;
    for (final req in myPendingState.pendingRequests) {
      if (req.tournamentId == widget.tournamentId) {
        pendingRequest = req;
        break;
      }
    }

    final showJoinWithPrevious = squadState.hasSquad && squadState.isOwner;
    final squad = squadState.squad;

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
                  Text('JOIN TOURNAMENT', style: AppTextStyles.display),
                  const SizedBox(height: 4),
                  Text(t?.name ?? '', style: AppTextStyles.bodyMd),
                  const SizedBox(height: 8),
                  Text('Squad of 4 • up to 2 substitutes',
                      style: AppTextStyles.bodySm),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error,
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.error)),
                  ],
                  const SizedBox(height: 20),

                  // Pending Join Request Card (If user requested to join a team)
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
                            'Waiting for team owner approval.',
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

                  // Option 1 (LEADER OR MANAGER): JOIN WITH PREVIOUS TEAM
                  if (showJoinWithPrevious && squad != null) ...[
                    JoinOptionCard(
                      icon: Icons.replay_rounded,
                      title: 'JOIN WITH PREVIOUS TEAM',
                      subtitle: squad.isManagerOwned
                          ? 'Invite all 4 stored members from squad "${squad.name}" (Manager non-playing)'
                          : 'Invite stored squad "${squad.name}" members (3 players) to this tournament',
                      highlighted: true,
                      onTap: () async {
                        await ref
                            .read(teamProvider(widget.tournamentId).notifier)
                            .createTeamWithPreviousSquad(squad);
                        _openLobby(replace: true);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Option 2: CREATE A TEAM
                  JoinOptionCard(
                    icon: Icons.add_moderator_rounded,
                    title: 'CREATE A NEW TEAM',
                    subtitle:
                        'Choose role (Leader or Manager) and invite new squad members',
                    highlighted: !showJoinWithPrevious,
                    onTap: () {
                      if (squadState.hasSquad && !squadState.isOwner) {
                        showAskLeaderDialog(context);
                      } else {
                        _open(CreateTeamScreen(
                            tournamentId: widget.tournamentId));
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Option 3: JOIN AN EXISTING TEAM
                  JoinOptionCard(
                    icon: Icons.group_add_rounded,
                    title: 'JOIN AN EXISTING TEAM',
                    subtitle: 'Enter a team code from your leader or manager',
                    onTap: () {
                      if (squadState.hasSquad && !squadState.isOwner) {
                        showAskLeaderDialog(context);
                      } else {
                        _open(JoinTeamScreen(
                            tournamentId: widget.tournamentId));
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
