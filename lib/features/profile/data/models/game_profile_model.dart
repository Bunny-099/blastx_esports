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
      id: json['id'] as String? ?? '',
      gameSlug: json['game_slug'] as String? ?? 'free_fire',
      gameName: json['game_name'] as String? ?? 'Free Fire',
      inGameUid: (json['in_game_uid'] ?? json['uid'] ?? '') as String,
      inGameName: (json['in_game_name'] ?? json['ign'] ?? '') as String,
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
