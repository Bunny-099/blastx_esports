import 'package:flutter/material.dart';

/// Model representing a promotional banner slide on the Home Screen
class BannerItem {
  final String id;
  final String title;
  final String subtitle;
  final String badgeText;
  final String imageUrl;
  final String buttonText;
  final int targetTabIndex; // Index to navigate to when tapped

  const BannerItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.imageUrl,
    required this.buttonText,
    required this.targetTabIndex,
  });
}

/// Model representing a live announcement notice ticker
class AnnouncementItem {
  final String id;
  final String message;
  final String tag;
  final DateTime timestamp;

  const AnnouncementItem({
    required this.id,
    required this.message,
    required this.tag,
    required this.timestamp,
  });
}

/// Model representing a community news/notice board card
class NoticeItem {
  final String id;
  final String title;
  final String description;
  final String category; // e.g. "RULES", "RESULTS", "MAINTENANCE"
  final DateTime date;
  final IconData icon;
  final bool isImportant;

  const NoticeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    required this.icon,
    this.isImportant = false,
  });
}

/// Model representing featured quick stats
class UserHomeStats {
  final int xp;
  final int rank;
  final int matchesPlayed;
  final int totalWins;

  const UserHomeStats({
    required this.xp,
    required this.rank,
    required this.matchesPlayed,
    required this.totalWins,
  });
}
