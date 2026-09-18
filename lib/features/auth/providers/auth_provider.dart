import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../splash/providers/splash_providers.dart';
import '../data/auth_repository.dart';
import '../data/services/auth_api_service.dart';

// Providers for Data Layer
final authApiServiceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthApiService(apiClient);
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
      // TODO: Save user token and profile locally
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
      // TODO: Save user token and profile locally
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
      // TODO: Implement actual Google Sign-In and get idToken
      // final idToken = await GoogleSignInService.getIdToken();
      // final user = await _repository.socialLogin(idToken, 'google');
      
      await Future.delayed(const Duration(milliseconds: 1000)); // Dummy delay for now
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Google sign-in failed.',
      );
      return false;
    }
  }

  // Email step pe wapas jaana
  void backToEmailStep() {
    state = state.copyWith(step: AuthStep.enterEmail, errorMessage: null);
  }
}
