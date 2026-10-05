import '../../domain/rank_system.dart';
import 'game_profile_model.dart';
import 'rank_model.dart';

class UserProfileModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profilePic;
  final String role;
  final bool isActive;
  final bool isVip;
  final bool crownBadgeUnlocked;
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
    this.phone,
    this.profilePic,
    this.role = 'USER',
    this.isActive = true,
    this.isVip = false,
    this.crownBadgeUnlocked = false,
    this.createdAt,
    this.gameProfile,
    this.tournamentsPlayed = 0,
    this.tournamentsWon = 0,
    this.totalKills = 0,
    this.winRate = '0%',
    this.xp = 0,
    this.rank = 1,
  });

  /// Computed rank progress and metrics from total XP
  RankProgressInfo get rankInfo => RankSystem.getRankProgress(xp);

  /// Current rank tier derived from RankSystem
  RankTier get currentRankTier => RankSystem.getRankFromXP(xp);

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
    final calculatedRank = RankSystem.getRankFromXP(userXp).number;
    final parsedRank = (json['rank'] as num?)?.toInt();
    final userRank = (parsedRank != null && parsedRank > 0) ? parsedRank : calculatedRank;

    final parsedIsVip = (json['is_vip'] as bool?) ?? (json['isVip'] as bool?) ?? false;
    final parsedCrownBadge = (json['crown_badge_unlocked'] as bool?) ?? (json['crownBadgeUnlocked'] as bool?) ?? false;

    return UserProfileModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ??
          json['phone_number'] as String? ??
          json['phoneNumber'] as String?,
      profilePic: json['profile_pic'] as String? ??
          json['profilePic'] as String? ??
          json['avatar'] as String?,
      role: json['role'] as String? ?? 'USER',
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      isVip: parsedIsVip,
      crownBadgeUnlocked: parsedCrownBadge,
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
      'phone': phone,
      'profile_pic': profilePic,
      'role': role,
      'is_active': isActive,
      'is_vip': isVip,
      'crown_badge_unlocked': crownBadgeUnlocked,
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
    String? phone,
    String? profilePic,
    bool? isVip,
    bool? crownBadgeUnlocked,
    GameProfileModel? gameProfile,
    int? tournamentsPlayed,
    int? tournamentsWon,
    int? totalKills,
    String? winRate,
    int? xp,
    int? rank,
  }) {
    final nextXp = xp ?? this.xp;
    final nextRankNumber = rank ?? (xp != null ? RankSystem.getRankFromXP(nextXp).number : this.rank);

    return UserProfileModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      profilePic: profilePic ?? this.profilePic,
      role: role,
      isActive: isActive,
      isVip: isVip ?? this.isVip,
      crownBadgeUnlocked: crownBadgeUnlocked ?? this.crownBadgeUnlocked,
      createdAt: createdAt,
      gameProfile: gameProfile ?? this.gameProfile,
      tournamentsPlayed: tournamentsPlayed ?? this.tournamentsPlayed,
      tournamentsWon: tournamentsWon ?? this.tournamentsWon,
      totalKills: totalKills ?? this.totalKills,
      winRate: winRate ?? this.winRate,
      xp: nextXp,
      rank: nextRankNumber,
    );
  }
}
