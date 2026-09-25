import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../settings/presentation/settings_screen.dart';
import '../providers/profile_provider.dart';

/// Profile screen — "Hero Profile" concept (01)
/// Hero banner + neon avatar ring + level/XP bar + stats + actions.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // ---- Static player data (replace with provider data when available) ----
  static const String _username = 'kushal';
  static const String _handle = '@kushal';
  static const String _playerId = '529381047';
  static const String _quote = 'Discipline creates champions.';
  static const int _level = 12;
  static const int _xp = 320;
  static const int _xpMax = 500;

  // ---------------------------------------------------------------------
  // Image picking (logic unchanged)
  // ---------------------------------------------------------------------
  void _handleImagePick(BuildContext context, WidgetRef ref, ImageSource source) async {
    final error = await ref.read(profileProvider.notifier).pickImage(source);
    if (error != null && context.mounted) {
      final isMissingPlugin = error.contains('MissingPluginException') ||
          error.contains('No implementation found');
      final isPermissionDenied = error.contains('photo_access_denied') ||
          error.contains('camera_access_denied') ||
          error.contains('permission');

      String message = 'Unable to pick image: $error';
      if (isMissingPlugin) {
        message = 'Please STOP & RESTART the app from Android Studio to register the image picker plugin.';
      } else if (isPermissionDenied) {
        message = 'Permission denied. Please allow Photos/Camera permission in Settings.';
      }
      _showSnack(context, message);
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.primaryNeon.withValues(alpha: 0.3)),
        ),
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 13),
        ),
      ),
    );
  }

  void _showImagePickerModal(BuildContext context, WidgetRef ref) {
    final profileState = ref.read(profileProvider);
    final hasImage = profileState.imagePath != null &&
        File(profileState.imagePath!).existsSync();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border(
              top: BorderSide(
                color: AppColors.primaryNeon.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Profile Photo',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionItem(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleImagePick(context, ref, ImageSource.camera);
                    },
                  ),
                  _buildOptionItem(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleImagePick(context, ref, ImageSource.gallery);
                    },
                  ),
                  if (hasImage)
                    _buildOptionItem(
                      icon: Icons.delete_outline_rounded,
                      label: 'Remove',
                      isDestructive: true,
                      onTap: () async {
                        Navigator.pop(ctx);
                        await ref.read(profileProvider.notifier).removeImage();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.redAccent : AppColors.primaryNeon;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceNavy,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDestructive ? Colors.redAccent : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final topPad = MediaQuery.of(context).padding.top;

    final hasImage = profileState.imagePath != null &&
        File(profileState.imagePath!).existsSync();

    const double heroHeight = 250;
    const double avatarOverhang = 58;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ------------------------------------------------------------
            // 1. HERO BANNER
            // ------------------------------------------------------------
            Stack(
              clipBehavior: Clip.none,
              children: [
                _buildHeroBanner(heroHeight),

                // Settings (glass button)
                Positioned(
                  top: topPad + 10,
                  right: 16,
                  child: _glassIconButton(
                    icon: Icons.settings_rounded,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                ),

                // Avatar (overlaps banner)
                Positioned(
                  left: 20,
                  bottom: -avatarOverhang,
                  child: GestureDetector(
                    onTap: () => _showImagePickerModal(context, ref),
                    child: _buildAvatar(hasImage, profileState.imagePath),
                  ),
                ),
              ],
            ),

            // ------------------------------------------------------------
            // 2. NAME / HANDLE beside avatar
            // ------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(20 + 116 + 14, 12, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.3,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded,
                            color: AppColors.primaryNeon, size: 20),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        Text(
                          _handle,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryNeon,
                          ),
                        ),
                        Text(
                          '#BlastixFamily',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ------------------------------------------------------------
            // 3. QUOTE
            // ------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildQuoteCard(),
            ),

            const SizedBox(height: 14),

            // ------------------------------------------------------------
            // 4. INFO ROW (location / member since)
            // ------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildInfoRow(),
            ),

            const SizedBox(height: 14),

            // ------------------------------------------------------------
            // 5. LEVEL + XP
            // ------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildLevelBar(),
            ),

            const SizedBox(height: 16),

            // ------------------------------------------------------------
            // 6. STATS
            // ------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _buildStatCard('Matches', '1,240', Icons.sports_esports_rounded, AppColors.primaryNeon)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatCard('Wins', '856', Icons.emoji_events_rounded, AppColors.glowSoft)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatCard('K/D', '2.45', Icons.query_stats_rounded, AppColors.glowLight)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatCard('Global', '#452', Icons.public_rounded, AppColors.primaryNeon)),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ------------------------------------------------------------
            // 7. ACTION BUTTONS
            // ------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildOutlineButton(
                      label: 'Edit Profile',
                      icon: Icons.edit_rounded,
                      onTap: () => _showImagePickerModal(context, ref),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNeonButton(
                      label: 'Share Profile',
                      icon: Icons.ios_share_rounded,
                      onTap: () async {
                        await Clipboard.setData(
                          const ClipboardData(text: 'Blastix Arena • $_username • ID: $_playerId'),
                        );
                        if (context.mounted) {
                          _showSnack(context, 'Profile link copied to clipboard');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ------------------------------------------------------------
            // 8. DETAILS CARD
            // ------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: _cardDecoration(radius: 24),
                child: Column(
                  children: [
                    _buildDetailRow('Tournaments Won', '12', Icons.workspace_premium_rounded),
                    const Divider(height: 30, color: AppColors.surfaceNavy),
                    _buildDetailRow('Rank', 'Elite', Icons.stars_rounded),
                    const Divider(height: 30, color: AppColors.surfaceNavy),
                    _buildDetailRow('Player ID', _playerId, Icons.badge_rounded),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Hero banner
  // ---------------------------------------------------------------------
  Widget _buildHeroBanner(double height) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Base gradient
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.blastixCoreGradient),
            ),
            // Dark vignette so text/avatar pop
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
            // Diagonal neon streaks
            CustomPaint(painter: _StreaksPainter(AppColors.primaryNeon)),
            // Big faded emblem
            Positioned(
              right: -30,
              bottom: -20,
              child: Icon(
                Icons.shield_rounded,
                size: 210,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            // Slanted tagline
            Positioned(
              right: 22,
              top: 84,
              child: Transform.rotate(
                angle: -math.pi / 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final word in const ['PLAY.', 'IMPROVE.', 'BELONG.'])
                      Text(
                        word,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          height: 1.05,
                          color: AppColors.primaryNeon.withValues(alpha: 0.9),
                          shadows: [
                            Shadow(
                              color: AppColors.primaryNeon.withValues(alpha: 0.6),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Bottom neon hairline
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.primaryNeon.withValues(alpha: 0.9),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassIconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Avatar with neon ring
  // ---------------------------------------------------------------------
  Widget _buildAvatar(bool hasImage, String? imagePath) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(
              colors: [
                AppColors.primaryNeon,
                AppColors.glowSoft,
                AppColors.glowLight,
                AppColors.primaryNeon,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryNeon.withValues(alpha: 0.5),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.surfaceNavy,
              backgroundImage: hasImage ? FileImage(File(imagePath!)) : null,
              child: !hasImage
                  ? const Icon(Icons.person, size: 64, color: AppColors.textMuted)
                  : null,
            ),
          ),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primaryNeon,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.background, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryNeon.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.camera_alt_rounded, size: 15, color: AppColors.background),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------
  BoxDecoration _cardDecoration({double radius = 18}) {
    return BoxDecoration(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.primaryNeon.withValues(alpha: 0.18)),
      boxShadow: [
        BoxShadow(
          color: AppColors.primaryNeon.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildQuoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceNavy.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: AppColors.primaryNeon, width: 3),
        ),
      ),
      child: Text(
        '“$_quote”',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildInfoRow() {
    Widget item(IconData icon, String text) {
      return Flexible(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryNeon),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: _cardDecoration(radius: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          item(Icons.location_on_outlined, 'India'),
          item(Icons.place_outlined, 'Bangalore, KA'),
          item(Icons.calendar_month_outlined, 'Since Jan 2024'),
        ],
      ),
    );
  }

  Widget _buildLevelBar() {
    final progress = (_xp / _xpMax).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _cardDecoration(radius: 16),
      child: Row(
        children: [
          Text(
            'Lv. $_level',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryNeon,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.surfaceNavy,
                borderRadius: BorderRadius.circular(10),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [AppColors.glowSoft, AppColors.primaryNeon],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryNeon.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '$_xp / $_xpMax XP',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeonButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AppColors.primaryNeon, AppColors.glowSoft],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryNeon.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.background),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.background,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlineButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.surfaceNavy.withValues(alpha: 0.6),
          border: Border.all(
            color: AppColors.primaryNeon.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.primaryNeon),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceNavy,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryNeon.withValues(alpha: 0.15),
            ),
          ),
          child: Icon(icon, color: AppColors.primaryNeon, size: 20),
        ),
        const SizedBox(width: 16),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryNeon,
          ),
        ),
      ],
    );
  }
}

/// Diagonal neon streaks for the hero banner background.
class _StreaksPainter extends CustomPainter {
  final Color color;
  _StreaksPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final offsets = [0.15, 0.32, 0.5, 0.68, 0.86];
    for (var i = 0; i < offsets.length; i++) {
      paint.color = color.withValues(alpha: 0.05 + (i % 2) * 0.07);
      final x = size.width * offsets[i];
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height * 0.6, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StreaksPainter oldDelegate) => oldDelegate.color != color;
}