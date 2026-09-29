import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/device_info_service.dart';
import '../../../core/services/storage_service.dart';
import '../data/repositories/splash_repository.dart';
import '../data/services/splash_api_service.dart';

final storageServiceProvider = Provider((ref) => StorageService());

final deviceInfoServiceProvider = Provider((ref) => DeviceInfoService());

final apiClientProvider = Provider((ref) {
  final storage = ref.watch(storageServiceProvider);
  final deviceInfo = ref.watch(deviceInfoServiceProvider);
  return ApiClient(storage, deviceInfo);
});

final splashApiServiceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SplashApiService(apiClient);
});

final splashRepositoryProvider = Provider((ref) {
  final apiService = ref.watch(splashApiServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return SplashRepository(apiService, storageService);
});
