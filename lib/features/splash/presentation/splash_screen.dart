import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/splash_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
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

    _glowPulse = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 1. Fetch App Config (Maintenance/Update)
      final repository = ref.read(splashRepositoryProvider);
      final config = await repository.getAppConfig();

      if (config.isMaintenance) {
        debugPrint('Maintenance Mode: ${config.maintenanceMessage}');
      }

      // 2. Check Auth Session
      final isLoggedIn = await repository.checkUserAuth();

      // 3. Navigation Logic
      Timer(const Duration(milliseconds: 2800), () {
        if (mounted) {
          if (isLoggedIn) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      });
    } catch (e) {
      debugPrint('Initialization Error: $e');
      // Fallback navigation if API fails
      Timer(const Duration(milliseconds: 2800), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Center glow effect — neon cyan energy radiate
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
                          AppColors.glowSoft.withValues(alpha: 0.25),
                          AppColors.glowLight.withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // Logo + text center
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: _logoFade.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: ShaderMask(
                          shaderCallback: (bounds) => AppColors.blastixCoreGradient
                              .createShader(bounds),
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
                        shaderCallback: (bounds) => AppColors.blastixCoreGradient
                            .createShader(bounds),
                        child: const Text(
                          'BlastIXEsports',
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
                        child: const LinearProgressIndicator(
                          backgroundColor: AppColors.surfaceNavy,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryNeon,
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