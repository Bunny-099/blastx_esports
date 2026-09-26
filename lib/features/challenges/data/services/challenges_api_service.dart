import 'dart:io';
import 'package:dio/dio.dart';
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

  /// Uploads 480p match recording proof to backend
  Future<Map<String, dynamic>> submitChallengeProof({
    required String challengeId,
    required File videoFile,
  }) async {
    try {
      final fileName = videoFile.path.split('/').last;
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
