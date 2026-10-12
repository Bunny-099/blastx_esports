import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recording_job_model.dart';

class RecordingJobsRepository {
  static const String _storageKey = 'blastix_upload_jobs';
  static const String _wifiOnlyKey = 'blastix_upload_wifi_only';

  final SharedPreferences _prefs;

  RecordingJobsRepository(this._prefs);

  List<RecordingJobModel> getAllJobs() {
    try {
      final jsonStr = _prefs.getString(_storageKey);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((item) => RecordingJobModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      debugPrint('Error reading upload jobs from SharedPreferences: $e');
      return [];
    }
  }

  Future<void> saveJob(RecordingJobModel job) async {
    final jobs = getAllJobs();
    final index = jobs.indexWhere((j) => j.clientRecordingId == job.clientRecordingId);
    if (index >= 0) {
      jobs[index] = job;
    } else {
      jobs.add(job);
    }
    await _saveAll(jobs);
  }

  Future<void> removeJob(String clientRecordingId) async {
    final jobs = getAllJobs();
    jobs.removeWhere((j) => j.clientRecordingId == clientRecordingId);
    await _saveAll(jobs);
  }

  Future<void> _saveAll(List<RecordingJobModel> jobs) async {
    try {
      final list = jobs.map((j) => j.toJson()).toList();
      await _prefs.setString(_storageKey, jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving upload jobs to SharedPreferences: $e');
    }
  }

  RecordingJobModel? getJob(String clientRecordingId) {
    final jobs = getAllJobs();
    try {
      return jobs.firstWhere((j) => j.clientRecordingId == clientRecordingId);
    } catch (_) {
      return null;
    }
  }

  RecordingJobModel? getJobForMatch(String tournamentId, String matchKey) {
    final jobs = getAllJobs();
    try {
      return jobs.firstWhere(
        (j) => j.tournamentId == tournamentId && j.matchKey == matchKey,
      );
    } catch (_) {
      return null;
    }
  }

  bool getWifiOnlySetting() {
    return _prefs.getBool(_wifiOnlyKey) ?? false;
  }

  Future<void> setWifiOnlySetting(bool wifiOnly) async {
    await _prefs.setBool(_wifiOnlyKey, wifiOnly);
  }

  /// Clean up orphan recording files in directory older than 7 days
  Future<void> cleanupOrphanRecordings(String recordingDirectory) async {
    try {
      final dir = Directory(recordingDirectory);
      if (!await dir.exists()) return;

      final jobs = getAllJobs();
      final activeFilePaths = jobs.map((j) => j.filePath).toSet();
      final now = DateTime.now();

      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.mp4')) {
          if (!activeFilePaths.contains(entity.path)) {
            final stat = await entity.stat();
            final age = now.difference(stat.modified);
            if (age.inDays >= 7) {
              debugPrint('Deleting orphan recording file older than 7 days: ${entity.path}');
              try {
                await entity.delete();
              } catch (e) {
                debugPrint('Failed to delete orphan file: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up orphan recordings: $e');
    }
  }
}
