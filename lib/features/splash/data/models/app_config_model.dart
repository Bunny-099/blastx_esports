class AppConfigModel {
  final String minVersion;
  final String latestVersion;
  final bool isMaintenance;
  final String? maintenanceMessage;
  final String? updateUrl;

  AppConfigModel({
    required this.minVersion,
    required this.latestVersion,
    required this.isMaintenance,
    this.maintenanceMessage,
    this.updateUrl,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel(
      minVersion: json['min_version'] ?? '1.0.0',
      latestVersion: json['latest_version'] ?? '1.0.0',
      isMaintenance: json['is_maintenance'] ?? false,
      maintenanceMessage: json['maintenance_message'],
      updateUrl: json['update_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min_version': minVersion,
      'latest_version': latestVersion,
      'is_maintenance': isMaintenance,
      'maintenance_message': maintenanceMessage,
      'update_url': updateUrl,
    };
  }
}
