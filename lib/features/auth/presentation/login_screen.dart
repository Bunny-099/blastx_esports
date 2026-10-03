// ignore_for_file: unused_import, unused_element

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pushable_button/pushable_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../../splash/providers/splash_providers.dart';
import '../providers/auth_provider.dart';
import 'ios_waitlist_dialog.dart';
import 'signup_screen.dart';

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
    // final isOtpStep = authState.step == AuthStep.enterOtp;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fullscreen background image ──
          Image.asset(
            'assets/images/login_bg.png',
            fit: BoxFit.fill,
            width: double.infinity,
            height: double.infinity,
          ),

          // ── Login UI ──
          SafeArea(
            child: Align(
              // 🔴 [POSITION CONTROL]: Change 0.4 (-1.0 = top, 0.0 = center, 1.0 = bottom) to move UI up or down
              alignment: const Alignment(0.0, 0.2),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      /*
                      Text(
                        'Login to continue to BlastIXEsports',
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
                            style: GoogleFonts.poppins(color: AppColors.primaryNeon, fontSize: 13),
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
                                      color: AppColors.primaryNeon,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Expanded(child: Divider(color: AppColors.surfaceNavy)),
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
                                const Expanded(child: Divider(color: AppColors.surfaceNavy)),
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
                              onPressed: () async {
                                final navigator = Navigator.of(context);
                                final success = await authNotifier.verifyOtp(_otpController.text.trim());
                                if (!mounted) return;
                                
                                if (success) {
                                  final isIos = ref.read(deviceInfoServiceProvider).isIos;
                                  if (isIos) {
                                    if (context.mounted) {
                                      await IosWaitlistDialog.show(context);
                                    }
                                  } else {
                                    navigator.pushNamedAndRemoveUntil(
                                      '/home',
                                      (route) => false,
                                    );
                                  }
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 28),

                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.surfaceNavy)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('OR',
                                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted)),
                          ),
                          const Expanded(child: Divider(color: AppColors.surfaceNavy)),
                        ],
                      ),

                      const SizedBox(height: 24),
                      */

                      Center(
                        child: Text(
                          'Login to continue to BlastIXEsports',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            shadows: const [
                              Shadow(blurRadius: 6, color: Colors.black, offset: Offset(0, 2)),
                            ],
                          ),
                        ),
                      ),

                      // 🔴 [GAP CONTROL]: Text aur Google button ke beech ki doori
                      const SizedBox(height: 20),

                      if (authState.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            authState.errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(color: AppColors.primaryNeon, fontSize: 13),
                          ),
                        ),

                      // 🔴 [BUTTON MARGIN]: Only button ki top/bottom position badalne ke liye
                      Padding(
                        padding: const EdgeInsets.only(top: 0, bottom: 0),
                        child: _GoogleButton(onTap: () async {
                          final navigator = Navigator.of(context);
                          final success = await authNotifier.continueWithGoogle();
                          if (!mounted) return;

                          if (success) {
                            final isIos = ref.read(deviceInfoServiceProvider).isIos;
                            if (isIos) {
                              if (context.mounted) {
                                await IosWaitlistDialog.show(context);
                              }
                            } else {
                              navigator.pushNamedAndRemoveUntil(
                                '/home',
                                (route) => false,
                              );
                            }
                          }
                        }),
                      ),

                      const SizedBox(height: 16),

                      /*
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ",
                                style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
                            GestureDetector(
                              onTap: () {
                                authNotifier.backToEmailStep();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                                );
                              },
                              child: Text(
                                'Sign up',
                                style: GoogleFonts.poppins(
                                  color: AppColors.primaryNeon,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      */

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glowing neon button ──
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
    return PushableButton(
      onPressed: isLoading ? null : onPressed,
      hslColor: HSLColor.fromColor(AppColors.primaryNeon),
      height: 54,
      elevation: 6,
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.2, color: AppColors.bgNavy),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: GoogleFonts.poppins(
                      color: AppColors.bgNavy,
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
                        color: AppColors.bgNavy.withValues(alpha: 0.2),
                      ),
                      child: const Icon(Icons.arrow_forward,
                          size: 16, color: AppColors.bgNavy),
                    ),
                  ],
                ],
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
    return PushableButton(
      onPressed: onTap,
      hslColor: HSLColor.fromColor(AppColors.surfaceElevated).withLightness(0.2),
      height: 54,
      elevation: 4,
      shadow: BoxShadow(
        color: AppColors.textMuted.withValues(alpha: 0.2),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            'https://www.gstatic.com/images/branding/googleg/1x/googleg_standard_color_128dp.png',
            height: 22,
            width: 22,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.g_mobiledata, size: 24),
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
    );
  }
}
