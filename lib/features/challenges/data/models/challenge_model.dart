enum ChallengeType {
  daily,
  weekly,
  special
}

class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final int rewardXP;
  final double currentProgress;
  final double targetProgress;
  final String game;
  final ChallengeType type;
  final bool isCompleted;
  final bool isClaimed;
  final bool requiresRecording;
  final String gamePackage;
  final String iconAsset;
  final String status;

  ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardXP,
    required this.currentProgress,
    required this.targetProgress,
    this.game = 'Free Fire',
    this.type = ChallengeType.daily,
    this.isCompleted = false,
    this.isClaimed = false,
    this.requiresRecording = true,
    this.gamePackage = 'com.dts.freefireth',
    this.iconAsset = '',
    this.status = 'ACTIVE',
  });

  double get progressPercentage =>
      targetProgress > 0 ? (currentProgress / targetProgress).clamp(0.0, 1.0) : 0.0;

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    ChallengeType typeEnum = ChallengeType.daily;
    final typeStr = (json['type'] ?? 'DAILY').toString().toUpperCase();
    if (typeStr == 'WEEKLY') {
      typeEnum = ChallengeType.weekly;
    } else if (typeStr == 'SPECIAL') {
      typeEnum = ChallengeType.special;
    }

    final double current = (json['current_progress'] ?? json['currentProgress'] ?? 0).toDouble();
    final double target = (json['target_progress'] ?? json['targetProgress'] ?? 1).toDouble();
    final bool completed = (json['is_completed'] ?? json['isCompleted'] ?? (current >= target && target > 0));

    return ChallengeModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      rewardXP: (json['reward_xp'] ?? json['rewardXP'] ?? 0) as int,
      currentProgress: current,
      targetProgress: target,
      game: json['game']?.toString() ?? 'Free Fire',
      type: typeEnum,
      isCompleted: completed,
      isClaimed: json['is_claimed'] ?? json['isClaimed'] ?? false,
      requiresRecording: json['requires_recording'] ?? json['requiresRecording'] ?? true,
      gamePackage: json['game_package'] ?? json['gamePackage'] ?? 'com.dts.freefireth',
      iconAsset: json['icon_asset'] ?? json['icon_url'] ?? json['iconAsset'] ?? '',
      status: json['status']?.toString() ?? (completed ? 'COMPLETED' : 'ACTIVE'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'reward_xp': rewardXP,
      'current_progress': currentProgress,
      'target_progress': targetProgress,
      'game': game,
      'type': type.name.toUpperCase(),
      'is_completed': isCompleted,
      'is_claimed': isClaimed,
      'requires_recording': requiresRecording,
      'game_package': gamePackage,
      'icon_asset': iconAsset,
      'status': status,
    };
  }

  ChallengeModel copyWith({
    String? id,
    String? title,
    String? description,
    int? rewardXP,
    double? currentProgress,
    double? targetProgress,
    String? game,
    ChallengeType? type,
    bool? isCompleted,
    bool? isClaimed,
    bool? requiresRecording,
    String? gamePackage,
    String? iconAsset,
    String? status,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      rewardXP: rewardXP ?? this.rewardXP,
      currentProgress: currentProgress ?? this.currentProgress,
      targetProgress: targetProgress ?? this.targetProgress,
      game: game ?? this.game,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      isClaimed: isClaimed ?? this.isClaimed,
      requiresRecording: requiresRecording ?? this.requiresRecording,
      gamePackage: gamePackage ?? this.gamePackage,
      iconAsset: iconAsset ?? this.iconAsset,
      status: status ?? this.status,
    );
  }
}
