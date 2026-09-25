class GameProfileModel {
  final String id;
  final String gameSlug;
  final String gameName;
  final String inGameUid;
  final String inGameName;

  const GameProfileModel({
    this.id = '',
    this.gameSlug = 'free_fire',
    this.gameName = 'Free Fire',
    required this.inGameUid,
    required this.inGameName,
  });

  factory GameProfileModel.fromJson(Map<String, dynamic> json) {
    return GameProfileModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      gameSlug: json['game_slug'] as String? ?? json['gameSlug'] as String? ?? 'free_fire',
      gameName: json['game_name'] as String? ?? json['gameName'] as String? ?? 'Free Fire',
      inGameUid: (json['in_game_uid'] ?? json['inGameUid'] ?? json['uid'] ?? '')?.toString() ?? '',
      inGameName: (json['in_game_name'] ?? json['inGameName'] ?? json['ign'] ?? '')?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'game_slug': gameSlug,
      'in_game_uid': inGameUid,
      'in_game_name': inGameName,
    };
  }
}
