import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sync/real_time_sync_manager.dart';
import '../../live/data/models/tournament_model.dart';
import '../../live/providers/live_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../splash/providers/splash_providers.dart';
import '../data/models/home_data_models.dart';
import '../data/services/home_api_service.dart';

/// Provider for HomeApiService
final homeApiServiceProvider = Provider<HomeApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HomeApiService(apiClient);
});

/// Provider for Featured BlastX Tournaments displayed on Home Screen
final homeFeaturedTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final liveTournaments = ref.watch(appLiveTournamentsProvider);
  final upcomingTournaments = ref.watch(appUpcomingTournamentsProvider);
  final allTournaments = ref.watch(appTournamentsProvider);

  if (liveTournaments.isNotEmpty || upcomingTournaments.isNotEmpty) {
    return [...liveTournaments, ...upcomingTournaments];
  }
  if (allTournaments.isNotEmpty) {
    return allTournaments;
  }
  final ffLive = ref.watch(officialTournamentsProvider);
  if (ffLive.isNotEmpty) {
    return ffLive;
  }
  return const [];
});

/// FutureProvider for dynamic promotional hero banners
/// Fetches real API data from GET /v1/admin/banners?page=1&limit=20 or GET /v1/home/banners.
final homeBannersProvider = FutureProvider<List<BannerItem>>((ref) async {
  final apiService = ref.watch(homeApiServiceProvider);
  final syncManager = ref.watch(realTimeSyncManagerProvider);

  const taskKey = 'home_banners';
  syncManager.register(
    key: taskKey,
    fetcher: () => apiService.getBanners(),
    onChanged: (_) {
      ref.invalidateSelf();
    },
  );
  ref.onDispose(() {
    syncManager.unregister(taskKey);
  });

  return await apiService.getBanners();
});

/// FutureProvider for Live Tournament Streams
/// Fetches real API data from GET /v1/home/live-streams or BlastX Live Tournaments.
final liveStreamsProvider = FutureProvider<List<LiveStreamCardItem>>((ref) async {
  final apiService = ref.watch(homeApiServiceProvider);
  final syncManager = ref.watch(realTimeSyncManagerProvider);

  const taskKey = 'home_live_streams';
  syncManager.register(
    key: taskKey,
    fetcher: () => apiService.getLiveStreams(),
    onChanged: (_) {
      ref.invalidateSelf();
    },
  );
  ref.onDispose(() {
    syncManager.unregister(taskKey);
  });

  final apiStreams = await apiService.getLiveStreams();
  if (apiStreams.isNotEmpty) {
    return apiStreams;
  }

  // Also check real BlastX Live tournaments from backend API
  final liveTournaments = ref.watch(appLiveTournamentsProvider);
  if (liveTournaments.isNotEmpty) {
    return liveTournaments.map((t) => LiveStreamCardItem(
      id: t.id,
      title: t.name,
      subtitle: t.organizer.isNotEmpty ? 'By ${t.organizer}' : t.game,
      location: t.mapName.isNotEmpty ? t.mapName : 'Online Tournament',
      viewerCount: t.viewersCount > 0 ? '${t.viewersCount}' : '0',
      isLive: t.isLive,
      isOfficial: true,
      imageUrl: t.bannerImageUrl.isNotEmpty ? t.bannerImageUrl : 'assets/images/top_banner.jpg',
      streamUrl: t.streamUrl ?? '',
      ctaText: 'Watch Now →',
    )).toList();
  }

  return const [];
});

/// FutureProvider for Brand Partners
/// Fetches real API data from GET /v1/home/partners.
final partnersProvider = FutureProvider<List<PartnerItem>>((ref) async {
  final apiService = ref.watch(homeApiServiceProvider);
  final syncManager = ref.watch(realTimeSyncManagerProvider);

  const taskKey = 'home_partners';
  syncManager.register(
    key: taskKey,
    fetcher: () => apiService.getPartners(),
    onChanged: (_) {
      ref.invalidateSelf();
    },
  );
  ref.onDispose(() {
    syncManager.unregister(taskKey);
  });

  return await apiService.getPartners();
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
