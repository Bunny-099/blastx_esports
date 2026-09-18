import 'package:flutter/material.dart';

enum ChallengeType {
  daily,
  weekly,
  special
}

class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final int rewardCoins;
  final double currentProgress;
  final double targetProgress;
  final String game;
  final ChallengeType type;
  final bool isCompleted;
  final bool isClaimed;
  final String iconAsset;

  ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardCoins,
    required this.currentProgress,
    required this.targetProgress,
    this.game = 'Free Fire',
    this.type = ChallengeType.daily,
    this.isCompleted = false,
    this.isClaimed = false,
    this.iconAsset = '',
  });

  double get progressPercentage => (currentProgress / targetProgress).clamp(0.0, 1.0);

  ChallengeModel copyWith({
    String? id,
    String? title,
    String? description,
    int? rewardCoins,
    double? currentProgress,
    double? targetProgress,
    String? game,
    ChallengeType? type,
    bool? isCompleted,
    bool? isClaimed,
    String? iconAsset,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      rewardCoins: rewardCoins ?? this.rewardCoins,
      currentProgress: currentProgress ?? this.currentProgress,
      targetProgress: targetProgress ?? this.targetProgress,
      game: game ?? this.game,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      isClaimed: isClaimed ?? this.isClaimed,
      iconAsset: iconAsset ?? this.iconAsset,
    );
  }
}
