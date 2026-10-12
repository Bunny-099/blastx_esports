import 'package:blastix_esports/core/sync/real_time_sync_manager.dart';
import 'package:blastix_esports/features/live/data/models/registration_approval_model.dart';
import 'package:blastix_esports/features/live/data/models/team_member_model.dart';
import 'package:blastix_esports/features/live/data/models/team_model.dart';
import 'package:blastix_esports/features/live/providers/team_provider.dart';
import 'package:blastix_esports/features/squad/data/models/squad_model.dart';
import 'package:blastix_esports/features/squad/providers/squad_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSquadNotifier extends SquadNotifier {
  @override
  SquadState build() => const SquadState(viewerUserId: 'cap_1');

  @override
  Future<bool> createOrSaveSquadFromRoster({
    String? squadName,
    String? tag,
    List<SquadMemberModel>? members,
    SquadRole ownerRole = SquadRole.leader,
  }) async {
    return true;
  }
}

class FakeRegistrationTeamRepository implements TeamRepository {
  TournamentTeamModel currentTeam = const TournamentTeamModel(
    id: 'team_100',
    tournamentId: 'tourn_100',
    code: 'CODE100',
    name: 'Gladiators',
    captainId: 'cap_1',
    status: TeamRegistrationStatus.forming,
    registrationState: TeamRegistrationState.forming,
    canRegister: true,
    members: [
      TeamMemberModel(
        userId: 'cap_1',
        name: 'Captain One',
        role: TeamRole.captain,
        rosterType: RosterType.main,
        status: TeamMemberStatus.confirmed,
      ),
      TeamMemberModel(
        userId: 'p2',
        name: 'Player Two',
        role: TeamRole.member,
        rosterType: RosterType.main,
        status: TeamMemberStatus.confirmed,
      ),
      TeamMemberModel(
        userId: 'p3',
        name: 'Player Three',
        role: TeamRole.member,
        rosterType: RosterType.main,
        status: TeamMemberStatus.confirmed,
      ),
      TeamMemberModel(
        userId: 'p4',
        name: 'Player Four',
        role: TeamRole.member,
        rosterType: RosterType.main,
        status: TeamMemberStatus.confirmed,
      ),
    ],
  );

  List<RegistrationApproval> myApprovalsList = [
    const RegistrationApproval(
      id: 'app_1',
      status: ApprovalStatus.pending,
      tournamentId: 'tourn_100',
      tournamentTitle: 'BlastX Cup',
      teamId: 'team_100',
      teamName: 'Gladiators',
    ),
  ];

  @override
  TournamentTeamModel parseTeam(dynamic d) {
    final map = (d is Map && d['team'] is Map) ? d['team'] : d;
    return TournamentTeamModel.fromJson(Map<String, dynamic>.from(map as Map));
  }

  @override
  Future<TournamentTeamModel?> myTeam(String tid) async {
    return currentTeam;
  }

  @override
  Future<dynamic> registerTournament(String tournamentId, String teamId) async {
    currentTeam = currentTeam.copyWith(
      registrationState: TeamRegistrationState.pendingPlayerApproval,
      canCancelRegistrationRequest: true,
    );
    return {'team': currentTeam.toJson()};
  }

  @override
  Future<TournamentTeamModel> updatePlayingRoster(
      String teamId, List<String> mainUserIds) async {
    currentTeam = currentTeam.copyWith(
      registrationState: TeamRegistrationState.forming,
      rosterVersion: currentTeam.rosterVersion + 1,
    );
    return currentTeam;
  }

  @override
  Future<TournamentTeamModel> cancelRegistrationRequest(
      String tid, String teamId) async {
    currentTeam = currentTeam.copyWith(
      registrationState: TeamRegistrationState.forming,
      canCancelRegistrationRequest: false,
    );
    return currentTeam;
  }

  @override
  Future<List<RegistrationApproval>> myApprovals([String status = 'PENDING']) async {
    return myApprovalsList;
  }

  @override
  Future<RegistrationApproval> approvalDetail(String id) async {
    return myApprovalsList.firstWhere(
      (a) => a.id == id,
      orElse: () => const RegistrationApproval(id: 'app_1'),
    );
  }

  @override
  Future<void> approveRegistration(String id) async {
    myApprovalsList = myApprovalsList.where((a) => a.id != id).toList();
    currentTeam = currentTeam.copyWith(
      registrationState: TeamRegistrationState.confirmed,
    );
  }

  @override
  Future<void> declineRegistration(String id) async {
    myApprovalsList = myApprovalsList.where((a) => a.id != id).toList();
    currentTeam = currentTeam.copyWith(
      registrationState: TeamRegistrationState.rosterChangeRequired,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RealTimeSyncManager.isTestMode = true;
  });

  tearDown(() {
    RealTimeSyncManager.isTestMode = false;
  });

  test('Registration Submit -> Pending Approval -> Cancel Request Flow', () async {
    final fakeRepo = FakeRegistrationTeamRepository();
    final container = ProviderContainer(
      overrides: [
        teamRepositoryProvider.overrideWithValue(fakeRepo),
        squadProvider.overrideWith(FakeSquadNotifier.new),
      ],
    );

    final notifier = container.read(teamProvider('tourn_100').notifier);

    // Initial state check
    await notifier.loadMyTeam();
    var state = container.read(teamProvider('tourn_100'));
    expect(state.team?.registrationState, TeamRegistrationState.forming);

    // Submit Registration
    final submitted = await notifier.completeRegistration(mode: 'SQUAD');
    expect(submitted, isTrue);

    state = container.read(teamProvider('tourn_100'));
    expect(state.team?.registrationState, TeamRegistrationState.pendingPlayerApproval);
    expect(state.team?.canCancelRegistrationRequest, isTrue);

    // Cancel Registration Request
    final cancelled = await notifier.cancelRegistrationRequest();
    expect(cancelled, isTrue);

    state = container.read(teamProvider('tourn_100'));
    expect(state.team?.registrationState, TeamRegistrationState.forming);

    container.dispose();
  });

  test('Registration Approval -> Approve and Decline Provider Flows', () async {
    final fakeRepo = FakeRegistrationTeamRepository();
    final container = ProviderContainer(
      overrides: [
        teamRepositoryProvider.overrideWithValue(fakeRepo),
        squadProvider.overrideWith(FakeSquadNotifier.new),
      ],
    );

    final approvalsNotifier = container.read(approvalsProvider.notifier);

    // Fetch approvals
    await approvalsNotifier.fetchApprovals();
    var approvalsState = container.read(approvalsProvider);
    expect(approvalsState.pendingApprovals.length, 1);
    expect(approvalsState.pendingApprovals.first.id, 'app_1');

    // Approve registration
    final approved = await approvalsNotifier.approve('app_1');
    expect(approved, isTrue);

    approvalsState = container.read(approvalsProvider);
    expect(approvalsState.pendingApprovals.isEmpty, isTrue);

    // Test decline flow
    fakeRepo.myApprovalsList = [
      const RegistrationApproval(
        id: 'app_2',
        status: ApprovalStatus.pending,
        tournamentId: 'tourn_100',
      ),
    ];

    await approvalsNotifier.fetchApprovals();
    expect(container.read(approvalsProvider).pendingApprovals.length, 1);

    final declined = await approvalsNotifier.decline('app_2');
    expect(declined, isTrue);
    expect(container.read(approvalsProvider).pendingApprovals.isEmpty, isTrue);

    container.dispose();
  });

  test('Playing Roster Update resets registration state to FORMING', () async {
    final fakeRepo = FakeRegistrationTeamRepository();
    final container = ProviderContainer(
      overrides: [
        teamRepositoryProvider.overrideWithValue(fakeRepo),
        squadProvider.overrideWith(FakeSquadNotifier.new),
      ],
    );

    final notifier = container.read(teamProvider('tourn_100').notifier);
    await notifier.loadMyTeam();

    // Set to pending
    fakeRepo.currentTeam = fakeRepo.currentTeam.copyWith(
      registrationState: TeamRegistrationState.pendingPlayerApproval,
    );

    final updated = await notifier.updatePlayingRoster(['cap_1', 'p2', 'p3', 'p4']);
    expect(updated, isTrue);

    final state = container.read(teamProvider('tourn_100'));
    expect(state.team?.registrationState, TeamRegistrationState.forming);
    expect(state.team?.rosterVersion, 2);

    container.dispose();
  });
}
