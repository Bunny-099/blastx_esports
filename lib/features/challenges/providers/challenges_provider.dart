import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../data/models/challenge_model.dart';
import '../data/repositories/challenges_repository.dart';
import '../data/services/challenges_api_service.dart';
import '../data/services/game_launcher_service.dart';
import '../data/services/screen_recording_service.dart';

// Services & Repository Providers
final challengesApiServiceProvider = Provider<ChallengesApiService>((ref) {
  final apiClient = ApiClient(StorageService());
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

  Future<void> claimReward(String id) async {
    try {
      await _repository.claimChallenge(id);
    } catch (e) {
      print('Claim API warning, applying local state update: $e');
    }
    state = [
      for (final challenge in state)
        if (challenge.id == id)
          challenge.copyWith(isClaimed: true, isCompleted: true, status: 'CLAIMED')
        else
          challenge
    ];
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
  return (String id) {
    ref.read(challengesProvider.notifier).claimReward(id);
  };
});
