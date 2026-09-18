import 'package:flutter_riverpod/riverpod.dart';
import '../../../core/api/api_client.dart';
import '../data/repositories/splash_repository.dart';
import '../data/services/splash_api_service.dart';

final apiClientProvider = Provider((ref) => ApiClient());

final splashApiServiceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SplashApiService(apiClient);
});

final splashRepositoryProvider = Provider((ref) {
  final apiService = ref.watch(splashApiServiceProvider);
  return SplashRepository(apiService);
});
