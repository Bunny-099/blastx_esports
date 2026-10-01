import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/challenge_model.dart';

class ChallengesApiService {
  final ApiClient _apiClient;

  ChallengesApiService(this._apiClient);

  /// Fetches active/available challenges from backend
  Future<List<ChallengeModel>> getChallenges() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.challenges);
      if (response is List) {
        return response
            .map((item) => ChallengeModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Claims reward XP for a completed challenge
  Future<ChallengeModel> claimChallenge(String challengeId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.claimChallenge(challengeId),
      );
      if (response is Map<String, dynamic>) {
        return ChallengeModel.fromJson(response);
      }
      throw Exception('Invalid response format');
    } catch (e) {
      rethrow;
    }
  }

  /// Uploads match recording proof video to backend
  Future<Map<String, dynamic>> submitChallengeProof({
    required String challengeId,
    required File videoFile,
  }) async {
    if (!await videoFile.exists()) {
      throw Exception('Video recording file does not exist at path: ${videoFile.path}');
    }

    final fileSize = await videoFile.length();
    const int minSizeBytes = 100 * 1024; // 100 KB minimum
    if (fileSize < minSizeBytes) {
      throw Exception('Recording file is too small (${(fileSize / 1024).toStringAsFixed(1)} KB). Recording was not saved properly. Minimum required size is 100 KB. Please record again.');
    }

    const int maxSizeBytes = 60 * 1024 * 1024; // 60 MB backend limit
    if (fileSize > maxSizeBytes) {
      final double sizeMb = fileSize / (1024 * 1024);
      throw Exception('Video file size (${sizeMb.toStringAsFixed(1)} MB) exceeds the maximum allowed limit of 60 MB.');
    }

    try {
      final fileName = videoFile.path.split(Platform.pathSeparator).last.split('/').last;
      debugPrint('Uploading proof video: $fileName, size: $fileSize bytes (${videoFile.path})');

      final formData = FormData.fromMap({
        'challenge_id': challengeId,
        'resolution': '480p',
        'file': await MultipartFile.fromFile(
          videoFile.path,
          filename: fileName,
        ),
      });

      final response = await _apiClient.post(
        ApiEndpoints.submitChallengeProof(challengeId),
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response is Map<String, dynamic>) {
        return response;
      }
      return {'status': 'success', 'message': 'Proof uploaded successfully'};
    } catch (e) {
      rethrow;
    }
  }
}
