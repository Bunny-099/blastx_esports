import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/profile/providers/profile_provider.dart';
import '../../../features/splash/providers/splash_providers.dart';
import '../data/models/squad_invitation_model.dart';
import '../data/models/squad_model.dart';
import '../data/repositories/mock_squad_repository.dart';
import '../data/repositories/squad_repository.dart';

/// Toggle Flag to switch between Mock and Real Squad Repository.
/// Set to false so real backend API integration is active by default.
final useMockSquadRepositoryProvider = StateProvider<bool>((ref) => false);

/// Single Instance of MockSquadRepository so state persists during app runtime when mock testing
final mockSquadRepositoryProvider = Provider<MockSquadRepository>((ref) {
  return MockSquadRepository();
});

/// Squad Repository Provider
final squadRepositoryProvider = Provider<SquadRepository>((ref) {
  final useMock = ref.watch(useMockSquadRepositoryProvider);
  if (useMock) {
    return ref.watch(mockSquadRepositoryProvider);
  } else {
    return RealSquadRepository(ref.watch(apiClientProvider));
  }
});

/// Squad UI State
class SquadState {
  final SquadModel? squad;
  final List<SquadInvitationModel> pendingInvitations;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final String viewerUserId;

  const SquadState({
    this.squad,
    this.pendingInvitations = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.viewerUserId = 'user_001',
  });

  bool get hasSquad => squad != null;
  bool get isLeader => squad != null && squad!.isOwner(viewerUserId);
  bool get isOwner => isLeader;
  bool get isMember => squad != null && squad!.isMember(viewerUserId);

  SquadState copyWith({
    SquadModel? squad,
    bool clearSquad = false,
    List<SquadInvitationModel>? pendingInvitations,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
    String? viewerUserId,
  }) {
    return SquadState(
      squad: clearSquad ? null : (squad ?? this.squad),
      pendingInvitations: pendingInvitations ?? this.pendingInvitations,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      viewerUserId: viewerUserId ?? this.viewerUserId,
    );
  }
}

/// Squad Notifier for State Management
class SquadNotifier extends Notifier<SquadState> {
  SquadRepository get _repo => ref.read(squadRepositoryProvider);

  @override
  SquadState build() {
    // Resolve logged in viewer user ID if available
    final profileState = ref.watch(profileProvider);
    final userId = profileState.user?.id ?? 'user_001';

    final initialState = SquadState(viewerUserId: userId);

    // Eagerly load squad on build
    Future.microtask(() => loadSquad());

    return initialState;
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  Future<void> loadSquad() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final s = await _repo.getMySquad();
      final invites = await _repo.getPendingInvitations();
      state = state.copyWith(
        squad: s,
        clearSquad: s == null,
        pendingInvitations: invites,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> createOrSaveSquadFromRoster({
    String? squadName,
    String? tag,
    List<SquadMemberModel>? members,
    SquadRole ownerRole = SquadRole.leader,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final now = DateTime.now();
      SquadModel? squadPayload;
      if (squadName != null && members != null) {
        squadPayload = SquadModel(
          id: 'squad_${now.millisecondsSinceEpoch}',
          name: squadName,
          tag: tag ?? '',
          leaderId: state.viewerUserId,
          ownerRole: ownerRole,
          members: members,
          createdAt: now,
        );
      }

      final saved = await _repo.createOrSaveSquad(squadPayload);
      state = state.copyWith(
        squad: saved,
        isLoading: false,
        successMessage: 'Persistent squad saved successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> removeMember(String userId) async {
    if (state.squad == null) return false;
    if (!state.isOwner) {
      state = state.copyWith(errorMessage: 'Only the squad leader/manager can remove members.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repo.removeMember(state.squad!.id, userId);
      state = state.copyWith(
        squad: updated,
        isLoading: false,
        successMessage: 'Member removed from squad.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> transferLeadership(String newLeaderId) async {
    if (state.squad == null) return false;
    if (!state.isOwner) {
      state = state.copyWith(errorMessage: 'Only the current leader/manager can transfer ownership.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repo.transferLeadership(state.squad!.id, newLeaderId);
      state = state.copyWith(
        squad: updated,
        isLoading: false,
        successMessage: 'Leadership/Ownership transferred successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> swapPlayers(String mainUserId, String subUserId) async {
    if (state.squad == null) return false;
    if (!state.isOwner) {
      state = state.copyWith(errorMessage: 'Only the squad leader/manager can swap players.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repo.swapPlayers(state.squad!.id, mainUserId, subUserId);
      state = state.copyWith(
        squad: updated,
        isLoading: false,
        successMessage: 'Roster swapped successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> updateMemberRole(String userId, SquadRosterType newRosterType) async {
    if (state.squad == null) return false;
    if (!state.isOwner) {
      state = state.copyWith(errorMessage: 'Only the squad leader/manager can update player roles.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repo.updateMemberRole(state.squad!.id, userId, newRosterType);
      state = state.copyWith(
        squad: updated,
        isLoading: false,
        successMessage: 'Player role updated to ${newRosterType.name.toUpperCase()}.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<Map<String, dynamic>?> sendPreviousTeamInvitations(String tournamentId) async {
    if (state.squad == null) return null;
    if (!state.isOwner) {
      state = state.copyWith(errorMessage: 'Only squad leader/manager can invite previous team members.');
      return null;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repo.sendPreviousTeamInvitations(state.squad!.id, tournamentId);
      final invites = await _repo.getPendingInvitations();
      state = state.copyWith(
        pendingInvitations: invites,
        isLoading: false,
        successMessage: 'Invitations sent to your squad members for tournament!',
      );
      return res;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  Future<bool> respondToInvitation(String invitationId, bool accept) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.respondToInvitation(invitationId, accept);
      final invites = await _repo.getPendingInvitations();
      final updatedSquad = await _repo.getMySquad();

      state = state.copyWith(
        squad: updatedSquad,
        pendingInvitations: invites,
        isLoading: false,
        successMessage: accept
            ? 'Invitation accepted! Joined tournament lobby.'
            : 'Invitation rejected and removed from squad.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final squadProvider = NotifierProvider<SquadNotifier, SquadState>(SquadNotifier.new);
