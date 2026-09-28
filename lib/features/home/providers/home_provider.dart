import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/models/home_data_models.dart';

final homeBannersProvider = Provider<List<BannerItem>>((ref) {
  return const [];
});

final homeAnnouncementsProvider = Provider<List<AnnouncementItem>>((ref) {
  return const [];
});

final homeNoticesProvider = Provider<List<NoticeItem>>((ref) {
  return const [];
});

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
