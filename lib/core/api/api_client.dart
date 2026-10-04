import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/device_info_service.dart';
import '../services/storage_service.dart';
import 'api_endpoints.dart';

class ApiClient {
  late final Dio _dio;
  final StorageService _storageService;
  final DeviceInfoService _deviceInfoService;

  ApiClient(this._storageService, this._deviceInfoService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final isPublicConfig = options.path == ApiEndpoints.appInit;
        if (!isPublicConfig) {
          final token = await _storageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }

        try {
          final deviceInfo = await _deviceInfoService.getDeviceInfo();
          options.headers.addAll(deviceInfo.toHeaders());
        } catch (_) {}

        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        debugPrint('Dio Error: ${e.type} -> ${e.message}');
        if (e.error != null) debugPrint('Dio Error Detail: ${e.error}');
        if (e.response != null) debugPrint('Dio Error Data: ${e.response?.data}');

        if (e.response?.statusCode == 401) {
          // Auto logout on token expiry
          await _storageService.deleteToken();
        }
        return handler.next(e);
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  dynamic _handleResponse(Response response) {
    if (response.data != null && response.data['status'] == 'success') {
      return response.data['data'];
    }
    return response.data;
  }
}
