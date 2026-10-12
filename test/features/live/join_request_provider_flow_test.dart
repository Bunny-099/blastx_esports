import 'package:blastix_esports/core/sync/real_time_sync_manager.dart';
import 'package:blastix_esports/features/live/data/models/team_model.dart';
import 'package:blastix_esports/features/live/providers/team_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FakeTeamRepository implements TeamRepository {
  List<JoinRequest> ownerRequests = [
    const JoinRequest(
      id: 'req_1',
      status: JoinRequestStatus.pending,
      teamId: 'team_1',
      userId: 'user_1',
      userName: 'Player One',
    ),
  ];

  List<JoinRequest> myPendingList = [
    const JoinRequest(
      id: 'req_my_1',
      status: JoinRequestStatus.pending,
      teamId: 'team_2',
      userId: 'my_user',
      userName: 'Me',
    ),
  ];

  @override
  Future<List<JoinRequest>> ownerJoinRequests(String teamId) async {
    return ownerRequests;
  }

  @override
  Future<void> approveJoinRequest(String teamId, String requestId) async {
    ownerRequests = ownerRequests.where((r) => r.id != requestId).toList();
  }

  @override
  Future<void> rejectJoinRequest(String teamId, String requestId) async {
    ownerRequests = ownerRequests.where((r) => r.id != requestId).toList();
  }

  @override
  Future<List<JoinRequest>> myJoinRequests([String status = 'PENDING']) async {
    return myPendingList;
  }

  @override
  Future<void> cancelJoinRequest(String requestId) async {
    myPendingList = myPendingList.where((r) => r.id != requestId).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    RealTimeSyncManager.isTestMode = true;
  });

  tearDown(() {
    RealTimeSyncManager.isTestMode = false;
  });

  test('OwnerJoinRequestsNotifier provider flow: fetch, approve, reject', () async {
    final fakeRepo = FakeTeamRepository();
    final container = ProviderContainer(
      overrides: [
        teamRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );

    final notifier = container.read(ownerJoinRequestsProvider('team_1').notifier);

    // Initial state
    await notifier.fetchRequests();
    var state = container.read(ownerJoinRequestsProvider('team_1'));
    expect(state.requests.length, 1);
    expect(state.requests.first.id, 'req_1');

    // Approve
    final approved = await notifier.approveRequest('req_1');
    expect(approved, isTrue);

    state = container.read(ownerJoinRequestsProvider('team_1'));
    expect(state.requests.isEmpty, isTrue);

    // Add another request to test reject
    fakeRepo.ownerRequests = [
      const JoinRequest(
        id: 'req_2',
        status: JoinRequestStatus.pending,
        teamId: 'team_1',
        userId: 'user_2',
        userName: 'Player Two',
      ),
    ];

    await notifier.fetchRequests();
    state = container.read(ownerJoinRequestsProvider('team_1'));
    expect(state.requests.length, 1);

    final rejected = await notifier.rejectRequest('req_2');
    expect(rejected, isTrue);

    state = container.read(ownerJoinRequestsProvider('team_1'));
    expect(state.requests.isEmpty, isTrue);

    container.dispose();
  });

  test('MyPendingRequestsNotifier provider flow: fetch, cancel', () async {
    final fakeRepo = FakeTeamRepository();
    final container = ProviderContainer(
      overrides: [
        teamRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );

    final notifier = container.read(myPendingRequestsProvider.notifier);

    await notifier.fetchPendingRequests();
    var state = container.read(myPendingRequestsProvider);
    expect(state.pendingRequests.length, 1);
    expect(state.pendingRequests.first.id, 'req_my_1');

    final cancelled = await notifier.cancelRequest('req_my_1');
    expect(cancelled, isTrue);

    state = container.read(myPendingRequestsProvider);
    expect(state.pendingRequests.isEmpty, isTrue);

    container.dispose();
  });
}
