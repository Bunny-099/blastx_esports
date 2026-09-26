import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../splash/providers/splash_providers.dart';
import '../../tournaments/data/repositories/tournament_repository.dart';
import '../data/models/user_profile_model.dart';
import '../data/repositories/user_repository.dart';

class ProfileState {
  final UserProfileModel? user;
  final String? localImagePath;
  final bool isLoading;
  final String? errorMessage;

  const ProfileState({
    this.user,
    this.localImagePath,
    this.isLoading = false,
    this.errorMessage,
  });

  ProfileState copyWith({
    UserProfileModel? user,
    String? localImagePath,
    bool? isLoading,
    String? errorMessage,
    bool clearLocalImage = false,
  }) {
    return ProfileState(
      user: user ?? this.user,
      localImagePath: clearLocalImage ? null : (localImagePath ?? this.localImagePath),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
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
    String? initialLocalPath;
    if (savedPath != null && savedPath.isNotEmpty) {
      final file = File(savedPath);
      if (file.existsSync()) {
        initialLocalPath = savedPath;
      }
    }

    // Load profile from API on initial build
    Future.microtask(() => loadProfile());

    return ProfileState(
      localImagePath: initialLocalPath,
      isLoading: true,
    );
  }

  /// Load user profile from Backend API
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final storage = ref.read(storageServiceProvider);

    try {
      final repo = ref.read(userRepositoryProvider);
      var user = await repo.getUserProfile();
      
      // Sync real-time count of tournaments registered by this user
      try {
        final tournamentRepo = ref.read(tournamentRepositoryProvider);
        final myTournaments = await tournamentRepo.getMyTournaments();
        if (myTournaments.isNotEmpty && myTournaments.length > user.tournamentsPlayed) {
          user = user.copyWith(tournamentsPlayed: myTournaments.length);
        }
      } catch (e) {
        debugPrint('Failed to sync myTournaments count: $e');
      }

      // Save user JSON locally for offline access
      await storage.saveString('user_profile_data', jsonEncode(user.toJson()));

      state = state.copyWith(
        user: user,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      debugPrint('ProfileNotifier loadProfile error: $e');
      debugPrint(stackTrace.toString());

      // Fallback: Check if we have saved user profile data locally (e.g. from Google Sign-In)
      final savedUserJson = storage.getString('user_profile_data');
      if (savedUserJson != null && savedUserJson.isNotEmpty) {
        try {
          final Map<String, dynamic> userMap = jsonDecode(savedUserJson);
          final cachedUser = UserProfileModel.fromJson(userMap);
          state = state.copyWith(
            user: cachedUser,
            isLoading: false,
          );
          return;
        } catch (_) {}
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load profile. Tap to retry.',
      );
    }
  }

  /// Update user name / tagline on API
  Future<bool> updateName(String newName) async {
    try {
      final repo = ref.read(userRepositoryProvider);
      final updatedUser = await repo.updateProfile(name: newName);
      state = state.copyWith(user: updatedUser);
      return true;
    } catch (e) {
      debugPrint('ProfileNotifier updateName error: $e');
      return false;
    }
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

        try {
          final repo = ref.read(userRepositoryProvider);
          final updatedUser = await repo.updateProfile(profilePic: pickedFile.path);
          state = state.copyWith(
            user: updatedUser,
            localImagePath: pickedFile.path,
            isLoading: false,
          );
        } catch (_) {
          state = state.copyWith(
            localImagePath: pickedFile.path,
            isLoading: false,
          );
        }
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
    state = state.copyWith(clearLocalImage: true, isLoading: false);
  }
}
