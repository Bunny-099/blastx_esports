import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/transitions/fire_page_route.dart';
import '../../../live/data/models/tournament_model.dart';
import '../../../live/presentation/team/team_lobby_screen.dart';
import '../../../live/presentation/tournament_detail_screen.dart';
import '../../../live/providers/team_provider.dart';

/// Central helper function to handle tournament card taps.
/// If user's squad has already joined/registered for this tournament, shows a dual option sheet
/// ("View Tournament Detail" vs "View Waitlist").
/// Otherwise, directly navigates to TournamentDetailScreen.
void handleTournamentCardTap(
  BuildContext context,
  WidgetRef ref,
  TournamentModel tournament, {
  bool viewOnly = false,
}) {
  final teamState = ref.read(teamProvider(tournament.id));
  final isRegistered = tournament.effectiveIsRegistered ||
      (teamState.team != null && (teamState.team!.isRegistered || teamState.team!.members.isNotEmpty));

  if (isRegistered && !viewOnly) {
    showJoinedTournamentOptionsModal(
      context: context,
      tournament: tournament,
    );
  } else {
    Navigator.of(context).push(
      FirePageRoute(
        page: TournamentDetailScreen(
          tournamentId: tournament.id,
          viewOnly: viewOnly,
        ),
      ),
    );
  }
}

/// Displays action bottom sheet when clicking a joined/registered tournament card
void showJoinedTournamentOptionsModal({
  required BuildContext context,
  required TournamentModel tournament,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tournament.displayTitle,
                style: AppTextStyles.headingXl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.primaryNeon, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'JOINED TOURNAMENT',
                    style: GoogleFonts.orbitron(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNeon,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Option 1: VIEW TOURNAMENT DETAIL
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AppColors.primaryNeon.withValues(alpha: 0.4)),
                ),
                tileColor: AppColors.surfaceNavy,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: AppColors.primaryNeon, size: 20),
                ),
                title: Text(
                  'VIEW TOURNAMENT DETAIL',
                  style: GoogleFonts.orbitron(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'View tournament schedule, rules & prize distribution',
                  style: AppTextStyles.caption,
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryNeon),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    FirePageRoute(
                      page: TournamentDetailScreen(tournamentId: tournament.id),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Option 2: VIEW WAITLIST / TEAM LOBBY
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AppColors.accentOrange.withValues(alpha: 0.5)),
                ),
                tileColor: AppColors.surfaceNavy,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_empty_rounded, color: AppColors.accentOrange, size: 20),
                ),
                title: Text(
                  'VIEW WAITLIST',
                  style: GoogleFonts.orbitron(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Check squad waitlist status & player acceptance requests',
                  style: AppTextStyles.caption,
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.accentOrange),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    FirePageRoute(
                      page: TeamLobbyScreen(tournamentId: tournament.id),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    },
  );
}
