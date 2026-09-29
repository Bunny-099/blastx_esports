import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../splash/providers/splash_providers.dart';
import '../../tournaments/data/repositories/tournament_repository.dart';
import '../data/models/game_profile_model.dart';
import '../data/models/rank_model.dart';
import '../data/models/user_profile_model.dart';
import '../data/repositories/user_repository.dart';
import '../domain/rank_system.dart';

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

      // Fallback: Check if we have saved user profile data locally
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

  /// Safely adds claimed XP to total user XP, recalculates rank, persists locally, and returns [RankChangeResult].
  Future<RankChangeResult?> addXP(int amount) async {
    if (amount <= 0) return null;
    final currentUser = state.user;
    if (currentUser == null) return null;

    final result = RankSystem.calculateXPClaim(
      currentXP: currentUser.xp,
      claimedXP: amount,
    );

    final updatedUser = currentUser.copyWith(
      xp: result.totalXP,
      rank: result.currentRank.number,
    );

    // Save user JSON locally
    try {
      final storage = ref.read(storageServiceProvider);
      await storage.saveString('user_profile_data', jsonEncode(updatedUser.toJson()));
    } catch (e) {
      debugPrint('Error persisting user_profile_data after claiming XP: $e');
    }

    state = state.copyWith(user: updatedUser);
    return result;
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

  /// Update full profile: name, profile image path, Free Fire UID, and IGN
  Future<bool> updateFullProfile({
    required String name,
    required String freeFireUid,
    String? inGameName,
    String? localImagePath,
  }) async {
    state = state.copyWith(isLoading: true);
    final storage = ref.read(storageServiceProvider);

    try {
      final repo = ref.read(userRepositoryProvider);

      if (localImagePath != null && localImagePath.isNotEmpty) {
        await storage.saveString(_profileImageKey, localImagePath);
      }

      final updatedUser = await repo.updateFullUserProfile(
        name: name,
        profilePic: localImagePath ?? state.user?.profilePic,
        freeFireUid: freeFireUid,
        inGameName: inGameName,
      );

      // Persist locally
      await storage.saveString('user_profile_data', jsonEncode(updatedUser.toJson()));

      state = state.copyWith(
        user: updatedUser,
        localImagePath: localImagePath ?? state.localImagePath,
        isLoading: false,
      );
      return true;
    } catch (e, stackTrace) {
      debugPrint('ProfileNotifier updateFullProfile error: $e');
      debugPrint(stackTrace.toString());

      // Fallback local update so user changes take immediate visual effect
      if (state.user != null) {
        final currentGp = state.user!.gameProfile;
        final newGp = GameProfileModel(
          id: currentGp?.id ?? '',
          gameSlug: 'free_fire',
          gameName: 'Free Fire',
          inGameUid: freeFireUid,
          inGameName: (inGameName != null && inGameName.isNotEmpty) ? inGameName : name,
        );
        final fallbackUser = state.user!.copyWith(
          name: name,
          profilePic: localImagePath ?? state.user!.profilePic,
          gameProfile: newGp,
        );
        await storage.saveString('user_profile_data', jsonEncode(fallbackUser.toJson()));

        state = state.copyWith(
          user: fallbackUser,
          localImagePath: localImagePath ?? state.localImagePath,
          isLoading: false,
        );
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update profile. Please try again.',
      );
      return false;
    }
  }
}
