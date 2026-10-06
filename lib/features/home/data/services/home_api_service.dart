import 'package:flutter/foundation.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/home_data_models.dart';

class HomeApiService {
  final ApiClient _apiClient;

  HomeApiService(this._apiClient);

  /// Fetch dynamic promotional hero banners from GET /v1/home/banners
  Future<List<BannerItem>> getBanners() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.homeBanners);
      if (response is List) {
        return response
            .map((e) => BannerItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('HomeApiService.getBanners error: $e');
    }
    return [];
  }

  /// Fetch live tournament stream cards from GET /v1/home/live-streams
  Future<List<LiveStreamCardItem>> getLiveStreams() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.homeLiveStreams);
      if (response is List) {
        return response
            .map((e) =>
                LiveStreamCardItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('HomeApiService.getLiveStreams error: $e');
    }
    return [];
  }

  /// Fetch brand partners from GET /v1/home/partners
  Future<List<PartnerItem>> getPartners() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.homePartners);
      if (response is List) {
        return response
            .map((e) => PartnerItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('HomeApiService.getPartners error: $e');
    }
    return [];
  }

  /// Submit partner inquiry form payload to POST /v1/partners/inquire
  Future<bool> submitPartnerInquiry(PartnerInquiry inquiry) async {
    try {
      await _apiClient.post(
        ApiEndpoints.partnerInquire,
        data: inquiry.toJson(),
      );
      return true;
    } catch (e) {
      debugPrint('HomeApiService.submitPartnerInquiry error: $e');
      return false;
    }
  }
}
