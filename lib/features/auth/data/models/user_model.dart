class UserModel {
  final String id;
  final String? name;
  final String email;
  final String? profilePic;
  final String? token;
  final bool needsProfileSetup;

  UserModel({
    required this.id,
    this.name,
    required this.email,
    this.profilePic,
    this.token,
    this.needsProfileSetup = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final bool rawNeedsSetup = (json['needs_profile_setup'] ?? json['needsProfileSetup'] as bool?) ?? false;
    final String? phone = json['phone'] as String?;
    final bool phoneEmpty = phone == null || phone.trim().isEmpty;

    return UserModel(
      id: json['id'] ?? '',
      name: json['name'],
      email: json['email'] ?? '',
      profilePic: json['profile_pic'],
      token: json['token'],
      needsProfileSetup: rawNeedsSetup || phoneEmpty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_pic': profilePic,
      'token': token,
      'needs_profile_setup': needsProfileSetup,
    };
  }
}
