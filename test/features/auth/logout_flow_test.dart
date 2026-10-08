import 'package:blastix_esports/core/services/storage_service.dart';
import 'package:blastix_esports/core/sync/real_time_sync_manager.dart';
import 'package:blastix_esports/features/auth/providers/auth_provider.dart';
import 'package:blastix_esports/features/profile/providers/profile_provider.dart';
import 'package:blastix_esports/features/splash/providers/splash_providers.dart';
import 'package:blastix_esports/features/squad/providers/squad_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeStorageService implements StorageService {
  final Map<String, String> _data = {};
  bool cleared = false;

  @override
  Future<void> init() async {}

  @override
  Future<void> saveToken(String token) async {
    _data['auth_token'] = token;
  }

  @override
  Future<String?> getToken() async => _data['auth_token'];

  @override
  Future<void> deleteToken() async {
    _data.remove('auth_token');
  }

  @override
  Future<void> saveString(String key, String value) async {
    _data[key] = value;
  }

  @override
  String? getString(String key) => _data[key];

  @override
  Future<void> clearAll() async {
    _data.clear();
    cleared = true;
  }
}

class FakeRealTimeSyncManager implements RealTimeSyncManager {
  @override
  void register({
    required String key,
    required Future<dynamic> Function() fetcher,
    required void Function(dynamic data) onChanged,
    bool runImmediately = false,
  }) {}

  @override
  void unregister(String key) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeStorageService fakeStorage;
  late FakeRealTimeSyncManager fakeSync;

  setUp(() {
    RealTimeSyncManager.isTestMode = true;
    fakeStorage = FakeStorageService();
    fakeSync = FakeRealTimeSyncManager();
  });

  test('Logout flow clears storage, resets AuthNotifier state, and invalidates providers', () async {
    await fakeStorage.saveToken('test_jwt_token_123');
    await fakeStorage.saveString('user_profile_data', '{"id":"user_123","name":"Test User"}');

    expect(await fakeStorage.getToken(), equals('test_jwt_token_123'));

    final container = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(fakeStorage),
        realTimeSyncManagerProvider.overrideWithValue(fakeSync),
      ],
    );

    // Read initial auth state
    final authStateBefore = container.read(authProvider);
    expect(authStateBefore.isLoading, isFalse);

    // Call logout
    await container.read(authProvider.notifier).logout();

    // Verify StorageService cleared
    expect(fakeStorage.cleared, isTrue);
    expect(await fakeStorage.getToken(), null);

    // Verify AuthNotifier state reset
    final authStateAfter = container.read(authProvider);
    expect(authStateAfter.step, equals(AuthStep.enterEmail));
    expect(authStateAfter.isLoading, isFalse);
    expect(authStateAfter.email, isEmpty);

    // Verify providers can build cleanly
    final profileState = container.read(profileProvider);
    expect(profileState, isNotNull);

    final squadState = container.read(squadProvider);
    expect(squadState, isNotNull);
  });
}
