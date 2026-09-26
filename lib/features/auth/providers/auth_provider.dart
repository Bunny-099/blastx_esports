import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/app_constants.dart';
import '../../splash/providers/splash_providers.dart';
import '../data/auth_repository.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_api_service.dart';

// Providers for Data Layer
final authApiServiceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthApiService(apiClient);
});

final authRepositoryProvider = Provider((ref) {
  if (AppConstants.useMockData) return MockAuthRepository();
  
  final apiService = ref.watch(authApiServiceProvider);
  return AuthRepository(apiService);
});

// Fake Repository for testing when backend is not live
class MockAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> sendOtp(String email) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<UserModel> login(String email, String otp) async {
    await Future.delayed(const Duration(seconds: 1));
    return UserModel(
      id: 'mock_user_123',
      name: 'Test Player',
      email: email,
      token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    );
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String otp,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return UserModel(
      id: 'mock_user_456',
      name: name,
      email: email,
      token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    );
  }

  @override
  Future<UserModel> socialLogin(String idToken, String provider) async {
    await Future.delayed(const Duration(seconds: 1));
    return UserModel(
      id: 'mock_user_google',
      name: 'Google User',
      email: 'google@test.com',
      token: 'mock_google_token',
    );
  }
}

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
      
      // Save token and user data
      final storage = ref.read(storageServiceProvider);
      if (user.token != null) {
        await storage.saveToken(user.token!);
      }
      // You might want to save full user object too
      // await storage.saveString('user_data', jsonEncode(user.toJson()));

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
      
      // Save token and user data
      final storage = ref.read(storageServiceProvider);
      if (user.token != null) {
        await storage.saveToken(user.token!);
      }

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

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      final String idToken = googleAuth.idToken ?? googleUser.id;

      UserModel user;
      if (AppConstants.useMockData) {
        user = UserModel(
          id: firebaseUser?.uid ?? googleUser.id,
          name: firebaseUser?.displayName ?? googleUser.displayName ?? 'Google Gamer',
          email: firebaseUser?.email ?? googleUser.email,
          profilePic: firebaseUser?.photoURL ?? googleUser.photoUrl,
          token: 'mock_google_token_${googleUser.id}',
        );
      } else {
        try {
          user = await _repository.socialLogin(idToken, 'google');
          if (user.name == null || user.name!.isEmpty) {
            user = UserModel(
              id: user.id.isNotEmpty ? user.id : (firebaseUser?.uid ?? googleUser.id),
              name: firebaseUser?.displayName ?? googleUser.displayName ?? 'Google Gamer',
              email: user.email.isNotEmpty ? user.email : (firebaseUser?.email ?? googleUser.email),
              profilePic: user.profilePic ?? firebaseUser?.photoURL ?? googleUser.photoUrl,
              token: user.token ?? 'google_token_${googleUser.id}',
            );
          }
        } catch (_) {
          user = UserModel(
            id: firebaseUser?.uid ?? googleUser.id,
            name: firebaseUser?.displayName ?? googleUser.displayName ?? 'Google Gamer',
            email: firebaseUser?.email ?? googleUser.email,
            profilePic: firebaseUser?.photoURL ?? googleUser.photoUrl,
            token: 'google_token_${googleUser.id}',
          );
        }
      }

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
}
