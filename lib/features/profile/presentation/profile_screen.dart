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

/// Profile screen — "Hero Profile" concept — Real-time API connected
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // ---------------------------------------------------------------------
  // Image picking
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
    final localPath = profileState.localImagePath;
    final userPic = profileState.user?.profilePic;
    final hasImage = (localPath != null && File(localPath).existsSync()) ||
        (userPic != null && userPic.isNotEmpty);

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
    final user = profileState.user;
    final topPad = MediaQuery.of(context).padding.top;

    final username = (user?.name != null && user!.name.isNotEmpty)
        ? user.name
        : 'Gamer';
    final playerId = (user?.gameProfile?.inGameUid != null && user!.gameProfile!.inGameUid.isNotEmpty)
        ? user.gameProfile!.inGameUid
        : (user?.id != null && user!.id.isNotEmpty ? user.id : 'N/A');
    final userEmail = user?.email ?? '';
    final userRole = user?.role ?? 'Player';
    final gameName = user?.gameProfile?.gameName ?? 'Free Fire';

    const double heroHeight = 250;
    const double avatarOverhang = 58;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primaryNeon,
        backgroundColor: AppColors.surfaceElevated,
        onRefresh: () => ref.read(profileProvider.notifier).loadProfile(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                      child: _buildAvatar(profileState),
                    ),
                  ),
                ],
              ),

              // ------------------------------------------------------------
              // 2. NAME + EDITABLE TAGLINE beside avatar
              // ------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(20 + 116 + 14, 12, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.3,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _EditableTagline(
                        initialText: username,
                        onSave: (newName) async {
                          if (newName.isNotEmpty) {
                            await ref.read(profileProvider.notifier).updateName(newName);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Loading / Error Banner
              if (profileState.isLoading && user == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(color: AppColors.primaryNeon),
                )
              else if (profileState.errorMessage != null && user == null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            profileState.errorMessage!,
                            style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () => ref.read(profileProvider.notifier).loadProfile(),
                          child: Text(
                            'Retry',
                            style: GoogleFonts.poppins(color: AppColors.primaryNeon, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ),
                ),

              // ------------------------------------------------------------
              // 3. STATS
              // ------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: _buildStatCard('Game', gameName, Icons.sports_esports_rounded, AppColors.primaryNeon)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatCard('Role', userRole, Icons.emoji_events_rounded, AppColors.glowSoft)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatCard('Status', user?.isActive == true ? 'Active' : 'Inactive', Icons.verified_user_rounded, AppColors.glowLight)),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ------------------------------------------------------------
              // 4. ACTION BUTTONS
              // ------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildOutlineButton(
                        label: 'Edit Photo',
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
                            ClipboardData(text: 'Blastix Arena • $username • ID: $playerId'),
                          );
                          if (context.mounted) {
                            _showSnack(context, 'Profile details copied to clipboard!');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ------------------------------------------------------------
              // 5. DETAILS CARD
              // ------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: _cardDecoration(radius: 24),
                  child: Column(
                    children: [
                      _buildDetailRow('Email', userEmail.isNotEmpty ? userEmail : 'Not set', Icons.email_rounded),
                      const Divider(height: 30, color: AppColors.surfaceNavy),
                      _buildDetailRow('In-Game Name', user?.gameProfile?.inGameName ?? 'N/A', Icons.sports_esports_rounded),
                      const Divider(height: 30, color: AppColors.surfaceNavy),
                      _buildDetailRow('Player UID / ID', playerId, Icons.badge_rounded),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
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
            // Hex grid overlay for a gamer feel
            CustomPaint(painter: _HexGridPainter(AppColors.primaryNeon)),
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
  Widget _buildAvatar(ProfileState profileState) {
    final localPath = profileState.localImagePath;
    final userPic = profileState.user?.profilePic;

    ImageProvider? imageProvider;
    if (localPath != null && File(localPath).existsSync()) {
      imageProvider = FileImage(File(localPath));
    } else if (userPic != null && userPic.isNotEmpty) {
      if (userPic.startsWith('http://') || userPic.startsWith('https://')) {
        imageProvider = NetworkImage(userPic);
      } else if (File(userPic).existsSync()) {
        imageProvider = FileImage(File(userPic));
      }
    }

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
              backgroundImage: imageProvider,
              child: imageProvider == null
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15,
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNeon,
            ),
          ),
        ),
      ],
    );
  }
}

/// Inline-editable tagline/name shown under the avatar.
/// Tap the text to edit it; tap away or hit enter to save.
class _EditableTagline extends StatefulWidget {
  final String initialText;
  final ValueChanged<String>? onSave;
  const _EditableTagline({required this.initialText, this.onSave});

  @override
  State<_EditableTagline> createState() => _EditableTaglineState();
}

class _EditableTaglineState extends State<_EditableTagline> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _save();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _EditableTagline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && widget.initialText != oldWidget.initialText) {
      _controller.text = widget.initialText;
    }
  }

  void _save() {
    setState(() => _isEditing = false);
    if (widget.onSave != null) {
      widget.onSave!(_controller.text.trim());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.poppins(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryNeon,
    );

    if (_isEditing) {
      return SizedBox(
        width: 220,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          maxLines: 1,
          maxLength: 40,
          style: baseStyle,
          cursorColor: AppColors.primaryNeon,
          decoration: InputDecoration(
            isDense: true,
            counterText: '',
            hintText: 'Type your name...',
            hintStyle: baseStyle.copyWith(color: AppColors.textMuted),
            contentPadding: EdgeInsets.zero,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryNeon.withValues(alpha: 0.4)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryNeon),
            ),
          ),
          onSubmitted: (_) {
            _focusNode.unfocus();
            _save();
          },
        ),
      );
    }

    final hasText = _controller.text.trim().isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _isEditing = true),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              hasText ? _controller.text : 'Edit name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: hasText
                  ? baseStyle
                  : baseStyle.copyWith(
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
            ),
          ),
          const SizedBox(width: 5),
          Icon(
            Icons.edit_rounded,
            size: 12,
            color: AppColors.primaryNeon.withValues(alpha: 0.7),
          ),
        ],
      ),
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

/// Faint hex-grid overlay for an extra gamified texture on the banner.
class _HexGridPainter extends CustomPainter {
  final Color color;
  _HexGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const double hexSize = 22;
    final double hexWidth = math.sqrt(3) * hexSize;
    final double hexHeight = 2 * hexSize;
    final double vertSpacing = hexHeight * 0.75;

    for (double row = -1; row * vertSpacing < size.height + hexHeight; row++) {
      final bool offsetRow = row.toInt() % 2 != 0;
      for (double col = -1; col * hexWidth < size.width + hexWidth; col++) {
        final double cx = col * hexWidth + (offsetRow ? hexWidth / 2 : 0);
        final double cy = row * vertSpacing;
        _drawHex(canvas, paint, Offset(cx, cy), hexSize);
      }
    }
  }

  void _drawHex(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 6;
      final point = Offset(
        center.dx + size * math.cos(angle),
        center.dy + size * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HexGridPainter oldDelegate) => oldDelegate.color != color;
}
