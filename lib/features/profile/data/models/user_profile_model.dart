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

  const UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePic,
    this.role = 'USER',
    this.isActive = true,
    this.createdAt,
    this.gameProfile,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profilePic: json['profile_pic'] as String?,
      role: json['role'] as String? ?? 'USER',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      gameProfile: json['game_profile'] != null
          ? GameProfileModel.fromJson(json['game_profile'] as Map<String, dynamic>)
          : null,
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
    };
  }

  UserProfileModel copyWith({
    String? name,
    String? profilePic,
    GameProfileModel? gameProfile,
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
    );
  }
}
