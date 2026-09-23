import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../settings/presentation/settings_screen.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
          content: Text(
            message,
            style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 13),
          ),
        ),
      );
    }
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
          decoration: const BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
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
                    context: context,
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleImagePick(context, ref, ImageSource.camera);
                    },
                  ),
                  _buildOptionItem(
                    context: context,
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleImagePick(context, ref, ImageSource.gallery);
                    },
                  ),
                  if (hasImage)
                    _buildOptionItem(
                      context: context,
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
    required BuildContext context,
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
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Profile Header with Gradient
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: AppColors.blastixCoreGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                ),
                // Settings Icon
                Positioned(
                  top: 50,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                ),
                // 2. Profile Photo Avatar
                Positioned(
                  top: 120,
                  child: GestureDetector(
                    onTap: () => _showImagePickerModal(context, ref),
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: AppColors.surfaceNavy,
                            backgroundImage: profileState.imagePath != null &&
                                    File(profileState.imagePath!).existsSync()
                                ? FileImage(File(profileState.imagePath!))
                                : null,
                            child: (profileState.imagePath == null ||
                                    !File(profileState.imagePath!).existsSync())
                                ? const Icon(
                                    Icons.person,
                                    size: 70,
                                    color: AppColors.textMuted,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryNeon,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.background,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryNeon.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 18,
                              color: AppColors.background,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 65),

            // 3. Username and Player ID
            Text(
              'Jonu',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceNavy,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'ID: 529381047',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 4. Stats Section (Matches, Wins, Tournaments)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Matches',
                      '1,240',
                      Icons.sports_esports_rounded,
                      AppColors.primaryNeon,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Wins',
                      '856',
                      Icons.emoji_events_rounded,
                      AppColors.glowSoft,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Rank',
                      'Elite',
                      Icons.stars_rounded,
                      AppColors.glowLight,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Additional Info / Tournaments Played
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Tournaments Won', '12', Icons.workspace_premium_rounded),
                    const Divider(height: 32, color: AppColors.surfaceNavy),
                    _buildDetailRow('K/D Ratio', '2.45', Icons.query_stats_rounded),
                    const Divider(height: 32, color: AppColors.surfaceNavy),
                    _buildDetailRow('Global Rank', '#452', Icons.public_rounded),
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
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
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
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
