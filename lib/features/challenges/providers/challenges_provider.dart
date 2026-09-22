import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/challenge_model.dart';

final challengesProvider = StateProvider<List<ChallengeModel>>((ref) {
  return [
    ChallengeModel(
      id: 'c1',
      title: 'First Blood',
      description: 'Get 5 kills in Battle Royale mode.',
      rewardXP: 100,
      currentProgress: 3,
      targetProgress: 5,
      iconAsset: 'assets/icons/kill.png',
    ),
    ChallengeModel(
      id: 'c2',
      title: 'Booyah Hunter',
      description: 'Win 1 match in any mode.',
      rewardXP: 500,
      currentProgress: 1,
      targetProgress: 1,
      isCompleted: true,
      iconAsset: 'assets/icons/trophy.png',
    ),
    ChallengeModel(
      id: 'c3',
      title: 'Headshot Master',
      description: 'Eliminate 3 enemies with headshots.',
      rewardXP: 250,
      currentProgress: 1,
      targetProgress: 3,
      iconAsset: 'assets/icons/target.png',
    ),
    ChallengeModel(
      id: 'c4',
      title: 'Survival Instinct',
      description: 'Survive for more than 15 minutes in a single match.',
      rewardXP: 150,
      currentProgress: 0,
      targetProgress: 1,
      iconAsset: 'assets/icons/shield.png',
    ),
    ChallengeModel(
      id: 'c5',
      title: 'Squad Support',
      description: 'Revive teammates 3 times.',
      rewardXP: 200,
      currentProgress: 2,
      targetProgress: 3,
      iconAsset: 'assets/icons/heart.png',
    ),
  ];
});

final dailyProgressProvider = Provider<double>((ref) {
  final challenges = ref.watch(challengesProvider);
  if (challenges.isEmpty) return 0;
  final completed = challenges.where((c) => c.isCompleted).length;
  return completed / challenges.length;
});

final claimChallengeProvider = Provider((ref) {
  return (String id) {
    final notifier = ref.read(challengesProvider.notifier);
    notifier.state = [
      for (final challenge in notifier.state)
        if (challenge.id == id)
          challenge.copyWith(isClaimed: true)
        else
          challenge
    ];
  };
});
