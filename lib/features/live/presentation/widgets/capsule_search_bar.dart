import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class CapsuleSearchBar extends StatelessWidget {
  const CapsuleSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 52, // Same as _kSearchBarHeight
          decoration: BoxDecoration(
            gradient: AppColors.glassFill,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 18),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.fireGradient.createShader(bounds),
                child: const Icon(Icons.search_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: AppTextStyles.bodyLg,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search tournaments, games...',
                    hintStyle: AppTextStyles.bodyMd,
                    isCollapsed: true,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}
