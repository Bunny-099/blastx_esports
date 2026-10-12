class RecordingConfigModel {
  final int videoBitrateKbps;
  final int maxHeight;
  final int fps;
  final int maxDurationMinutes;
  final int minFreeSpaceMb;

  const RecordingConfigModel({
    this.videoBitrateKbps = 2500,
    this.maxHeight = 720,
    this.fps = 30,
    this.maxDurationMinutes = 60,
    this.minFreeSpaceMb = 1500,
  });

  factory RecordingConfigModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RecordingConfigModel();
    return RecordingConfigModel(
      videoBitrateKbps: (json['video_bitrate_kbps'] as num?)?.toInt() ?? 2500,
      maxHeight: (json['max_height'] as num?)?.toInt() ?? 720,
      fps: (json['fps'] as num?)?.toInt() ?? 30,
      maxDurationMinutes: (json['max_duration_minutes'] as num?)?.toInt() ?? 60,
      minFreeSpaceMb: (json['min_free_space_mb'] as num?)?.toInt() ?? 1500,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'video_bitrate_kbps': videoBitrateKbps,
      'max_height': maxHeight,
      'fps': fps,
      'max_duration_minutes': maxDurationMinutes,
      'min_free_space_mb': minFreeSpaceMb,
    };
  }
}

class AppConfigModel {
  final String minVersion;
  final String latestVersion;
  final bool isMaintenance;
  final String? maintenanceMessage;
  final String? updateUrl;
  final RecordingConfigModel recording;

  AppConfigModel({
    required this.minVersion,
    required this.latestVersion,
    required this.isMaintenance,
    this.maintenanceMessage,
    this.updateUrl,
    this.recording = const RecordingConfigModel(),
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel(
      minVersion: json['min_version'] ?? '1.0.0',
      latestVersion: json['latest_version'] ?? '1.0.0',
      isMaintenance: json['is_maintenance'] ?? false,
      maintenanceMessage: json['maintenance_message'],
      updateUrl: json['update_url'],
      recording: RecordingConfigModel.fromJson(
        json['recording'] is Map<String, dynamic> ? json['recording'] as Map<String, dynamic> : null,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min_version': minVersion,
      'latest_version': latestVersion,
      'is_maintenance': isMaintenance,
      'maintenance_message': maintenanceMessage,
      'update_url': updateUrl,
      'recording': recording.toJson(),
    };
  }
}
