import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/home_data_models.dart';

final homeBannersProvider = Provider<List<BannerItem>>((ref) {
  return [
    const BannerItem(
      id: 'b1',
      title: 'BLASTX FF LEAGUE SEASON 4',
      subtitle: '₹100,000 Prize Pool • Squad Registration Open',
      badgeText: 'FEATURED LEAGUE',
      imageUrl: 'assets/images/top_banner.jpg',
      buttonText: 'Join Tournament',
      targetTabIndex: 2, // Tournaments tab
    ),
    const BannerItem(
      id: 'b2',
      title: 'DAILY BGMI SCRIMS',
      subtitle: 'Free Entry • Instant Rewards • Daily at 8 PM',
      badgeText: 'DAILY SCRIMS',
      imageUrl: 'assets/images/top_banner.jpg',
      buttonText: 'Play Scrims',
      targetTabIndex: 1, // Live tab
    ),
    const BannerItem(
      id: 'b3',
      title: 'COMPLETE DAILY QUESTS',
      subtitle: 'Earn XP daily by completing challenges',
      badgeText: 'REWARDS PASS',
      imageUrl: 'assets/images/top_banner.jpg',
      buttonText: 'View Quests',
      targetTabIndex: 3, // Challenges tab
    ),
  ];
});

final homeAnnouncementsProvider = Provider<List<AnnouncementItem>>((ref) {
  return [
    AnnouncementItem(
      id: 'a1',
      message: '🔥 BlastX Winter Championship Registrations are now LIVE!',
      tag: 'NEW',
      timestamp: DateTime.now(),
    ),
    AnnouncementItem(
      id: 'a2',
      message: '⚡ Daily Scrims Slot List updated for 8:00 PM matches.',
      tag: 'SCRIMS',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AnnouncementItem(
      id: 'a3',
      message: '🏆 Weekly Leaderboard rewards distributed to top 10 players!',
      tag: 'REWARDS',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];
});

final homeNoticesProvider = Provider<List<NoticeItem>>((ref) {
  return [
    NoticeItem(
      id: 'n1',
      title: 'Official Tournament Rulebook Updated v2.4',
      description: 'Important updates on substitute player rules and lobby ping checks.',
      category: 'RULEBOOK',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      icon: Icons.gavel_rounded,
      isImportant: true,
    ),
    NoticeItem(
      id: 'n2',
      title: 'BlastX Weekly Showdown #12 Winners',
      description: 'Congratulations to Team GodLike for securing 1st place with 42 kills!',
      category: 'RESULTS',
      date: DateTime.now().subtract(const Duration(days: 1)),
      icon: Icons.emoji_events_rounded,
      isImportant: false,
    ),
    NoticeItem(
      id: 'n3',
      title: 'Scheduled Server Maintenance Notice',
      description: 'Lobby server upgrades on Sunday from 2:00 AM to 4:00 AM IST.',
      category: 'MAINTENANCE',
      date: DateTime.now().subtract(const Duration(days: 2)),
      icon: Icons.build_circle_rounded,
      isImportant: false,
    ),
  ];
});

final userHomeStatsProvider = Provider<UserHomeStats>((ref) {
  return const UserHomeStats(
    xp: 3200,
    rank: 12,
    matchesPlayed: 48,
    totalWins: 18,
  );
});
