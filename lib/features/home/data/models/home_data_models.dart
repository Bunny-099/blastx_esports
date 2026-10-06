import 'package:flutter/material.dart';

/// Model representing a dynamic promotional hero banner slide on the Home Screen
class BannerItem {
  final String id;
  final String tagline;
  final String title;
  final String subtitle;
  final String brandBadge;
  final String imageUrl;
  final String buttonText;
  final int targetTabIndex; // Navigation tab index when tapped

  const BannerItem({
    required this.id,
    this.tagline = 'BHADRAK GAMING CHAMPIONSHIP',
    required this.title,
    required this.subtitle,
    this.brandBadge = 'GAME COMMUNITY CULTURE',
    required this.imageUrl,
    this.buttonText = 'KNOW MORE →',
    required this.targetTabIndex,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['id'] as String? ?? 'banner_1',
      tagline: json['tagline'] as String? ?? 'BHADRAK GAMING CHAMPIONSHIP',
      title: json['title'] as String? ?? 'BGC 2026',
      subtitle: json['subtitle'] as String? ?? 'BIGGER SQUADS. BIGGER BATTLES. BHADRAK PRIDE.',
      brandBadge: json['brand_badge'] as String? ?? 'GAME COMMUNITY CULTURE',
      imageUrl: json['image_url'] as String? ?? 'assets/images/top_banner.jpg',
      buttonText: json['button_text'] as String? ?? 'KNOW MORE →',
      targetTabIndex: json['target_tab_index'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tagline': tagline,
      'title': title,
      'subtitle': subtitle,
      'brand_badge': brandBadge,
      'image_url': imageUrl,
      'button_text': buttonText,
      'target_tab_index': targetTabIndex,
    };
  }
}

/// Model representing a Live Tournament Stream Card
class LiveStreamCardItem {
  final String id;
  final String title;
  final String subtitle;
  final String location;
  final String viewerCount;
  final bool isLive;
  final bool isOfficial;
  final String imageUrl;
  final String streamUrl;
  final String ctaText;

  const LiveStreamCardItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.location,
    required this.viewerCount,
    this.isLive = true,
    this.isOfficial = true,
    required this.imageUrl,
    required this.streamUrl,
    this.ctaText = 'Watch Now →',
  });

  factory LiveStreamCardItem.fromJson(Map<String, dynamic> json) {
    return LiveStreamCardItem(
      id: json['id'] as String? ?? 'stream_1',
      title: json['title'] as String? ?? 'BLASTIX ARENA PRO SERIES 2026',
      subtitle: json['subtitle'] as String? ?? 'Grand Finals – Day 2',
      location: json['location'] as String? ?? 'New Delhi, India',
      viewerCount: json['viewer_count'] as String? ?? '12.4K',
      isLive: json['is_live'] as bool? ?? true,
      isOfficial: json['is_official'] as bool? ?? true,
      imageUrl: json['image_url'] as String? ?? 'assets/images/top_banner.jpg',
      streamUrl: json['stream_url'] as String? ?? '',
      ctaText: json['cta_text'] as String? ?? 'Watch Now →',
    );
  }
}

/// Model representing an Esports Brand Partner
class PartnerItem {
  final String id;
  final String name;
  final IconData? icon;
  final String? logoPath;
  final String? logoUrl;

  const PartnerItem({
    required this.id,
    required this.name,
    this.icon,
    this.logoPath,
    this.logoUrl,
  });

  factory PartnerItem.fromJson(Map<String, dynamic> json) {
    return PartnerItem(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      logoUrl: json['logo_url'] as String? ?? json['logo'] as String? ?? json['logoUrl'] as String?,
      logoPath: json['logo_path'] as String? ?? json['logoPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo_url': logoUrl,
      'logo_path': logoPath,
    };
  }
}

/// Model representing a Partner Inquiry Form Submission
class PartnerInquiry {
  final String brandName;
  final String contactName;
  final String email;
  final String phone;
  final String partnershipType;
  final String message;

  const PartnerInquiry({
    required this.brandName,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.partnershipType,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'brand_name': brandName,
      'contact_name': contactName,
      'email': email,
      'phone': phone,
      'partnership_type': partnershipType,
      'message': message,
      'submitted_at': DateTime.now().toIso8601String(),
    };
  }
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
