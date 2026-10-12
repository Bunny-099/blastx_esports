import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/transitions/fire_page_route.dart';
import '../../../live/data/models/tournament_model.dart';
import '../../../live/presentation/tournament_detail_screen.dart';

/// Central helper function to handle tournament card taps.
/// Tapping any card (Home, Tournaments, Live, and Upcoming) opens TournamentDetailScreen directly.
void handleTournamentCardTap(
  BuildContext context,
  WidgetRef ref,
  TournamentModel tournament, {
  bool viewOnly = false,
}) {
  Navigator.of(context).push(
    FirePageRoute(
      page: TournamentDetailScreen(
        tournamentId: tournament.id,
        viewOnly: viewOnly,
      ),
    ),
  );
}
