import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:blastix_esports/core/theme/app_colors.dart';
import 'package:blastix_esports/features/profile/providers/profile_provider.dart';
import 'package:blastix_esports/shared/widgets/custom_button.dart';
import 'package:blastix_esports/shared/widgets/custom_textfield.dart';

/// Post-login required Profile Setup Screen for entering Profile Name & Phone Number.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(profileProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.length < 2) {
      setState(() => _error = 'Name must be at least 2 characters.');
      return;
    }

    if (phone.length < 7) {
      setState(() => _error = 'Please enter a valid phone number.');
      return;
    }

    setState(() {
      _error = null;
      _isSaving = true;
    });

    final success = await ref
        .read(profileProvider.notifier)
        .updateNameAndPhone(name: name, phone: phone);

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );
    } else {
      setState(() {
        _error = 'Failed to update profile. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'COMPLETE YOUR PROFILE',
            style: GoogleFonts.syne(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNeon,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNeon.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primaryNeon.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 48,
                        color: AppColors.primaryNeon,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome to BlastiX Arena!',
                    style: GoogleFonts.syne(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Please set your profile name and phone number to continue.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Name Field
                  Text(
                    'PROFILE NAME *',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _nameController,
                    hintText: 'Enter your gamer name',
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 20),

                  // Phone Field
                  Text(
                    'PHONE NUMBER *',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _phoneController,
                    hintText: 'e.g. 9876543210',
                    keyboardType: TextInputType.phone,
                    maxLength: 12,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  ],

                  const SizedBox(height: 36),

                  CustomButton(
                    text: 'CONTINUE',
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
