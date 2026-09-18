class UserModel {
  final String id;
  final String? name;
  final String email;
  final String? profilePic;
  final String? token;

  UserModel({
    required this.id,
    this.name,
    required this.email,
    this.profilePic,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'],
      email: json['email'] ?? '',
      profilePic: json['profile_pic'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_pic': profilePic,
      'token': token,
    };
  }
}
