import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../splash/providers/splash_providers.dart';

class ProfileState {
  final String? imagePath;
  final bool isLoading;

  const ProfileState({
    this.imagePath,
    this.isLoading = false,
  });

  ProfileState copyWith({
    String? imagePath,
    bool? isLoading,
    bool clearImage = false,
  }) {
    return ProfileState(
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);

class ProfileNotifier extends Notifier<ProfileState> {
  static const String _profileImageKey = 'user_profile_image_path';
  final ImagePicker _picker = ImagePicker();

  @override
  ProfileState build() {
    final storage = ref.watch(storageServiceProvider);
    final savedPath = storage.getString(_profileImageKey);
    if (savedPath != null && savedPath.isNotEmpty) {
      final file = File(savedPath);
      if (file.existsSync()) {
        return ProfileState(imagePath: savedPath);
      }
    }
    return const ProfileState();
  }

  /// Returns null on success or cancellation, or error message String on failure.
  Future<String?> pickImage(ImageSource source) async {
    try {
      state = state.copyWith(isLoading: true);
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final storage = ref.read(storageServiceProvider);
        await storage.saveString(_profileImageKey, pickedFile.path);
        state = ProfileState(imagePath: pickedFile.path, isLoading: false);
        return null;
      } else {
        state = state.copyWith(isLoading: false);
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('ProfileNotifier pickImage error: $e');
      debugPrint(stackTrace.toString());
      state = state.copyWith(isLoading: false);
      return e.toString();
    }
  }

  Future<void> removeImage() async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveString(_profileImageKey, '');
    state = const ProfileState(imagePath: null, isLoading: false);
  }
}
