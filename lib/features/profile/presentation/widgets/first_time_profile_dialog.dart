import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pushable_button/pushable_button.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/user_profile_model.dart';
import '../../providers/profile_provider.dart';

class FirstTimeProfileDialog extends ConsumerStatefulWidget {
  final UserProfileModel user;

  const FirstTimeProfileDialog({
    super.key,
    required this.user,
  });

  /// Static method to show the non-dismissible dialog
  static Future<void> show(BuildContext context, UserProfileModel user) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => FirstTimeProfileDialog(user: user),
    );
  }

  @override
  ConsumerState<FirstTimeProfileDialog> createState() => _FirstTimeProfileDialogState();
}

class _FirstTimeProfileDialogState extends ConsumerState<FirstTimeProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final currentName = widget.user.name;
    // Prefill name if available and not 'Gamer'
    _nameController = TextEditingController(
      text: (currentName.isNotEmpty && currentName != 'Gamer') ? currentName : '',
    );
    _phoneController = TextEditingController(
      text: widget.user.phone ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    final success = await ref.read(profileProvider.notifier).updateNameAndPhone(
          name: name,
          phone: phone,
        );

    if (mounted) {
      setState(() => _isSaving = false);

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: AppColors.primaryNeon.withValues(alpha: 0.5),
              ),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.primaryNeon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Profile saved successfully! Welcome aboard, $name 🚀',
                    style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(
              'Failed to save profile. Please try again.',
              style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.primaryNeon.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryNeon.withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- Header Icon & Glow ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryNeon.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppColors.primaryNeon.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryNeon.withValues(alpha: 0.3),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 38,
                      color: AppColors.primaryNeon,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'Complete Profile 🎮',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Please enter your Name and Phone Number to continue to BlastiX Arena.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // --- Name Input ---
                  _buildFieldLabel('Full Name', isRequired: true),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hintText: 'e.g. Rahul Sharma',
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // --- Phone Input ---
                  _buildFieldLabel('Phone Number', isRequired: true),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _phoneController,
                    hintText: '10-digit mobile number',
                    prefixIcon: Icons.phone_android_rounded,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (value.trim().length != 10) {
                        return 'Phone number must be exactly 10 digits';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // --- Save & Continue Button ---
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: PushableButton(
                      onPressed: _isSaving ? null : _handleSave,
                      hslColor: HSLColor.fromColor(AppColors.primaryNeon),
                      height: 52,
                      elevation: 6,
                      child: Center(
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.bgNavy,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Save & Continue',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.bgNavy,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.bgNavy.withValues(alpha: 0.2),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: AppColors.bgNavy,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (isRequired)
            Text(
              ' *',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNeon,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
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
        fillColor: AppColors.surfaceNavy,
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
