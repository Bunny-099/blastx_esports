import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ScreenRecordingService {
  static const MethodChannel _recorderChannel =
      MethodChannel('com.blastix.esports/screen_recorder');

  bool _isRecording = false;
  File? _currentVideoFile;
  Timer? _timer;
  int _elapsedSeconds = 0;
  final ImagePicker _picker = ImagePicker();

  bool get isRecording => _isRecording;
  int get elapsedSeconds => _elapsedSeconds;
  File? get currentVideoFile => _currentVideoFile;

  // Testing / Fake Support
  bool testMode = false;
  bool mockPermissionGranted = true;
  int stopDelayMs = 1500;
  File? mockRecordedFile;

  /// Restores device preferred orientations to default (all orientations)
  Future<void> _restoreOrientation() async {
    try {
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    } catch (e) {
      debugPrint('Error restoring device orientation: $e');
    }
  }

  /// Locks device orientation to landscape and waits for rotation animation to settle
  Future<void> _lockLandscapeOrientation() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      // Wait ~800ms for rotation animation to settle before starting screen recording
      await Future.delayed(const Duration(milliseconds: 800));
    } catch (e) {
      debugPrint('Error setting landscape orientation: $e');
    }
  }

  /// Starts landscape match recording session
  Future<bool> startRecording({required String challengeId}) async {
    if (_isRecording) return false;

    // Lock device orientation to landscape before starting screen recording
    await _lockLandscapeOrientation();

    if (testMode) {
      if (!mockPermissionGranted) {
        _isRecording = false;
        await _restoreOrientation();
        return false;
      }
      _isRecording = true;
      _elapsedSeconds = 0;
      if (mockRecordedFile != null) {
        _currentVideoFile = mockRecordedFile;
      } else {
        final tempDir = Directory.systemTemp;
        _currentVideoFile = File('${tempDir.path}/test_match_record_$challengeId.mp4');
      }
      return true;
    }

    try {
      Directory tempDir;
      try {
        tempDir = await getTemporaryDirectory();
      } catch (e) {
        debugPrint('PathProvider getTemporaryDirectory fallback to systemTemp: $e');
        tempDir = Directory.systemTemp;
      }

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = '${tempDir.path}/match_record_${challengeId}_720p_$timestamp.mp4';
      _currentVideoFile = File(filePath);

      // Create initial temp file placeholder
      await _currentVideoFile!.create(recursive: true);

      bool nativeStarted = false;
      if (!kIsWeb && Platform.isAndroid) {
        try {
          final bool? result = await _recorderChannel.invokeMethod<bool>(
            'startRecording',
            {'filePath': filePath},
          );
          nativeStarted = result ?? false;
          debugPrint('Native Android ScreenRecorder start response: $nativeStarted');
        } catch (e) {
          debugPrint('Native ScreenRecorder start error: $e');
          nativeStarted = false;
        }

        // If native recorder failed or permission was denied by user, cleanup and return false
        if (!nativeStarted) {
          debugPrint('Native screen recorder failed to start. Cleaning up temp placeholder.');
          if (_currentVideoFile != null && await _currentVideoFile!.exists()) {
            await _currentVideoFile!.delete();
          }
          _currentVideoFile = null;
          _isRecording = false;
          await _restoreOrientation();
          return false;
        }
      }

      _isRecording = true;
      _elapsedSeconds = 0;

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        _elapsedSeconds++;
      });

      debugPrint('Started Landscape Screen Recording session at temp path: $filePath');
      return true;
    } catch (e) {
      debugPrint('ScreenRecordingService start error: $e');
      if (_currentVideoFile != null && await _currentVideoFile!.exists()) {
        try {
          await _currentVideoFile!.delete();
        } catch (_) {}
      }
      _currentVideoFile = null;
      _isRecording = false;
      await _restoreOrientation();
      return false;
    }
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

      // Wait 1.5 seconds so Android OS MediaRecorder finishes flushing MP4 file container to disk
      await Future.delayed(const Duration(milliseconds: 1500));

      if (nativeStoppedPath != null && nativeStoppedPath.isNotEmpty) {
        _currentVideoFile = File(nativeStoppedPath);
      }

      if (_currentVideoFile != null) {
        try {
          if (await _currentVideoFile!.exists()) {
            final int length = await _currentVideoFile!.length();
            debugPrint('Stopped Screen Recording. File exists, length: $length bytes at ${_currentVideoFile!.path}');

            // Verify file is a valid video (> 10 KB)
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
      // Always restore device orientation after stopping recording or on error
      await _restoreOrientation();
    }
  }

  /// Pick real match video recording proof from device gallery or camera
  Future<File?> pickVideoProof({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 30),
      );

      if (pickedFile != null && pickedFile.path.isNotEmpty) {
        final file = File(pickedFile.path);
        if (await file.exists() && await file.length() > 0) {
          debugPrint('Selected video proof file: ${file.path} (${await file.length()} bytes)');
          return file;
        }
      }
    } catch (e) {
      debugPrint('Error picking video proof: $e');
    }
    return null;
  }

  /// Deletes the recorded video file from device temporary storage
  Future<bool> deleteRecordingFile(File? file) async {
    if (file == null) return true;
    try {
      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted local 480p temporary recording: ${file.path}');
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
    _restoreOrientation();
  }
}
