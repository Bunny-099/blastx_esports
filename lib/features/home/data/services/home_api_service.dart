import 'package:flutter/foundation.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/home_data_models.dart';

class HomeApiService {
  final ApiClient _apiClient;

  HomeApiService(this._apiClient);

  /// Fetch dynamic promotional hero banners from GET /v1/admin/banners?page=1&limit=20 or GET /v1/home/banners
  Future<List<BannerItem>> getBanners() async {
    try {
      dynamic response;
      try {
        response = await _apiClient.get(
          ApiEndpoints.adminBanners,
          queryParameters: {'page': 1, 'limit': 20},
        );
      } catch (_) {
        response = await _apiClient.get(ApiEndpoints.homeBanners);
      }

      List itemsList = [];
      if (response is List) {
        itemsList = response;
      } else if (response is Map) {
        if (response['banners'] is List) {
          itemsList = response['banners'] as List;
        } else if (response['data'] is List) {
          itemsList = response['data'] as List;
        } else if (response['docs'] is List) {
          itemsList = response['docs'] as List;
        } else if (response['items'] is List) {
          itemsList = response['items'] as List;
        } else if (response['results'] is List) {
          itemsList = response['results'] as List;
        }
      }

      return itemsList
          .where((e) =>
              e is Map &&
              (e['isActive'] ?? e['is_active'] ?? true) != false &&
              e['status'] != 'inactive')
          .map((e) => BannerItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('HomeApiService.getBanners error: $e');
    }
    return [];
  }

  /// Fetch live tournament stream cards from GET /v1/home/live-streams or GET /v1/admin/live-streams
  Future<List<LiveStreamCardItem>> getLiveStreams() async {
    try {
      dynamic response;
      try {
        response = await _apiClient.get(ApiEndpoints.homeLiveStreams);
      } catch (_) {
        response = await _apiClient.get(ApiEndpoints.adminLiveStreams);
      }

      List itemsList = [];
      if (response is List) {
        itemsList = response;
      } else if (response is Map) {
        if (response['streams'] is List) {
          itemsList = response['streams'] as List;
        } else if (response['data'] is List) {
          itemsList = response['data'] as List;
        } else if (response['docs'] is List) {
          itemsList = response['docs'] as List;
        } else if (response['items'] is List) {
          itemsList = response['items'] as List;
        }
      }

      return itemsList
          .where((e) => e is Map)
          .map((e) =>
              LiveStreamCardItem.fromJson(Map<String, dynamic>.from(e as Map)))
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
      List itemsList = [];
      if (response is List) {
        itemsList = response;
      } else if (response is Map) {
        if (response['partners'] is List) {
          itemsList = response['partners'] as List;
        } else if (response['data'] is List) {
          itemsList = response['data'] as List;
        } else if (response['docs'] is List) {
          itemsList = response['docs'] as List;
        } else if (response['items'] is List) {
          itemsList = response['items'] as List;
        }
      }

      return itemsList
          .where((e) => e is Map)
          .map((e) => PartnerItem.fromJson(Map<String, dynamic>.from(e as Map)))
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
