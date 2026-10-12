class RecordingJobModel {
  final String clientRecordingId;
  final String tournamentId;
  final String matchKey;
  final String filePath;
  final int sizeBytes;
  final int durationSeconds;
  final String startedAt;
  final String stoppedAt;
  final String? recordingId;
  final String? sessionUrl;
  final int chunkSizeBytes;
  final String? expiresAt;
  final int uploadedOffset;
  final int attempts;
  final String status; // 'pending', 'registering', 'uploading', 'completed', 'failed', 'paused'
  final String? lastErrorMessage;
  final String createdAt;
  final String resolution;

  RecordingJobModel({
    required this.clientRecordingId,
    required this.tournamentId,
    required this.matchKey,
    required this.filePath,
    required this.sizeBytes,
    required this.durationSeconds,
    required this.startedAt,
    required this.stoppedAt,
    this.recordingId,
    this.sessionUrl,
    this.chunkSizeBytes = 262144, // 256 KB
    this.expiresAt,
    this.uploadedOffset = 0,
    this.attempts = 0,
    this.status = 'pending',
    this.lastErrorMessage,
    String? createdAt,
    this.resolution = '1280x720',
  }) : createdAt = createdAt ?? DateTime.now().toUtc().toIso8601String();

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isSessionExpired {
    if (expiresAt == null) return true;
    try {
      final exp = DateTime.parse(expiresAt!);
      return DateTime.now().toUtc().isAfter(exp);
    } catch (_) {
      return true;
    }
  }

  RecordingJobModel copyWith({
    String? clientRecordingId,
    String? tournamentId,
    String? matchKey,
    String? filePath,
    int? sizeBytes,
    int? durationSeconds,
    String? startedAt,
    String? stoppedAt,
    String? recordingId,
    String? sessionUrl,
    int? chunkSizeBytes,
    String? expiresAt,
    int? uploadedOffset,
    int? attempts,
    String? status,
    String? lastErrorMessage,
    String? createdAt,
    String? resolution,
  }) {
    return RecordingJobModel(
      clientRecordingId: clientRecordingId ?? this.clientRecordingId,
      tournamentId: tournamentId ?? this.tournamentId,
      matchKey: matchKey ?? this.matchKey,
      filePath: filePath ?? this.filePath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      startedAt: startedAt ?? this.startedAt,
      stoppedAt: stoppedAt ?? this.stoppedAt,
      recordingId: recordingId ?? this.recordingId,
      sessionUrl: sessionUrl ?? this.sessionUrl,
      chunkSizeBytes: chunkSizeBytes ?? this.chunkSizeBytes,
      expiresAt: expiresAt ?? this.expiresAt,
      uploadedOffset: uploadedOffset ?? this.uploadedOffset,
      attempts: attempts ?? this.attempts,
      status: status ?? this.status,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
      createdAt: createdAt ?? this.createdAt,
      resolution: resolution ?? this.resolution,
    );
  }

  factory RecordingJobModel.fromJson(Map<String, dynamic> json) {
    return RecordingJobModel(
      clientRecordingId: json['client_recording_id'] as String? ?? '',
      tournamentId: json['tournament_id'] as String? ?? '',
      matchKey: json['match_key'] as String? ?? '',
      filePath: json['file_path'] as String? ?? '',
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      startedAt: json['started_at'] as String? ?? '',
      stoppedAt: json['stopped_at'] as String? ?? '',
      recordingId: json['recording_id'] as String?,
      sessionUrl: json['session_url'] as String?,
      chunkSizeBytes: (json['chunk_size_bytes'] as num?)?.toInt() ?? 262144,
      expiresAt: json['expires_at'] as String?,
      uploadedOffset: (json['uploaded_offset'] as num?)?.toInt() ?? 0,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
      lastErrorMessage: json['last_error_message'] as String?,
      createdAt: json['created_at'] as String?,
      resolution: json['resolution'] as String? ?? '1280x720',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_recording_id': clientRecordingId,
      'tournament_id': tournamentId,
      'match_key': matchKey,
      'file_path': filePath,
      'size_bytes': sizeBytes,
      'duration_seconds': durationSeconds,
      'started_at': startedAt,
      'stopped_at': stoppedAt,
      'recording_id': recordingId,
      'session_url': sessionUrl,
      'chunk_size_bytes': chunkSizeBytes,
      'expires_at': expiresAt,
      'uploaded_offset': uploadedOffset,
      'attempts': attempts,
      'status': status,
      'last_error_message': lastErrorMessage,
      'created_at': createdAt,
      'resolution': resolution,
    };
  }
}
