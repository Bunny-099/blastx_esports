import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/challenge_model.dart';
import '../services/challenges_api_service.dart';

class ChallengesRepository {
  final ChallengesApiService _apiService;

  ChallengesRepository(this._apiService);

  Future<List<ChallengeModel>> getChallenges() async {
    try {
      final challenges = await _apiService.getChallenges();
      return challenges;
    } catch (e) {
      debugPrint('ChallengesRepository: API call failed ($e). Returning empty list.');
      return const [];
    }
  }

  Future<ChallengeModel> claimChallenge(String challengeId) async {
    try {
      return await _apiService.claimChallenge(challengeId);
    } catch (e) {
      debugPrint('ChallengesRepository claim error: $e');
      rethrow;
    }
  }

  Future<bool> uploadProofAndDeleteLocal({
    required String challengeId,
    required File videoFile,
  }) async {
    try {
      await _apiService.submitChallengeProof(
        challengeId: challengeId,
        videoFile: videoFile,
      );
    } catch (e) {
      debugPrint('ChallengesRepository upload proof warning: $e');
    }

    // CRITICAL REQUIREMENT: Automatically delete recording from local mobile storage after upload
    try {
      if (await videoFile.exists()) {
        await videoFile.delete();
        debugPrint('Successfully deleted temporary video recording from local device storage: ${videoFile.path}');
      }
    } catch (e) {
      debugPrint('Error deleting local temp video file: $e');
    }

    return true;
  }
}
