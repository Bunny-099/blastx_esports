import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/services/notification_navigator.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/sync/real_time_sync_manager.dart';
import '../../challenges/providers/challenges_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../home/providers/navigation_provider.dart';
import '../../live/providers/live_provider.dart';
import '../../live/providers/team_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../splash/providers/splash_providers.dart';
import '../../squad/providers/squad_provider.dart';
import '../data/auth_repository.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_api_service.dart';

// Providers for Data Layer
final authApiServiceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final deviceInfoService = ref.watch(deviceInfoServiceProvider);
  return AuthApiService(apiClient, deviceInfoService);
});

final authRepositoryProvider = Provider((ref) {
  final apiService = ref.watch(authApiServiceProvider);
  return AuthRepository(apiService);
});

// UI State Management
enum AuthStep { enterEmail, enterOtp, verifying }

class AuthState {
  final AuthStep step;
  final bool isLoading;
  final String? errorMessage;
  final String email;
  final String name;

  const AuthState({
    this.step = AuthStep.enterEmail,
    this.isLoading = false,
    this.errorMessage,
    this.email = '',
    this.name = '',
  });

  AuthState copyWith({
    AuthStep? step,
    bool? isLoading,
    String? errorMessage,
    String? email,
    String? name,
  }) {
    return AuthState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      email: email ?? this.email,
      name: name ?? this.name,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  // Step 1: Email submit -> OTP bhejna
  Future<void> sendOtp(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      state = state.copyWith(errorMessage: 'Please enter a valid email');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, email: email);

    try {
      await _repository.sendOtp(email);
      state = state.copyWith(isLoading: false, step: AuthStep.enterOtp);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send OTP. Please try again.',
      );
    }
  }

  // Signup Step 1: Name and Email submit -> OTP bhejna
  Future<void> sendSignupOtp(String name, String email) async {
    if (name.isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter your name');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      state = state.copyWith(errorMessage: 'Please enter a valid email');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      email: email,
      name: name,
    );

    try {
      await _repository.sendOtp(email);
      state = state.copyWith(isLoading: false, step: AuthStep.enterOtp);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send OTP. Please try again.',
      );
    }
  }

  // Step 2: OTP verify karna for Login
  Future<bool> verifyOtp(String otp) async {
    if (otp.length != 6) {
      state = state.copyWith(errorMessage: 'Enter valid 6-digit OTP');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await _repository.login(state.email, otp);

      // Purge any residual cached provider state from previous sessions
      _clearUserCacheAndProviders();
      
      // Save token and user data
      final storage = ref.read(storageServiceProvider);
      if (user.token != null) {
        await storage.saveToken(user.token!);
      }

      await storage.saveString('user_profile_data', jsonEncode({
        'id': user.id,
        'name': user.name ?? 'Gamer',
        'email': user.email,
        'profile_pic': user.profilePic,
      }));

      // Register FCM device token with backend and process pending notification payload
      NotificationService.instance.registerDeviceTokenWithBackend(_repository, storage);
      NotificationNavigator.processPendingPayloadIfAny(isLoggedIn: true);

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid OTP or Login failed.',
      );
      return false;
    }
  }

  // Signup Step 2: OTP verify for signup
  Future<bool> verifySignupOtp(String otp) async {
    if (otp.length != 6) {
      state = state.copyWith(errorMessage: 'Enter valid 6-digit OTP');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await _repository.register(
        name: state.name,
        email: state.email,
        otp: otp,
      );

      // Purge any residual cached provider state from previous sessions
      _clearUserCacheAndProviders();
      
      // Save token and user data
      final storage = ref.read(storageServiceProvider);
      if (user.token != null) {
        await storage.saveToken(user.token!);
      }

      await storage.saveString('user_profile_data', jsonEncode({
        'id': user.id,
        'name': user.name ?? state.name,
        'email': user.email,
        'profile_pic': user.profilePic,
      }));

      // Register FCM device token with backend and process pending notification payload
      NotificationService.instance.registerDeviceTokenWithBackend(_repository, storage);
      NotificationNavigator.processPendingPayloadIfAny(isLoggedIn: true);

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Registration failed. Try again.',
      );
      return false;
    }
  }

  // Google sign-in
  Future<bool> continueWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: '252531921295-maivho5ga1plaqmr3hndfuif0960lvp6.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      final String idToken = googleAuth.idToken ?? googleUser.id;

      final UserModel user = await _repository.socialLogin(idToken, 'google');

      // Purge any residual cached provider state from previous sessions
      _clearUserCacheAndProviders();

      final storage = ref.read(storageServiceProvider);
      if (user.token != null) {
        await storage.saveToken(user.token!);
      }

      await storage.saveString('user_profile_data', jsonEncode({
        'id': user.id,
        'name': user.name ?? googleUser.displayName ?? 'Gamer',
        'email': user.email,
        'profile_pic': user.profilePic ?? googleUser.photoUrl,
      }));

      // Register FCM device token with backend and process pending notification payload
      NotificationService.instance.registerDeviceTokenWithBackend(_repository, storage);
      NotificationNavigator.processPendingPayloadIfAny(isLoggedIn: true);

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Google sign-in failed. Please try again.',
      );
      return false;
    }
  }

  // Email step pe wapas jaana
  void backToEmailStep() {
    state = state.copyWith(step: AuthStep.enterEmail, errorMessage: null);
  }

  /// Clears cached sync tasks and invalidates all Riverpod providers across features
  void _clearUserCacheAndProviders() {
    try {
      // 1. Reset RealTimeSyncManager tasks & cached payload hashes
      ref.read(realTimeSyncManagerProvider).clearAll();
    } catch (e) {
      debugPrint('Sync Manager Reset Error: $e');
    }

    try {
      // 2. Invalidate user profile, squad, notifications & navigation
      ref.invalidate(profileProvider);
      ref.invalidate(squadProvider);
      ref.invalidate(notificationProvider);
      ref.invalidate(navigationIndexProvider);

      // 3. Invalidate team and join request family providers
      ref.invalidate(teamProvider);
      ref.invalidate(ownerJoinRequestsProvider);
      ref.invalidate(myPendingRequestsProvider);
      ref.invalidate(approvalsProvider);

      // 4. Invalidate tournament API providers
      ref.invalidate(apiTournamentsProvider);
      ref.invalidate(blastxLiveTournamentsApiProvider);
      ref.invalidate(blastxUpcomingTournamentsApiProvider);
      ref.invalidate(blastxTournamentsApiProvider);
      ref.invalidate(tournamentDetailApiProvider);
      ref.invalidate(roomDetailsProvider);
      ref.invalidate(registeredTeamsProvider);
      ref.invalidate(tournamentStagesProvider);
      ref.invalidate(myActiveAssignmentProvider);
      ref.invalidate(tournamentBracketProvider);

      // 5. Invalidate challenges and user home stats
      ref.invalidate(challengesProvider);
      ref.invalidate(userHomeStatsProvider);
    } catch (e) {
      debugPrint('Provider Invalidation Error: $e');
    }
  }

  // Logout user
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Unregister FCM device token BEFORE clearing local auth session
      await NotificationService.instance.unregisterDeviceTokenFromBackend(_repository);
    } catch (e) {
      debugPrint('Unregister Device Token Error: $e');
    }

    try {
      // 1. Call Backend Logout API
      await _repository.logout();
    } catch (e) {
      debugPrint('Backend Logout Error: $e');
    }

    try {
      // 2. Sign out Google and Firebase Auth
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint('Sign Out Error: $e');
    }

    try {
      // 3. Clear Local Storage
      final storage = ref.read(storageServiceProvider);
      await storage.clearAll();
    } catch (e) {
      debugPrint('Storage Clear Error: $e');
    }

    // 4. Reset RealTimeSyncManager tasks & hashes and invalidate Riverpod providers
    _clearUserCacheAndProviders();

    // 5. Reset Auth State
    state = const AuthState();
  }
}
