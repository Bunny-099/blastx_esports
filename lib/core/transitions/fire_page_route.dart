import 'package:flutter/material.dart';

/// ============================================================
/// FIRE PAGE ROUTE
/// ============================================================
/// Custom page transition used across the app instead of the
/// default platform slide. Combines a fade + gentle upward slide
/// + micro scale for a premium, cinematic feel.
///
/// Usage:
///   Navigator.of(context).push(
///     FirePageRoute(page: TournamentDetailScreen(tournamentId: id)),
///   );
/// ============================================================

class FirePageRoute<T> extends PageRouteBuilder<T> {
  FirePageRoute({required this.page})
      : super(
    transitionDuration: const Duration(milliseconds: 480),
    reverseTransitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final slide = Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(curved);

      final scale = Tween<double>(begin: 0.97, end: 1.0).animate(curved);

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: slide,
          child: ScaleTransition(scale: scale, child: child),
        ),
      );
    },
  );

  final Widget page;
}