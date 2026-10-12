import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/network_connectivity_observer.dart';
import '../../splash/providers/splash_providers.dart';
import '../data/repositories/recording_jobs_repository.dart';
import '../data/services/resumable_uploader_service.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final recordingJobsRepositoryProvider = Provider<RecordingJobsRepository?>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  return prefsAsync.when(
    data: (prefs) => RecordingJobsRepository(prefs),
    loading: () => null,
    error: (_, __) => null,
  );
});

final networkConnectivityObserverProvider = Provider<NetworkConnectivityObserver>((ref) {
  return NetworkConnectivityObserver();
});

final uploadWifiOnlyProvider = StateNotifierProvider<UploadWifiOnlyNotifier, bool>((ref) {
  final repo = ref.watch(recordingJobsRepositoryProvider);
  return UploadWifiOnlyNotifier(repo);
});

class UploadWifiOnlyNotifier extends StateNotifier<bool> {
  final RecordingJobsRepository? _repo;

  UploadWifiOnlyNotifier(this._repo) : super(_repo?.getWifiOnlySetting() ?? false);

  Future<void> toggle(bool value) async {
    state = value;
    if (_repo != null) {
      await _repo!.setWifiOnlySetting(value);
    }
  }
}

final resumableUploaderServiceProvider = Provider<ResumableUploaderService?>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final repository = ref.watch(recordingJobsRepositoryProvider);
  final connectivity = ref.watch(networkConnectivityObserverProvider);

  if (repository == null) return null;

  final service = ResumableUploaderService(
    apiClient: apiClient,
    repository: repository,
    connectivityObserver: connectivity,
  );

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
