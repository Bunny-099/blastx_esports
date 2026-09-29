import 'package:dio/dio.dart';
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
        final token = await _storageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        try {
          final deviceInfo = await _deviceInfoService.getDeviceInfo();
          options.headers.addAll(deviceInfo.toHeaders());
        } catch (_) {}

        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        print('Dio Error: ${e.type} -> ${e.message}');
        if (e.error != null) print('Dio Error Detail: ${e.error}');
        if (e.response != null) print('Dio Error Data: ${e.response?.data}');

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
