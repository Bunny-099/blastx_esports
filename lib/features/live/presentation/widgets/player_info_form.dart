import 'package:blastx_esports/core/theme/app_text_styles.dart';
import 'package:blastx_esports/shared/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';

/// Free Fire player details (not stored on the user account yet).
class PlayerInfoForm extends StatelessWidget {
  const PlayerInfoForm({
    super.key,
    required this.nameController,
    required this.ignController,
    required this.uidController,
  });

  final TextEditingController nameController;
  final TextEditingController ignController;
  final TextEditingController uidController;

  /// Returns the first validation error, or null when valid.
  static String? validate(String name, String ign, String uid) {
    if (name.trim().length < 2) return 'Enter your player name.';
    if (ign.trim().length < 2) return 'Enter your Free Fire IGN.';
    if (!RegExp(r'^\d{8,12}$').hasMatch(uid.trim())) {
      return 'Free Fire UID must be 8–12 digits.';
    }
    return null;
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 14),
    child: Text(t, style: AppTextStyles.overline),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('PLAYER NAME'),
        CustomTextField(controller: nameController, hintText: 'Your name', maxLength: 30),
        _label('FREE FIRE IGN'),
        CustomTextField(controller: ignController, hintText: 'In-game name', maxLength: 30),
        _label('FREE FIRE UID'),
        CustomTextField(
            controller: uidController,
            hintText: 'e.g. 123456789',
            keyboardType: TextInputType.number,
            maxLength: 12),
      ],
    );
  }
}