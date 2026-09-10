import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _glowPulse;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Logo pehle chhota hota hai, phir zoom-in ke saath aata hai (0% - 60% of timeline)
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Glow ring pulse — continuous breathing effect jaisa
    _glowPulse = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Text (app name) logo ke thoda baad fade in hota hai (50% - 80%)
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // 2.8 sec baad navigate — abhi timer, baad me go_router se replace karenge
    Timer(const Duration(milliseconds: 2800), () {
      // TODO: context.go('/login');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Center glow effect — MLBB jaisa energy radiate feel, subtle version
              Center(
                child: Transform.scale(
                  scale: _glowPulse.value,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.25),
                          AppColors.secondary.withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // Logo + text center me
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: _logoFade.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: AppColors.primaryGradient,
                          ).createShader(bounds),
                          child: const Icon(
                            Icons.sports_esports_rounded,
                            size: 84,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Opacity(
                      opacity: _textFade.value,
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: AppColors.primaryGradient,
                        ).createShader(bounds),
                        child: const Text(
                          'BlastXEsports',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Opacity(
                      opacity: _textFade.value,
                      child: Text(
                        'Battle. Compete. Win.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom loading bar
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Opacity(
                    opacity: _textFade.value,
                    child: SizedBox(
                      width: 120,
                      height: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          backgroundColor: AppColors.surfaceMuted,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}