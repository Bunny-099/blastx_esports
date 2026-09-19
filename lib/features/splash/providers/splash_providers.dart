import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';
import '../data/models/app_config_model.dart';
import '../data/repositories/splash_repository.dart';
import '../data/services/splash_api_service.dart';

final storageServiceProvider = Provider((ref) => StorageService());

final apiClientProvider = Provider((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiClient(storage);
});

final splashApiServiceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SplashApiService(apiClient);
});

final splashRepositoryProvider = Provider((ref) {
  if (AppConstants.useMockData) return MockSplashRepository();

  final apiService = ref.watch(splashApiServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return SplashRepository(apiService, storageService);
});

// Fake Splash Repository
class MockSplashRepository implements SplashRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<AppConfigModel> getAppConfig() async {
    await Future.delayed(const Duration(seconds: 1));
    return AppConfigModel(
      minVersion: '1.0.0',
      latestVersion: '1.0.0',
      isMaintenance: false,
    );
  }

  @override
  Future<bool> checkUserAuth() async {
    return false;
  }
}
