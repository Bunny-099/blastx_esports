import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:blastix_esports/core/api/api_client.dart';
import 'package:blastix_esports/core/network/network_connectivity_observer.dart';
import 'package:blastix_esports/core/services/notification_service.dart';
import '../models/recording_job_model.dart';
import '../repositories/recording_jobs_repository.dart';

class ResumableUploaderService {
  final ApiClient _apiClient;
  final RecordingJobsRepository _repository;
  final NetworkConnectivityObserver _connectivityObserver;
  final Dio _uploadDio;

  final Map<String, bool> _activeUploads = {};
  StreamSubscription? _connectivitySubscription;

  ResumableUploaderService({
    required ApiClient apiClient,
    required RecordingJobsRepository repository,
    required NetworkConnectivityObserver connectivityObserver,
    Dio? uploadDio,
  })  : _apiClient = apiClient,
        _repository = repository,
        _connectivityObserver = connectivityObserver,
        _uploadDio = uploadDio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 30))) {
    _listenToConnectivity();
  }

  void _listenToConnectivity() {
    // Periodically check connectivity to resume pending upload jobs
    Timer.periodic(const Duration(seconds: 15), (_) async {
      if (await _connectivityObserver.checkConnectivity()) {
        resumeAllPendingJobs();
      }
    });
  }

  Future<void> resumeAllPendingJobs() async {
    final jobs = _repository.getAllJobs();
    for (final job in jobs) {
      if (job.status == 'pending' || job.status == 'uploading' || job.status == 'paused') {
        uploadJob(job);
      }
    }
  }

  Future<void> uploadJob(RecordingJobModel initialJob, {
    Function(int uploaded, int total)? onProgress,
    Function()? onCompleted,
    Function(String error)? onError,
  }) async {
    if (_activeUploads[initialJob.clientRecordingId] == true) {
      debugPrint('Upload already active for clientRecordingId: ${initialJob.clientRecordingId}');
      return;
    }

    _activeUploads[initialJob.clientRecordingId] = true;
    RecordingJobModel job = initialJob;

    try {
      // 1. Check Connectivity
      final isOnline = await _connectivityObserver.checkConnectivity();
      if (!isOnline) {
        debugPrint('Upload paused: device is offline.');
        job = job.copyWith(status: 'paused', lastErrorMessage: 'Waiting for internet connection.');
        await _repository.saveJob(job);
        onError?.call('Waiting for internet connection.');
        _activeUploads.remove(job.clientRecordingId);
        return;
      }

      final file = File(job.filePath);
      if (!await file.exists()) {
        debugPrint('Recording file not found on disk: ${job.filePath}');
        job = job.copyWith(status: 'failed', lastErrorMessage: 'Recording file missing on device.');
        await _repository.saveJob(job);
        onError?.call('Recording file missing on device.');
        _activeUploads.remove(job.clientRecordingId);
        return;
      }

      final int fileSize = await file.length();
      if (job.sizeBytes != fileSize) {
        job = job.copyWith(sizeBytes: fileSize);
        await _repository.saveJob(job);
      }

      // 2. Register / Fetch Session
      if (job.recordingId == null || job.sessionUrl == null || job.isSessionExpired) {
        job = await _registerOrRenewSession(job);
        if (job.status == 'completed') {
          // 409 RECORDING_ALREADY_UPLOADED
          await _deleteFile(file);
          onCompleted?.call();
          _activeUploads.remove(job.clientRecordingId);
          return;
        }
        if (job.status == 'failed') {
          onError?.call(job.lastErrorMessage ?? 'Session registration failed.');
          _activeUploads.remove(job.clientRecordingId);
          return;
        }
      }

      // 3. Query Upload Status on Session URL (Empty PUT with bytes */fileSize)
      int offset = await _querySessionOffset(job.sessionUrl!, fileSize);
      if (offset >= fileSize) {
        debugPrint('File already fully uploaded on Google Drive. Finalizing complete...');
        await _completeUpload(job);
        await _deleteFile(file);
        job = job.copyWith(status: 'completed', uploadedOffset: fileSize);
        await _repository.saveJob(job);
        onCompleted?.call();
        _activeUploads.remove(job.clientRecordingId);
        return;
      }

      job = job.copyWith(status: 'uploading', uploadedOffset: offset);
      await _repository.saveJob(job);

      // 4. Upload Chunks
      DateTime lastProgressCall = DateTime.now().subtract(const Duration(seconds: 20));

      final int chunkSize = job.chunkSizeBytes > 0 ? job.chunkSizeBytes : 262144; // 256 KB

      while (offset < fileSize) {
        final int end = (offset + chunkSize - 1) < (fileSize - 1) ? (offset + chunkSize - 1) : (fileSize - 1);
        final int currentChunkLength = end - offset + 1;

        final chunkBytes = await _readChunk(file, offset, currentChunkLength);

        final response = await _uploadChunk(
          sessionUrl: job.sessionUrl!,
          chunkBytes: chunkBytes,
          start: offset,
          end: end,
          total: fileSize,
        );

        if (response.statusCode == 308) {
          // Resume incomplete
          final rangeHeader = response.headers.value('range');
          if (rangeHeader != null) {
            offset = _parseRangeEnd(rangeHeader) + 1;
          } else {
            offset = end + 1;
          }
        } else if (response.statusCode == 200 || response.statusCode == 201) {
          offset = fileSize;
        } else {
          throw DioException(
            requestOptions: RequestOptions(path: job.sessionUrl!),
            response: response,
            error: 'Unexpected status code ${response.statusCode} during chunk upload',
          );
        }

        job = job.copyWith(uploadedOffset: offset);
        await _repository.saveJob(job);
        onProgress?.call(offset, fileSize);

        // Throttled /progress update call to backend (at most once every 15 seconds)
        if (DateTime.now().difference(lastProgressCall).inSeconds >= 15) {
          lastProgressCall = DateTime.now();
          _reportProgress(job.recordingId!, offset);
        }
      }

      // 5. Complete Upload Call
      await _completeUpload(job);
      await _deleteFile(file);

      job = job.copyWith(status: 'completed', uploadedOffset: fileSize);
      await _repository.saveJob(job);

      NotificationService.instance.showLocalNotification(
        title: 'Match Recording Uploaded ✓',
        body: 'Gameplay recording for match #${job.matchKey} was successfully uploaded.',
        payload: {
          'type': 'match_recording_uploaded',
          'tournamentId': job.tournamentId,
          'matchKey': job.matchKey,
        },
      );

      onCompleted?.call();

    } catch (e) {
      debugPrint('Upload error for job ${job.clientRecordingId}: $e');

      String errMsg = 'Upload failed: $e';
      bool isFatal = false;

      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 400 || statusCode == 403 || statusCode == 404) {
          isFatal = true;
          errMsg = 'Server rejected upload (HTTP $statusCode): ${e.response?.data}';
        } else if (statusCode == 409) {
          // Already uploaded
          final file = File(job.filePath);
          await _deleteFile(file);
          job = job.copyWith(status: 'completed');
          await _repository.saveJob(job);
          onCompleted?.call();
          _activeUploads.remove(job.clientRecordingId);
          return;
        }
      }

      job = job.copyWith(
        status: isFatal ? 'failed' : 'pending',
        attempts: job.attempts + 1,
        lastErrorMessage: errMsg,
      );
      await _repository.saveJob(job);
      onError?.call(errMsg);

      if (isFatal) {
        NotificationService.instance.showLocalNotification(
          title: 'Match Recording Upload Failed',
          body: 'Failed to upload match recording for #${job.matchKey}. Tap to check.',
          payload: {
            'type': 'match_recording_failed',
            'tournamentId': job.tournamentId,
            'matchKey': job.matchKey,
          },
        );
      }

      // If transient error, schedule exponential backoff retry if under 10 attempts
      if (!isFatal && job.attempts < 10) {
        final delaySeconds = _getExponentialBackoffDelay(job.attempts);
        debugPrint('Scheduling retry for ${job.clientRecordingId} in $delaySeconds seconds...');
        Future.delayed(Duration(seconds: delaySeconds), () {
          if (_repository.getJob(job.clientRecordingId)?.status != 'completed') {
            _activeUploads.remove(job.clientRecordingId);
            uploadJob(_repository.getJob(job.clientRecordingId) ?? job);
          }
        });
      }

    } finally {
      _activeUploads.remove(job.clientRecordingId);
    }
  }

  Future<RecordingJobModel> _registerOrRenewSession(RecordingJobModel job) async {
    try {
      if (job.recordingId != null && job.isSessionExpired) {
        // Renew expired session
        final response = await _apiClient.get('/recordings/${job.recordingId}/upload-session');
        if (response != null && response is Map<String, dynamic>) {
          final session = response['upload'] ?? response;
          return job.copyWith(
            sessionUrl: session['session_url'] as String?,
            chunkSizeBytes: (session['chunk_size_bytes'] as num?)?.toInt() ?? 262144,
            expiresAt: session['expires_at'] as String?,
            status: 'uploading',
          );
        }
      }

      // Post initial registration
      final endpoint = '/tournaments/${job.tournamentId}/matches/${job.matchKey}/recordings';
      final payload = {
        'client_recording_id': job.clientRecordingId,
        'started_at': job.startedAt,
        'stopped_at': job.stoppedAt,
        'duration_seconds': job.durationSeconds,
        'size_bytes': job.sizeBytes,
        'mime_type': 'video/mp4',
        'resolution': job.resolution,
        'device_model': Platform.operatingSystem,
        'app_version': '1.0.0',
      };

      final response = await _apiClient.post(endpoint, data: payload);

      if (response != null && response is Map<String, dynamic>) {
        final recId = response['recording_id'] as String?;
        final uploadMap = response['upload'] as Map<String, dynamic>?;

        return job.copyWith(
          recordingId: recId,
          sessionUrl: uploadMap?['session_url'] as String?,
          chunkSizeBytes: (uploadMap?['chunk_size_bytes'] as num?)?.toInt() ?? 262144,
          expiresAt: uploadMap?['expires_at'] as String?,
          status: 'uploading',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        debugPrint('RECORDING_ALREADY_UPLOADED (409) received during registration.');
        return job.copyWith(status: 'completed');
      }
      final statusCode = e.response?.statusCode;
      if (statusCode == 400 || statusCode == 403) {
        final msg = 'Backend refused recording: ${e.response?.data}';
        return job.copyWith(status: 'failed', lastErrorMessage: msg);
      }
      rethrow;
    } catch (e) {
      rethrow;
    }

    return job;
  }

  Future<int> _querySessionOffset(String sessionUrl, int totalSize) async {
    try {
      final response = await _uploadDio.put(
        sessionUrl,
        options: Options(
          headers: {
            'Content-Range': 'bytes */$totalSize',
          },
          validateStatus: (status) => status != null && (status == 308 || status == 200 || status == 201),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return totalSize;
      }

      final rangeHeader = response.headers.value('range');
      if (rangeHeader != null) {
        return _parseRangeEnd(rangeHeader) + 1;
      }
    } catch (e) {
      debugPrint('Error querying session offset from Google Drive: $e');
    }
    return 0;
  }

  Future<Response> _uploadChunk({
    required String sessionUrl,
    required List<int> chunkBytes,
    required int start,
    required int end,
    required int total,
  }) async {
    return _uploadDio.put(
      sessionUrl,
      data: Stream.fromIterable([chunkBytes]),
      options: Options(
        headers: {
          'Content-Length': chunkBytes.length,
          'Content-Range': 'bytes $start-$end/$total',
          'Content-Type': 'video/mp4',
        },
        validateStatus: (status) => status != null && (status == 308 || status == 200 || status == 201),
      ),
    );
  }

  Future<void> _reportProgress(String recordingId, int uploadedBytes) async {
    try {
      await _apiClient.post(
        '/recordings/$recordingId/progress',
        data: {'uploaded_bytes': uploadedBytes},
      );
    } catch (e) {
      debugPrint('Non-critical progress report error: $e');
    }
  }

  Future<void> _completeUpload(RecordingJobModel job) async {
    if (job.recordingId == null) return;
    try {
      await _apiClient.post(
        '/recordings/${job.recordingId}/complete',
        data: {'size_bytes': job.sizeBytes},
      );
    } catch (e) {
      debugPrint('Complete upload backend call error: $e');
      // If complete call fails, rethrow so retry handler can retry complete
      rethrow;
    }
  }

  Future<Uint8List> _readChunk(File file, int offset, int length) async {
    final handle = await file.open(mode: FileMode.read);
    try {
      await handle.setPosition(offset);
      return await handle.read(length);
    } finally {
      await handle.close();
    }
  }

  int _parseRangeEnd(String rangeHeader) {
    // Header format e.g. "bytes=0-1048575"
    try {
      final parts = rangeHeader.split('=');
      if (parts.length > 1) {
        final rangeValues = parts[1].split('-');
        if (rangeValues.length > 1) {
          return int.parse(rangeValues[1]);
        }
      }
    } catch (e) {
      debugPrint('Error parsing range header: $e');
    }
    return 0;
  }

  int _getExponentialBackoffDelay(int attempts) {
    final delays = [2, 4, 8, 16, 30, 60];
    if (attempts <= 0) return delays[0];
    if (attempts > delays.length) return delays.last;
    return delays[attempts - 1];
  }

  Future<void> _deleteFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        debugPrint('Successfully deleted local MP4 recording: ${file.path}');
      }
    } catch (e) {
      debugPrint('Error deleting local MP4 recording: $e');
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
