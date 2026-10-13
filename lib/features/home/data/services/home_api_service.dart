import 'package:flutter/foundation.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/home_data_models.dart';

class HomeApiService {
  final ApiClient _apiClient;

  HomeApiService(this._apiClient);

  List _extractListFromResponse(dynamic response, String primaryKey) {
    if (response is List) return response;
    if (response is Map) {
      final map = Map<String, dynamic>.from(response);
      if (map[primaryKey] is List) return map[primaryKey] as List;
      if (map['data'] is List) return map['data'] as List;
      if (map['data'] is Map) {
        final dataMap = Map<String, dynamic>.from(map['data'] as Map);
        if (dataMap[primaryKey] is List) return dataMap[primaryKey] as List;
        if (dataMap['items'] is List) return dataMap['items'] as List;
        if (dataMap['data'] is List) return dataMap['data'] as List;
      }
      if (map['items'] is List) return map['items'] as List;
      if (map['docs'] is List) return map['docs'] as List;
      if (map['results'] is List) return map['results'] as List;
    }
    return [];
  }

  /// Fetch dynamic promotional hero banners from public endpoint GET /v1/home/banners
  Future<List<BannerItem>> getBanners() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.homeBanners);
      final itemsList = _extractListFromResponse(response, 'banners');

      return itemsList
          .whereType<Map>()
          .where((e) =>
              (e['isActive'] ?? e['is_active'] ?? true) != false &&
              e['status'] != 'inactive')
          .map((e) => BannerItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('HomeApiService.getBanners error: $e');
    }
    return [];
  }

  /// Fetch live tournament stream cards from public endpoint GET /v1/home/live-streams
  Future<List<LiveStreamCardItem>> getLiveStreams() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.homeLiveStreams);
      final itemsList = _extractListFromResponse(response, 'streams');

      return itemsList
          .whereType<Map>()
          .map((e) =>
              LiveStreamCardItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('HomeApiService.getLiveStreams error: $e');
    }
    return [];
  }

  /// Fetch brand partners from GET /v1/home/partners
  Future<List<PartnerItem>> getPartners() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.homePartners);
      final itemsList = _extractListFromResponse(response, 'partners');

      return itemsList
          .whereType<Map>()
          .map((e) => PartnerItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
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
