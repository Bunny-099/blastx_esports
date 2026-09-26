import 'game_profile_model.dart';

class UserProfileModel {
  final String id;
  final String name;
  final String email;
  final String? profilePic;
  final String role;
  final bool isActive;
  final DateTime? createdAt;
  final GameProfileModel? gameProfile;
  final int tournamentsPlayed;
  final int tournamentsWon;
  final int totalKills;
  final String winRate;
  final int xp;
  final int rank;

  const UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePic,
    this.role = 'USER',
    this.isActive = true,
    this.createdAt,
    this.gameProfile,
    this.tournamentsPlayed = 0,
    this.tournamentsWon = 0,
    this.totalKills = 0,
    this.winRate = '0%',
    this.xp = 0,
    this.rank = 0,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final tPlayed = (json['tournaments_played'] ??
            json['tournamentsPlayed'] ??
            json['matches_played'] ??
            json['matchesPlayed'] as num?)
        ?.toInt() ?? 0;
    final tWon = (json['tournaments_won'] ??
            json['tournamentsWon'] ??
            json['wins'] ??
            json['total_wins'] ??
            json['totalWins'] as num?)
        ?.toInt() ?? 0;
    final kills = (json['total_kills'] ??
            json['totalKills'] ??
            json['kills'] as num?)
        ?.toInt() ?? 0;
    final wRate = json['win_rate']?.toString() ??
        json['winRate']?.toString() ??
        '${(tPlayed > 0 ? (tWon / tPlayed * 100).toStringAsFixed(1) : '0')}%';
    final userXp = (json['xp'] as num?)?.toInt() ?? 0;
    final userRank = (json['rank'] as num?)?.toInt() ?? 0;

    return UserProfileModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profilePic: json['profile_pic'] as String? ??
          json['profilePic'] as String? ??
          json['avatar'] as String?,
      role: json['role'] as String? ?? 'USER',
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString())
              : null),
      gameProfile: json['game_profile'] != null
          ? GameProfileModel.fromJson(
              Map<String, dynamic>.from(json['game_profile'] as Map))
          : (json['gameProfile'] != null
              ? GameProfileModel.fromJson(
                  Map<String, dynamic>.from(json['gameProfile'] as Map))
              : null),
      tournamentsPlayed: tPlayed,
      tournamentsWon: tWon,
      totalKills: kills,
      winRate: wRate,
      xp: userXp,
      rank: userRank,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_pic': profilePic,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      if (gameProfile != null) 'game_profile': gameProfile!.toJson(),
      'tournaments_played': tournamentsPlayed,
      'tournaments_won': tournamentsWon,
      'total_kills': totalKills,
      'win_rate': winRate,
      'xp': xp,
      'rank': rank,
    };
  }

  UserProfileModel copyWith({
    String? name,
    String? profilePic,
    GameProfileModel? gameProfile,
    int? tournamentsPlayed,
    int? tournamentsWon,
    int? totalKills,
    String? winRate,
    int? xp,
    int? rank,
  }) {
    return UserProfileModel(
      id: id,
      name: name ?? this.name,
      email: email,
      profilePic: profilePic ?? this.profilePic,
      role: role,
      isActive: isActive,
      createdAt: createdAt,
      gameProfile: gameProfile ?? this.gameProfile,
      tournamentsPlayed: tournamentsPlayed ?? this.tournamentsPlayed,
      tournamentsWon: tournamentsWon ?? this.tournamentsWon,
      totalKills: totalKills ?? this.totalKills,
      winRate: winRate ?? this.winRate,
      xp: xp ?? this.xp,
      rank: rank ?? this.rank,
    );
  }
}
