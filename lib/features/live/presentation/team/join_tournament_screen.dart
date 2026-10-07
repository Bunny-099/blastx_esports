import 'package:blastix_esports/core/theme/app_colors.dart';
import 'package:blastix_esports/core/theme/app_text_styles.dart';
import 'package:blastix_esports/core/transitions/fire_page_route.dart';
import 'package:blastix_esports/features/live/presentation/team/create_team_screen.dart';
import 'package:blastix_esports/features/live/presentation/team/join_team_screen.dart';
import 'package:blastix_esports/features/live/presentation/team/team_lobby_screen.dart';
import 'package:blastix_esports/features/live/presentation/widgets/join_option_card.dart';
import 'package:blastix_esports/features/live/providers/live_provider.dart';
import 'package:blastix_esports/features/live/providers/team_provider.dart';
import 'package:blastix_esports/features/squad/providers/squad_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Entry point of the team flow: Create a Team / Join a Team / Join with Previous Team.
/// If the user already has a team in this tournament, goes straight to it.
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
    await ref.read(teamProvider(widget.tournamentId).notifier).loadMyTeam();
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

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tournamentByIdProvider(widget.tournamentId));
    final error = ref.watch(teamProvider(widget.tournamentId)).error;
    final squadState = ref.watch(squadProvider);

    // Requirement 4: Show "Join with Previous Team" to squad Leaders or Managers who have a stored squad
    final showJoinWithPrevious = squadState.hasSquad && squadState.isOwner;
    final squad = squadState.squad;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
      body: _checking && error == null
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : Padding(
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
            const SizedBox(height: 24),

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
              subtitle: 'Choose role (Leader or Manager) and invite new squad members',
              highlighted: !showJoinWithPrevious,
              onTap: () {
                if (squadState.hasSquad && !squadState.isOwner) {
                  _showAskLeaderDialog(context);
                } else {
                  _open(CreateTeamScreen(tournamentId: widget.tournamentId));
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
                  _showAskLeaderDialog(context);
                } else {
                  _open(JoinTeamScreen(tournamentId: widget.tournamentId));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAskLeaderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderCyan),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceNavy,
                  ),
                  child: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.accentOrange,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'please ask team leader to register the tournament',
              textAlign: TextAlign.center,
              style: AppTextStyles.headingLg.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNeon,
                foregroundColor: AppColors.bgNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text('OK', style: AppTextStyles.button.copyWith(color: AppColors.bgNavy)),
            ),
          ],
        ),
      ),
    );
  }
}
