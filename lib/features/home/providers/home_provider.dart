import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/providers/profile_provider.dart';
import '../../splash/providers/splash_providers.dart';
import '../data/models/home_data_models.dart';
import '../data/services/home_api_service.dart';

/// Provider for HomeApiService
final homeApiServiceProvider = Provider<HomeApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HomeApiService(apiClient);
});

const _defaultBanners = [
  BannerItem(
    id: 'banner_bgc_2026',
    tagline: 'BHADRAK GAMING CHAMPIONSHIP',
    title: 'BGC 2026',
    subtitle: 'BIGGER SQUADS. BIGGER BATTLES. BHADRAK PRIDE.',
    brandBadge: 'GAME COMMUNITY CULTURE',
    imageUrl: 'assets/images/top_banner.jpg',
    buttonText: 'KNOW MORE →',
    targetTabIndex: 1, // Tournaments
  ),
  BannerItem(
    id: 'banner_pro_series',
    tagline: 'OFFICIAL TOURNAMENT SERIES',
    title: 'PRO SERIES S4',
    subtitle: '₹1,00,000 PRIZE POOL • FREE FIRE SQUAD',
    brandBadge: 'BLASTIX ARENA',
    imageUrl: 'assets/images/top_banner.jpg',
    buttonText: 'REGISTER NOW →',
    targetTabIndex: 1, // Tournaments
  ),
];

const _defaultLiveStreams = [
  LiveStreamCardItem(
    id: 'live_pro_series_2026',
    title: 'PRO SERIES 2026',
    subtitle: 'Grand Finals – Day 2',
    location: 'New Delhi, India',
    viewerCount: '12.4K',
    isLive: true,
    isOfficial: true,
    imageUrl: 'assets/images/top_banner.jpg',
    streamUrl: 'https://youtube.com/live',
    ctaText: 'Watch Now →',
  ),
  LiveStreamCardItem(
    id: 'live_weekly_cup',
    title: 'WEEKLY CUP S12',
    subtitle: 'Quarter Finals • Map: Bermuda',
    location: 'Online Tournament',
    viewerCount: '8.1K',
    isLive: true,
    isOfficial: true,
    imageUrl: 'assets/images/top_banner.jpg',
    streamUrl: 'https://youtube.com/live',
    ctaText: 'Watch Now →',
  ),
];

/// FutureProvider for dynamic promotional hero banners
/// Fetches real API data from GET /v1/home/banners with safe fallback
final homeBannersProvider = FutureProvider<List<BannerItem>>((ref) async {
  final apiService = ref.watch(homeApiServiceProvider);
  final apiBanners = await apiService.getBanners();
  if (apiBanners.isNotEmpty) {
    return apiBanners;
  }
  return _defaultBanners;
});

/// FutureProvider for Live Tournament Streams
/// Fetches real API data from GET /v1/home/live-streams with safe fallback
final liveStreamsProvider = FutureProvider<List<LiveStreamCardItem>>((ref) async {
  final apiService = ref.watch(homeApiServiceProvider);
  final apiStreams = await apiService.getLiveStreams();
  if (apiStreams.isNotEmpty) {
    return apiStreams;
  }
  return _defaultLiveStreams;
});

/// Provider for Brand Partners
final partnersProvider = Provider<List<PartnerItem>>((ref) {
  return const [
    PartnerItem(id: 'redbull', name: 'Red Bull', icon: Icons.sports_kabaddi_rounded),
    PartnerItem(id: 'intel', name: 'Intel', icon: Icons.memory_rounded),
    PartnerItem(id: 'logitech', name: 'Logitech G', icon: Icons.mouse_rounded),
    PartnerItem(id: 'zowie', name: 'ZOWIE', icon: Icons.desktop_windows_rounded),
    PartnerItem(id: 'discord', name: 'Discord', icon: Icons.forum_rounded),
  ];
});

/// Provider for Live Announcements
final homeAnnouncementsProvider = Provider<List<AnnouncementItem>>((ref) {
  return [
    AnnouncementItem(
      id: 'ann_1',
      message: 'BGC 2026 Registration Open! Squad up and win ₹50,000.',
      tag: 'FEATURED',
      timestamp: DateTime.now(),
    ),
    AnnouncementItem(
      id: 'ann_2',
      message: 'Match recording upload is live. Submit 480p match videos for proof.',
      tag: 'SYSTEM',
      timestamp: DateTime.now(),
    ),
  ];
});

/// Provider for Notice Board Items
final homeNoticesProvider = Provider<List<NoticeItem>>((ref) {
  return [
    NoticeItem(
      id: 'not_1',
      title: 'Free Fire Anti-Cheat Protocol Update',
      description: 'All players must record full match gameplay during BGC 2026 matches.',
      category: 'RULES',
      date: DateTime.now(),
      icon: Icons.shield_rounded,
      isImportant: true,
    ),
    NoticeItem(
      id: 'not_2',
      title: 'Weekly Rewards Payout Complete',
      description: 'XP and wallet credits for week 40 have been distributed to team captains.',
      category: 'REWARDS',
      date: DateTime.now(),
      icon: Icons.payments_rounded,
    ),
  ];
});

/// Provider for User Stats
final userHomeStatsProvider = Provider<UserHomeStats>((ref) {
  final profileState = ref.watch(profileProvider);
  final user = profileState.user;
  return UserHomeStats(
    xp: user?.xp ?? 0,
    rank: user?.rank ?? 0,
    matchesPlayed: user?.tournamentsPlayed ?? 0,
    totalWins: user?.tournamentsWon ?? 0,
  );
});

/// StateNotifier to handle partner inquiry submission
class PartnerInquiryNotifier extends StateNotifier<AsyncValue<void>> {
  PartnerInquiryNotifier(this._apiService) : super(const AsyncValue.data(null));

  final HomeApiService _apiService;

  Future<bool> submitInquiry(PartnerInquiry inquiry) async {
    state = const AsyncValue.loading();
    try {
      final success = await _apiService.submitPartnerInquiry(inquiry);
      state = const AsyncValue.data(null);
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final partnerInquiryProvider =
    StateNotifierProvider<PartnerInquiryNotifier, AsyncValue<void>>((ref) {
  final apiService = ref.watch(homeApiServiceProvider);
  return PartnerInquiryNotifier(apiService);
});
