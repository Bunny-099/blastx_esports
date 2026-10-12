import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ScreenRecordingService {
  static const MethodChannel _recorderChannel =
      MethodChannel('com.blastix.esports/screen_recorder');
  static const EventChannel _eventsChannel =
      EventChannel('com.blastix.esports/screen_recorder_events');

  bool _isRecording = false;
  File? _currentVideoFile;
  Timer? _timer;
  int _elapsedSeconds = 0;
  final ImagePicker _picker = ImagePicker();

  StreamSubscription? _eventSubscription;
  final _recordingEventsController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get recordingEvents => _recordingEventsController.stream;

  bool get isRecording => _isRecording;
  int get elapsedSeconds => _elapsedSeconds;
  File? get currentVideoFile => _currentVideoFile;

  // Testing / Fake Support
  bool testMode = false;
  bool mockPermissionGranted = true;
  int stopDelayMs = 1500;
  File? mockRecordedFile;

  ScreenRecordingService() {
    _initEventChannel();
  }

  void _initEventChannel() {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      _eventSubscription = _eventsChannel.receiveBroadcastStream().listen(
        (event) {
          if (event is Map) {
            final map = Map<String, dynamic>.from(event);
            debugPrint('Native ScreenRecorder Event Received: $map');
            _recordingEventsController.add(map);

            if (map['event'] == 'recordingStopped') {
              _isRecording = false;
              _timer?.cancel();
            } else if (map['event'] == 'recordingFailed') {
              _isRecording = false;
              _timer?.cancel();
            }
          }
        },
        onError: (err) {
          debugPrint('Native ScreenRecorder EventChannel error: $err');
        },
      );
    } catch (e) {
      debugPrint('Could not bind EventChannel: $e');
    }
  }

  /// Restores device preferred orientations to default
  Future<void> restoreOrientation() async {
    try {
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    } catch (e) {
      debugPrint('Error restoring device orientation: $e');
    }
  }

  /// Locks device orientation to landscape
  Future<void> lockLandscapeOrientation() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await Future.delayed(const Duration(milliseconds: 800));
    } catch (e) {
      debugPrint('Error setting landscape orientation: $e');
    }
  }

  /// Query pending native recordings stored in SharedPreferences
  Future<List<Map<String, dynamic>>> getPendingRecordings() async {
    if (testMode || kIsWeb || !Platform.isAndroid) return [];
    try {
      final List<dynamic>? rawList =
          await _recorderChannel.invokeListMethod<dynamic>('getPendingRecordings');
      if (rawList == null) return [];
      return rawList.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (e) {
      debugPrint('Error getting pending recordings from native: $e');
      return [];
    }
  }

  /// Clear a pending native recording item from SharedPreferences
  Future<bool> clearPendingRecording(String clientRecordingId) async {
    if (testMode || kIsWeb || !Platform.isAndroid) return true;
    try {
      final bool? res = await _recorderChannel.invokeMethod<bool>(
        'clearPendingRecording',
        {'clientRecordingId': clientRecordingId},
      );
      return res ?? true;
    } catch (e) {
      debugPrint('Error clearing pending recording: $e');
      return false;
    }
  }

  /// Get native recording app-specific directory
  Future<String> getRecordingDirectory() async {
    if (testMode || kIsWeb || !Platform.isAndroid) {
      final tempDir = await getTemporaryDirectory();
      return tempDir.path;
    }
    try {
      final String? dir = await _recorderChannel.invokeMethod<String>('getRecordingDirectory');
      if (dir != null && dir.isNotEmpty) return dir;
    } catch (e) {
      debugPrint('Error getting native recording directory: $e');
    }
    final tempDir = await getTemporaryDirectory();
    return tempDir.path;
  }

  /// Configured start match recording call
  Future<bool> startMatchRecording({
    required String tournamentId,
    required String matchKey,
    required String clientRecordingId,
    int videoBitrateKbps = 2500,
    int maxHeight = 720,
    int fps = 30,
    int maxDurationMinutes = 60,
    int minFreeSpaceMb = 1500,
  }) async {
    if (_isRecording) return false;

    await lockLandscapeOrientation();

    if (testMode) {
      if (!mockPermissionGranted) {
        _isRecording = false;
        await restoreOrientation();
        return false;
      }
      _isRecording = true;
      _elapsedSeconds = 0;
      final dirPath = await getRecordingDirectory();
      _currentVideoFile = File('$dirPath/match_record_${clientRecordingId}.mp4');
      return true;
    }

    try {
      final dirPath = await getRecordingDirectory();
      final String filePath = '$dirPath/match_record_${tournamentId}_${matchKey}_$clientRecordingId.mp4';
      _currentVideoFile = File(filePath);

      bool nativeStarted = false;
      if (!kIsWeb && Platform.isAndroid) {
        try {
          final bool? result = await _recorderChannel.invokeMethod<bool>(
            'startRecording',
            {
              'filePath': filePath,
              'videoBitrate': videoBitrateKbps * 1000,
              'maxHeight': maxHeight,
              'fps': fps,
              'maxDurationMinutes': maxDurationMinutes,
              'minFreeSpaceMb': minFreeSpaceMb,
              'tournamentId': tournamentId,
              'matchKey': matchKey,
              'clientRecordingId': clientRecordingId,
            },
          );
          nativeStarted = result ?? false;
        } on PlatformException catch (e) {
          debugPrint('Native ScreenRecorder start PlatformException: ${e.code} - ${e.message}');
          if (e.code == 'LOW_STORAGE') {
            _isRecording = false;
            await restoreOrientation();
            rethrow;
          }
          nativeStarted = false;
        } catch (e) {
          debugPrint('Native ScreenRecorder start error: $e');
          nativeStarted = false;
        }

        if (!nativeStarted) {
          if (_currentVideoFile != null && await _currentVideoFile!.exists()) {
            await _currentVideoFile!.delete();
          }
          _currentVideoFile = null;
          _isRecording = false;
          await restoreOrientation();
          return false;
        }
      }

      _isRecording = true;
      _elapsedSeconds = 0;

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        _elapsedSeconds++;
      });

      return true;
    } catch (e) {
      debugPrint('ScreenRecordingService startMatchRecording error: $e');
      if (_currentVideoFile != null && await _currentVideoFile!.exists()) {
        try {
          await _currentVideoFile!.delete();
        } catch (_) {}
      }
      _currentVideoFile = null;
      _isRecording = false;
      await restoreOrientation();
      rethrow;
    }
  }

  /// Legacy start recording method (for Daily Challenges)
  Future<bool> startRecording({required String challengeId}) async {
    return startMatchRecording(
      tournamentId: 'challenge_$challengeId',
      matchKey: 'challenge_match',
      clientRecordingId: 'challenge_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Stops screen recording session and returns recorded video file if valid (>10 KB)
  Future<File?> stopRecording() async {
    try {
      if (!_isRecording && _currentVideoFile == null) return null;

      _timer?.cancel();
      _isRecording = false;

      if (testMode) {
        if (stopDelayMs > 0) {
          await Future.delayed(Duration(milliseconds: stopDelayMs));
        }
        return _currentVideoFile;
      }

      String? nativeStoppedPath;
      if (!kIsWeb && Platform.isAndroid) {
        try {
          nativeStoppedPath = await _recorderChannel.invokeMethod<String>('stopRecording');
          debugPrint('Native Android ScreenRecorder stopped. Path: $nativeStoppedPath');
        } catch (e) {
          debugPrint('Native ScreenRecorder stop error: $e');
        }
      }

      await Future.delayed(const Duration(milliseconds: 1000));

      if (nativeStoppedPath != null && nativeStoppedPath.isNotEmpty) {
        _currentVideoFile = File(nativeStoppedPath);
      }

      if (_currentVideoFile != null) {
        try {
          if (await _currentVideoFile!.exists()) {
            final int length = await _currentVideoFile!.length();
            debugPrint('Stopped Screen Recording. File exists, length: $length bytes at ${_currentVideoFile!.path}');

            if (length > 10 * 1024) {
              final recordedFile = _currentVideoFile;
              return recordedFile;
            } else {
              debugPrint('Recording file is too small ($length bytes). Deleting invalid file.');
              await _currentVideoFile!.delete();
            }
          }
        } catch (e) {
          debugPrint('Error checking or finalizing recording file: $e');
        }
      }

      _currentVideoFile = null;
      return null;
    } finally {
      await restoreOrientation();
    }
  }

  /// Pick video proof from device gallery or camera
  Future<File?> pickVideoProof({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 30),
      );

      if (pickedFile != null && pickedFile.path.isNotEmpty) {
        final file = File(pickedFile.path);
        if (await file.exists() && await file.length() > 0) {
          return file;
        }
      }
    } catch (e) {
      debugPrint('Error picking video proof: $e');
    }
    return null;
  }

  /// Deletes recorded video file
  Future<bool> deleteRecordingFile(File? file) async {
    if (file == null) return true;
    try {
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting temp recording file: $e');
    }
    return false;
  }

  void reset() {
    _timer?.cancel();
    _isRecording = false;
    _elapsedSeconds = 0;
    _currentVideoFile = null;
    restoreOrientation();
  }

  void dispose() {
    _eventSubscription?.cancel();
    _recordingEventsController.close();
  }
}
