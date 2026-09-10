import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final isOtpStep = authState.step == AuthStep.enterOtp;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top header image ──
            Image.asset(
              'assets/images/login_top.png',
              fit: BoxFit.contain,
            ),

            // ── Form section ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Login to continue to BlastXEsports',
                    style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Email',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                  ),

                  if (authState.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        authState.errorMessage!,
                        style: GoogleFonts.poppins(color: AppColors.error, fontSize: 13),
                      ),
                    ),

                  const SizedBox(height: 16),

                  if (!isOtpStep)
                    _GlowButton(
                      text: 'Send OTP',
                      isLoading: authState.isLoading,
                      onPressed: () =>
                          authNotifier.sendOtp(_emailController.text.trim()),
                    ),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    child: isOtpStep
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: authNotifier.backToEmailStep,
                              child: Text(
                                'Change email',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.secondaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.surfaceMuted)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'Enter OTP',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: AppColors.surfaceMuted)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sent to ${authState.email}',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          controller: _otpController,
                          hintText: '6-digit code',
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                        ),
                        const SizedBox(height: 16),
                        _GlowButton(
                          text: 'Verify & Login',
                          isLoading: authState.isLoading,
                          showArrow: true,
                          onPressed: () =>
                              authNotifier.verifyOtp(_otpController.text.trim()),
                        ),
                        const SizedBox(height: 8),
                      ],
                    )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.surfaceMuted)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OR',
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted)),
                      ),
                      Expanded(child: Divider(color: AppColors.surfaceMuted)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _GoogleButton(onTap: () => authNotifier.continueWithGoogle()),

                  const SizedBox(height: 32),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ",
                            style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
                        GestureDetector(
                          onTap: () {
                            // TODO: context.go('/signup')
                          },
                          child: Text(
                            'Sign up',
                            style: GoogleFonts.poppins(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Glowing green gradient button ──
class _GlowButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final bool showArrow;
  final VoidCallback onPressed;

  const _GlowButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (showArrow) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Google Sign-In button ──
class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceMuted),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://www.gstatic.com/images/branding/googleg/1x/googleg_standard_color_128dp.png',
              height: 22,
              width: 22,
              errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24),
            ),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}