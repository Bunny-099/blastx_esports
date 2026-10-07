/// Model representing an Issue Report submission payload.
class ReportIssueRequest {
  final String issueType;
  final String description;
  final String? tournamentName;
  final String? deviceModel;
  final String? appVersion;
  final String? osVersion;
  final String? deviceType;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? freeFireUid;
  final String? inGameName;

  const ReportIssueRequest({
    required this.issueType,
    required this.description,
    this.tournamentName,
    this.deviceModel,
    this.appVersion,
    this.osVersion,
    this.deviceType,
    this.userId,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.freeFireUid,
    this.inGameName,
  });

  Map<String, dynamic> toJson() {
    return {
      'issue_type': issueType,
      'description': description,
      if (tournamentName != null && tournamentName!.isNotEmpty)
        'tournament_name': tournamentName,
      'device_model': deviceModel ?? 'Unknown Device',
      'app_version': appVersion ?? '1.0.0',
      'os_version': osVersion ?? 'Unknown OS',
      'device_type': deviceType ?? 'UNKNOWN',
      'user_id': userId ?? '',
      'user_name': userName ?? '',
      'user_email': userEmail ?? '',
      if (userPhone != null && userPhone!.isNotEmpty) 'user_phone': userPhone,
      if (freeFireUid != null && freeFireUid!.isNotEmpty)
        'free_fire_uid': freeFireUid,
      if (inGameName != null && inGameName!.isNotEmpty)
        'in_game_name': inGameName,
      'submitted_at': DateTime.now().toIso8601String(),
    };
  }

  factory ReportIssueRequest.fromJson(Map<String, dynamic> json) {
    return ReportIssueRequest(
      issueType: json['issue_type']?.toString() ?? 'Other',
      description: json['description']?.toString() ?? '',
      tournamentName: json['tournament_name']?.toString(),
      deviceModel: json['device_model']?.toString(),
      appVersion: json['app_version']?.toString(),
      osVersion: json['os_version']?.toString(),
      deviceType: json['device_type']?.toString(),
      userId: json['user_id']?.toString(),
      userName: json['user_name']?.toString(),
      userEmail: json['user_email']?.toString(),
      userPhone: json['user_phone']?.toString(),
      freeFireUid: json['free_fire_uid']?.toString(),
      inGameName: json['in_game_name']?.toString(),
    );
  }
}

/// Model representing a Contact Support ticket request payload.
class ContactSupportRequest {
  final String subject;
  final String category;
  final String message;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? freeFireUid;
  final String? inGameName;
  final String? deviceModel;
  final String? appVersion;
  final String? osVersion;
  final String? deviceType;

  const ContactSupportRequest({
    required this.subject,
    required this.category,
    required this.message,
    this.userId,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.freeFireUid,
    this.inGameName,
    this.deviceModel,
    this.appVersion,
    this.osVersion,
    this.deviceType,
  });

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'category': category,
      'message': message,
      'user_id': userId ?? '',
      'user_name': userName ?? '',
      'user_email': userEmail ?? '',
      if (userPhone != null && userPhone!.isNotEmpty) 'user_phone': userPhone,
      if (freeFireUid != null && freeFireUid!.isNotEmpty)
        'free_fire_uid': freeFireUid,
      if (inGameName != null && inGameName!.isNotEmpty)
        'in_game_name': inGameName,
      'device_model': deviceModel ?? 'Unknown Device',
      'app_version': appVersion ?? '1.0.0',
      'os_version': osVersion ?? 'Unknown OS',
      'device_type': deviceType ?? 'UNKNOWN',
      'submitted_at': DateTime.now().toIso8601String(),
    };
  }

  factory ContactSupportRequest.fromJson(Map<String, dynamic> json) {
    return ContactSupportRequest(
      subject: json['subject']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General Query',
      message: json['message']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      userName: json['user_name']?.toString(),
      userEmail: json['user_email']?.toString(),
      userPhone: json['user_phone']?.toString(),
      freeFireUid: json['free_fire_uid']?.toString(),
      inGameName: json['in_game_name']?.toString(),
      deviceModel: json['device_model']?.toString(),
      appVersion: json['app_version']?.toString(),
      osVersion: json['os_version']?.toString(),
      deviceType: json['device_type']?.toString(),
    );
  }
}
