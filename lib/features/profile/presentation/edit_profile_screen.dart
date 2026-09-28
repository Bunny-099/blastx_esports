import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _ffUidController;
  late final TextEditingController _ffIgnController;

  String? _selectedImagePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profileState = ref.read(profileProvider);
    final user = profileState.user;

    _nameController = TextEditingController(text: user?.name ?? '');
    _ffUidController = TextEditingController(
      text: user?.gameProfile?.inGameUid ?? '',
    );
    _ffIgnController = TextEditingController(
      text: user?.gameProfile?.inGameName ?? '',
    );

    _selectedImagePath = profileState.localImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ffUidController.dispose();
    _ffIgnController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Image Picking
  // ---------------------------------------------------------------------
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() {
          _selectedImagePath = file.path;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to pick image: $e', isError: true);
      }
    }
  }

  void _showImagePickerModal() {
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
                'Change Profile Photo',
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
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildOptionItem(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  if (_selectedImagePath != null && _selectedImagePath!.isNotEmpty)
                    _buildOptionItem(
                      icon: Icons.delete_outline_rounded,
                      label: 'Remove',
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _selectedImagePath = null;
                        });
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
  // Save Logic
  // ---------------------------------------------------------------------
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final ffUid = _ffUidController.text.trim();
    final ffIgn = _ffIgnController.text.trim();

    final success = await ref.read(profileProvider.notifier).updateFullProfile(
          name: name,
          freeFireUid: ffUid,
          inGameName: ffIgn.isNotEmpty ? ffIgn : name,
          localImagePath: _selectedImagePath,
        );

    if (mounted) {
      setState(() => _isSaving = false);

      if (success) {
        _showSnack('Profile updated successfully!');
        Navigator.pop(context);
      } else {
        _showSnack('Failed to update profile. Please try again.', isError: true);
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.redAccent.shade700 : AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isError
                ? Colors.redAccent
                : AppColors.primaryNeon.withValues(alpha: 0.5),
          ),
        ),
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 13),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // UI Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final user = profileState.user;

    ImageProvider? imageProvider;
    if (_selectedImagePath != null && File(_selectedImagePath!).existsSync()) {
      imageProvider = FileImage(File(_selectedImagePath!));
    } else if (user?.profilePic != null && user!.profilePic!.isNotEmpty) {
      if (user.profilePic!.startsWith('http://') || user.profilePic!.startsWith('https://')) {
        imageProvider = NetworkImage(user.profilePic!);
      } else if (File(user.profilePic!).existsSync()) {
        imageProvider = FileImage(File(user.profilePic!));
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceElevated,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.primaryNeon.withValues(alpha: 0.2),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ---------------------------------------------------------
                // 1. Profile Photo Picker
                // ---------------------------------------------------------
                Center(
                  child: Stack(
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
                              color: AppColors.primaryNeon.withValues(alpha: 0.35),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor: AppColors.surfaceNavy,
                            backgroundImage: imageProvider,
                            child: imageProvider == null
                                ? const Icon(
                                    Icons.person_rounded,
                                    size: 60,
                                    color: AppColors.textMuted,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: InkWell(
                          onTap: _showImagePickerModal,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryNeon,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.background,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryNeon.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: AppColors.background,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _showImagePickerModal,
                  icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primaryNeon),
                  label: Text(
                    'Change Profile Photo',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryNeon,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ---------------------------------------------------------
                // 2. Full Name Input
                // ---------------------------------------------------------
                _buildFieldLabel('Full Name', isRequired: true),
                const SizedBox(height: 8),
                _buildGamerTextField(
                  controller: _nameController,
                  hintText: 'Enter your full name',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ---------------------------------------------------------
                // 3. Free Fire UID Input
                // ---------------------------------------------------------
                _buildFieldLabel('Free Fire UID', isRequired: true, badge: 'REQUIRED FOR TOURNAMENTS'),
                const SizedBox(height: 8),
                _buildGamerTextField(
                  controller: _ffUidController,
                  hintText: 'e.g. 1234567890',
                  prefixIcon: Icons.sports_esports_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your Free Fire UID';
                    }
                    if (value.trim().length < 6) {
                      return 'Free Fire UID must be at least 6 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '⚡ Found in Free Fire Profile tab. Required to join tournaments.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ---------------------------------------------------------
                // 4. Free Fire In-Game Name (IGN) Input
                // ---------------------------------------------------------
                _buildFieldLabel('Free Fire In-Game Name (IGN)'),
                const SizedBox(height: 8),
                _buildGamerTextField(
                  controller: _ffIgnController,
                  hintText: 'e.g. BLASTIX_PRO_99',
                  prefixIcon: Icons.badge_outlined,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(30),
                  ],
                ),

                const SizedBox(height: 36),

                // ---------------------------------------------------------
                // 5. Save Button
                // ---------------------------------------------------------
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                      shadowColor: AppColors.primaryNeon.withValues(alpha: 0.4),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryNeon, AppColors.glowSoft],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: AppColors.background,
                                  strokeWidth: 2.8,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.background,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Save Changes',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.background,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------
  Widget _buildFieldLabel(String label, {bool isRequired = false, String? badge}) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (isRequired)
          Text(
            ' *',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNeon,
            ),
          ),
        if (badge != null) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryNeon.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.primaryNeon.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: Text(
              badge,
              style: GoogleFonts.poppins(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNeon,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGamerTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.poppins(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: AppColors.primaryNeon,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(
          color: AppColors.textMuted,
          fontSize: 13,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: AppColors.primaryNeon,
          size: 20,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.primaryNeon.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.primaryNeon.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primaryNeon,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.8,
          ),
        ),
        errorStyle: GoogleFonts.poppins(
          color: Colors.redAccent,
          fontSize: 11,
        ),
      ),
    );
  }
}
