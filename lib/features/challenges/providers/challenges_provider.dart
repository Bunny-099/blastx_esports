import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/data/models/rank_model.dart';
import '../../profile/providers/profile_provider.dart';
import '../../splash/providers/splash_providers.dart';
import '../data/models/challenge_model.dart';
import '../data/repositories/challenges_repository.dart';
import '../data/services/challenges_api_service.dart';
import '../data/services/game_launcher_service.dart';
import '../data/services/screen_recording_service.dart';

// Services & Repository Providers
final challengesApiServiceProvider = Provider<ChallengesApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChallengesApiService(apiClient);
});

final challengesRepositoryProvider = Provider<ChallengesRepository>((ref) {
  final apiService = ref.watch(challengesApiServiceProvider);
  return ChallengesRepository(apiService);
});

final gameLauncherServiceProvider = Provider<GameLauncherService>((ref) {
  return GameLauncherService();
});

final screenRecordingServiceProvider = Provider<ScreenRecordingService>((ref) {
  return ScreenRecordingService();
});

// Recording & Upload State Providers
final activeRecordingChallengeIdProvider = StateProvider<String?>((ref) => null);
final recordedVideoFileProvider = StateProvider<File?>((ref) => null);
final isUploadingProofProvider = StateProvider<bool>((ref) => false);
final activeFilterTypeProvider = StateProvider<ChallengeType?>((ref) => null);

// Main Challenges Notifier State
class ChallengesNotifier extends StateNotifier<List<ChallengeModel>> {
  final ChallengesRepository _repository;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  ChallengesNotifier(this._repository) : super([]) {
    loadChallenges();
  }

  Future<void> loadChallenges() async {
    _isLoading = true;
    try {
      final challenges = await _repository.getChallenges();
      state = challenges;
    } catch (e) {
      print('Error loading challenges: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// Claims reward for a completed challenge and updates total XP in Profile.
  /// Prevents duplicate claims if already claimed or if proof review is not approved yet.
  Future<RankChangeResult?> claimReward(String id, {WidgetRef? ref, Ref? containerRef}) async {
    final index = state.indexWhere((c) => c.id == id);
    if (index == -1) return null;

    final challenge = state[index];

    // CRITICAL: Prevent duplicate XP claim or claiming before admin approval / if rejected
    if (challenge.isClaimed || !challenge.isReadyToClaim) {
      return null;
    }

    try {
      await _repository.claimChallenge(id);
    } catch (e) {
      print('Claim API warning, applying local state update: $e');
    }

    // Mark challenge as claimed locally
    state = [
      for (final c in state)
        if (c.id == id)
          c.copyWith(isClaimed: true, isCompleted: true, status: 'CLAIMED')
        else
          c
    ];

    // Award XP to user profile and return RankChangeResult
    if (ref != null) {
      return await ref.read(profileProvider.notifier).addXP(challenge.rewardXP);
    } else if (containerRef != null) {
      return await containerRef.read(profileProvider.notifier).addXP(challenge.rewardXP);
    }
    return null;
  }

  void markProofSubmitted(String id) {
    state = [
      for (final challenge in state)
        if (challenge.id == id)
          challenge.copyWith(
            status: 'PROOF_SUBMITTED',
            isCompleted: true,
            currentProgress: challenge.targetProgress,
          )
        else
          challenge
    ];
  }

  void updateChallengeStatus(String id, String status) {
    state = [
      for (final challenge in state)
        if (challenge.id == id)
          challenge.copyWith(status: status)
        else
          challenge
    ];
  }
}

final challengesProvider =
    StateNotifierProvider<ChallengesNotifier, List<ChallengeModel>>((ref) {
  final repository = ref.watch(challengesRepositoryProvider);
  return ChallengesNotifier(repository);
});

final dailyProgressProvider = Provider<double>((ref) {
  final challenges = ref.watch(challengesProvider);
  if (challenges.isEmpty) return 0.0;
  final completed = challenges.where((c) => c.isCompleted || c.isClaimed).length;
  return (completed / challenges.length).clamp(0.0, 1.0);
});

final claimChallengeProvider = Provider((ref) {
  return (String id) async {
    return await ref.read(challengesProvider.notifier).claimReward(id, containerRef: ref);
  };
});
