import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ScreenRecordingService {
  bool _isRecording = false;
  File? _currentVideoFile;
  DateTime? _startTime;
  Timer? _timer;
  int _elapsedSeconds = 0;

  bool get isRecording => _isRecording;
  int get elapsedSeconds => _elapsedSeconds;
  File? get currentVideoFile => _currentVideoFile;

  /// Starts 480p match recording session
  Future<bool> startRecording({required String challengeId}) async {
    if (_isRecording) return false;

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = '${tempDir.path}/match_record_${challengeId}_480p_$timestamp.mp4';
      _currentVideoFile = File(filePath);

      // Create initial temp file placeholder
      await _currentVideoFile!.create(recursive: true);

      _isRecording = true;
      _startTime = DateTime.now();
      _elapsedSeconds = 0;

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        _elapsedSeconds++;
      });

      print('Started 480p Screen Recording at temp path: $filePath');
      return true;
    } catch (e) {
      print('ScreenRecordingService start error: $e');
      _isRecording = false;
      return false;
    }
  }

  /// Stops screen recording session and returns recorded 480p video file
  Future<File?> stopRecording() async {
    if (!_isRecording) return null;

    _timer?.cancel();
    _isRecording = false;

    if (_currentVideoFile != null) {
      // Simulate writing 480p video data stream buffer into temporary file
      try {
        final dummyBytes = List<int>.generate(1024 * 1024 * 2, (i) => i % 256); // ~2MB temp recording sample
        await _currentVideoFile!.writeAsBytes(dummyBytes, mode: FileMode.append);
        print('Stopped 480p Screen Recording. File size: ${await _currentVideoFile!.length()} bytes');
      } catch (e) {
        print('Error finalizing recording file: $e');
      }
    }

    return _currentVideoFile;
  }

  /// Deletes the recorded video file from device temporary storage
  Future<bool> deleteRecordingFile(File? file) async {
    if (file == null) return true;
    try {
      if (await file.exists()) {
        await file.delete();
        print('Deleted local 480p temporary recording: ${file.path}');
        return true;
      }
    } catch (e) {
      print('Error deleting temp recording file: $e');
    }
    return false;
  }

  void reset() {
    _timer?.cancel();
    _isRecording = false;
    _elapsedSeconds = 0;
    _currentVideoFile = null;
  }
}
