import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStep { enterEmail, enterOtp, verifying }

class AuthState {
  final AuthStep step;
  final bool isLoading;
  final String? errorMessage;
  final String email;

  const AuthState({
    this.step = AuthStep.enterEmail,
    this.isLoading = false,
    this.errorMessage,
    this.email = '',
  });

  AuthState copyWith({
    AuthStep? step,
    bool? isLoading,
    String? errorMessage,
    String? email,
  }) {
    return AuthState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // null explicitly clear karne ke liye
      email: email ?? this.email,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  // Step 1: Email submit -> OTP bhejna
  Future<void> sendOtp(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      state = state.copyWith(errorMessage: 'Please enter a valid email');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, email: email);

    // TODO: Yahan actual API call aayegi (send OTP to email)
    // Abhi ke liye simulate kar rahe hain 1.5 sec delay se
    await Future.delayed(const Duration(milliseconds: 1500));

    state = state.copyWith(isLoading: false, step: AuthStep.enterOtp);
  }

  // Step 2: OTP verify karna
  Future<void> verifyOtp(String otp) async {
    if (otp.length != 6) {
      state = state.copyWith(errorMessage: 'Enter valid 6-digit OTP');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    // TODO: Yahan actual API call aayegi (verify OTP)
    await Future.delayed(const Duration(milliseconds: 1500));

    state = state.copyWith(isLoading: false);
    // TODO: Success hone par -> go_router se home pe navigate karenge
  }

  // Google sign-in
  Future<void> continueWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // TODO: Yahan Google Sign-In package integrate hoga
    await Future.delayed(const Duration(milliseconds: 1000));

    state = state.copyWith(isLoading: false);
  }

  // Email step pe wapas jaana (agar user email change karna chahe)
  void backToEmailStep() {
    state = state.copyWith(step: AuthStep.enterEmail, errorMessage: null);
  }
}