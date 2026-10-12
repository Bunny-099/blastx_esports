import 'package:blastix_esports/features/live/data/models/registration_status_helper.dart';
import 'package:blastix_esports/features/live/data/models/team_model.dart';
import 'package:blastix_esports/features/live/data/models/tournament_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MyRegistration & TournamentModel Section 4 Parsing', () {
    test('MyRegistration.fromJson parses all fields and enums correctly', () {
      final json = {
        'state': 'PENDING_PLAYER_APPROVAL',
        'team_id': 'team_99',
        'slot_number': 4,
        'waitlist_position': 2,
        'approvals_required': 4,
        'approvals_approved': 1,
        'my_pending_approval_id': 'app_123',
        'my_role': 'LEADER',
        'is_playing': true,
      };

      final reg = MyRegistration.fromJson(json);

      expect(reg.state, equals(MyRegistrationState.pendingPlayerApproval));
      expect(reg.teamId, equals('team_99'));
      expect(reg.slotNumber, equals(4));
      expect(reg.waitlistPosition, equals(2));
      expect(reg.approvalsRequired, equals(4));
      expect(reg.approvalsApproved, equals(1));
      expect(reg.myPendingApprovalId, equals('app_123'));
      expect(reg.myRole, equals(MyRegistrationRole.leader));
      expect(reg.isPlaying, isTrue);
    });

    test('MyRegistration handles unknown state and role gracefully', () {
      final json = {
        'state': 'SOME_NEW_FUTURE_STATE',
        'my_role': 'NEW_ROLE',
      };

      final reg = MyRegistration.fromJson(json);

      expect(reg.state, equals(MyRegistrationState.unknown));
      expect(reg.myRole, equals(MyRegistrationRole.unknown));
    });

    test('TournamentModel parses my_registration and waitlist_count', () {
      final json = {
        'id': 't_001',
        'title': 'Grand FF Tournament',
        'status': 'LIVE',
        'waitlist_count': 5,
        'my_registration': {
          'state': 'CONFIRMED',
          'team_id': 'team_1',
          'waitlist_position': null,
          'my_role': 'PLAYER',
        },
      };

      final model = TournamentModel.fromJson(json);

      expect(model.waitlistCount, equals(5));
      expect(model.myRegistration, isNotNull);
      expect(model.myRegistration!.state, equals(MyRegistrationState.confirmed));
      expect(model.myRegistration!.myRole, equals(MyRegistrationRole.player));
    });

    test('TournamentTeamModel parses waitlistPosition and waitlistSize', () {
      final json = {
        'id': 'team_1',
        'tournament_id': 't_001',
        'name': 'Alpha Squad',
        'waitlist_position': 3,
        'waitlist_size': 10,
      };

      final team = TournamentTeamModel.fromJson(json);

      expect(team.waitlistPosition, equals(3));
      expect(team.waitlistSize, equals(10));
    });
  });

  group('getRegistrationBadge Helper Tests', () {
    test('CONFIRMED -> Registered badge', () {
      final t = TournamentModel(
        id: '1',
        name: 'T',
        game: 'G',
        bannerImageUrl: '',
        gameLogoUrl: '',
        prizePool: 0,
        viewersCount: 0,
        status: TournamentStatus.live,
        startTime: DateTime.now(),
        organizer: 'O',
        myRegistration: const MyRegistration(state: MyRegistrationState.confirmed),
      );

      final badge = getRegistrationBadge(t);
      expect(badge, isNotNull);
      expect(badge!.label, equals('Registered'));
    });

    test('PENDING_PLAYER_APPROVAL -> Approval pending badge', () {
      final t = TournamentModel(
        id: '1',
        name: 'T',
        game: 'G',
        bannerImageUrl: '',
        gameLogoUrl: '',
        prizePool: 0,
        viewersCount: 0,
        status: TournamentStatus.live,
        startTime: DateTime.now(),
        organizer: 'O',
        myRegistration: const MyRegistration(state: MyRegistrationState.pendingPlayerApproval),
      );

      final badge = getRegistrationBadge(t);
      expect(badge, isNotNull);
      expect(badge!.label, equals('Approval pending'));
    });

    test('ROSTER_CHANGE_REQUIRED -> Action needed badge', () {
      final t = TournamentModel(
        id: '1',
        name: 'T',
        game: 'G',
        bannerImageUrl: '',
        gameLogoUrl: '',
        prizePool: 0,
        viewersCount: 0,
        status: TournamentStatus.live,
        startTime: DateTime.now(),
        organizer: 'O',
        myRegistration: const MyRegistration(state: MyRegistrationState.rosterChangeRequired),
      );

      final badge = getRegistrationBadge(t);
      expect(badge, isNotNull);
      expect(badge!.label, equals('Action needed'));
    });

    test('WAITLISTED -> Waitlisted #n badge', () {
      final t = TournamentModel(
        id: '1',
        name: 'T',
        game: 'G',
        bannerImageUrl: '',
        gameLogoUrl: '',
        prizePool: 0,
        viewersCount: 0,
        status: TournamentStatus.live,
        startTime: DateTime.now(),
        organizer: 'O',
        myRegistration: const MyRegistration(
          state: MyRegistrationState.waitlisted,
          waitlistPosition: 4,
        ),
      );

      final badge = getRegistrationBadge(t);
      expect(badge, isNotNull);
      expect(badge!.label, equals('Waitlisted #4'));
    });

    test('FORMING -> Team forming badge', () {
      final t = TournamentModel(
        id: '1',
        name: 'T',
        game: 'G',
        bannerImageUrl: '',
        gameLogoUrl: '',
        prizePool: 0,
        viewersCount: 0,
        status: TournamentStatus.live,
        startTime: DateTime.now(),
        organizer: 'O',
        myRegistration: const MyRegistration(state: MyRegistrationState.forming),
      );

      final badge = getRegistrationBadge(t);
      expect(badge, isNotNull);
      expect(badge!.label, equals('Team forming'));
    });

    test('null myRegistration -> null badge', () {
      final t = TournamentModel(
        id: '1',
        name: 'T',
        game: 'G',
        bannerImageUrl: '',
        gameLogoUrl: '',
        prizePool: 0,
        viewersCount: 0,
        status: TournamentStatus.live,
        startTime: DateTime.now(),
        organizer: 'O',
      );

      final badge = getRegistrationBadge(t);
      expect(badge, isNull);
    });
  });

  group('getCtaState Helper Tests (Full Table)', () {
    final now = DateTime.now();

    test('Priority 1: Completed tournament -> completed CTA', () {
      final t = TournamentModel(
        id: '1',
        name: 'T',
        game: 'G',
        bannerImageUrl: '',
        gameLogoUrl: '',
        prizePool: 0,
        viewersCount: 0,
        status: TournamentStatus.completed,
        startTime: now,
        organizer: 'O',
      );

      final cta = getCtaState(t, null);
      expect(cta.type, equals(CtaType.completed));
      expect(cta.isEnabled, isFalse);
    });

    test('Priority 2: Upcoming tournament -> countdown CTA', () {
      final t = TournamentModel(
        id: '1',
        name: 'T',
        game: 'G',
        bannerImageUrl: '',
        gameLogoUrl: '',
        prizePool: 0,
        viewersCount: 0,
        status: TournamentStatus.upcoming,
        startTime: now.add(const Duration(hours: 3)),
        organizer: 'O',
      );

      final cta = getCtaState(t, null);
      expect(cta.type, equals(CtaType.upcomingCountdown));
      expect(cta.isEnabled, isFalse);
    });

    test('Priority 3: CONFIRMED -> REGISTERED - VIEW MATCHES CTA', () {
      final t = TournamentModel(
        id: '1',
        name: 'T',
        game: 'G',
        bannerImageUrl: '',
        gameLogoUrl: '',
        prizePool: 0,
        viewersCount: 0,
        status: TournamentStatus.live,
        startTime: now,
        organizer: 'O',
        myRegistration: const MyRegistration(state: MyRegistrationState.confirmed),
      );

      final cta = getCtaState(t, null);
      expect(cta.type, equals(CtaType.confirmed));
      expect(cta.label, contains('REGISTERED - VIEW MATCHES'));
    });

    test('Priority 4: WAITLISTED -> WAITLISTED #n - VIEW STATUS CTA', () {
      final t = TournamentModel(
        id: '1',
        name: 'T',
        game: 'G',
        bannerImageUrl: '',
        gameLogoUrl: '',
        prizePool: 0,
        viewersCount: 0,
        status: TournamentStatus.live,
        startTime: now,
        organizer: 'O',
        myRegistration: const MyRegistration(
          state: MyRegistrationState.waitlisted,
          waitlistPosition: 2,
        ),
      );

      final cta = getCtaState(t, null);
      expect(cta.type, equals(CtaType.waitlisted));
      expect(cta.label, contains('WAITLISTED #2'));
    });

    test('Priority 5: myPendingApprovalId present -> APPROVE PARTICIPATION CTA', () {
      final t = TournamentModel(
        id: '1',
        name: 'T',
        game: 'G',
        bannerImageUrl: '',
        gameLogoUrl: '',
        prizePool: 0,
        viewersCount: 0,
        status: TournamentStatus.live,
        startTime: now,
        organizer: 'O',
        myRegistration: const MyRegistration(
          state: MyRegistrationState.pendingPlayerApproval,
          myPendingApprovalId: 'app_1',
        ),
      );

      final cta = getCtaState(t, null);
      expect(cta.type, equals(CtaType.approveParticipation));
      expect(cta.label, equals('APPROVE PARTICIPATION'));
    });

    test('Priority 6: PENDING_PLAYER_APPROVAL -> WAITING FOR APPROVALS (x/y) CTA', () {
      final t = TournamentModel(
        id: '1',
        name: 'T',
        game: 'G',
        bannerImageUrl: '',
        gameLogoUrl: '',
        prizePool: 0,
        viewersCount: 0,
        status: TournamentStatus.live,
        startTime: now,
        organizer: 'O',
        myRegistration: const MyRegistration(
          state: MyRegistrationState.pendingPlayerApproval,
          approvalsApproved: 2,
          approvalsRequired: 4,
        ),
      );

      final cta = getCtaState(t, null);
      expect(cta.type, equals(CtaType.waitingApprovals));
      expect(cta.label, contains('WAITING FOR APPROVALS (2/4)'));
    });

    test('Priority 7: ROSTER_CHANGE_REQUIRED -> Owner gets FIX ROSTER, Non-owner gets VIEW STATUS', () {
      final t = TournamentModel(
        id: '1',
        name: 'T',
        game: 'G',
        bannerImageUrl: '',
        gameLogoUrl: '',
        prizePool: 0,
        viewersCount: 0,
        status: TournamentStatus.live,
        startTime: now,
        organizer: 'O',
        myRegistration: const MyRegistration(state: MyRegistrationState.rosterChangeRequired),
      );

      const ownerTeam = TournamentTeamModel(
        id: 'team_1',
        tournamentId: '1',
        code: '123',
        name: 'Team 1',
        captainId: 'u_1',
        viewerUserId: 'u_1',
      );

      const memberTeam = TournamentTeamModel(
        id: 'team_1',
        tournamentId: '1',
        code: '123',
        name: 'Team 1',
        captainId: 'u_1',
        viewerUserId: 'u_2',
      );

      final ownerCta = getCtaState(t, ownerTeam);
      expect(ownerCta.label, equals('FIX ROSTER'));

      final memberCta = getCtaState(t, memberTeam);
      expect(memberCta.label, equals('VIEW STATUS'));
    });

    test('Priority 8: FORMING -> Owner gets CONTINUE REGISTRATION, Non-owner gets VIEW TEAM LOBBY', () {
      final t = TournamentModel(
        id: '1',
        name: 'T',
        game: 'G',
        bannerImageUrl: '',
        gameLogoUrl: '',
        prizePool: 0,
        viewersCount: 0,
        status: TournamentStatus.live,
        startTime: now,
        organizer: 'O',
        myRegistration: const MyRegistration(state: MyRegistrationState.forming),
      );

      const ownerTeam = TournamentTeamModel(
        id: 'team_1',
        tournamentId: '1',
        code: '123',
        name: 'Team 1',
        captainId: 'u_1',
        viewerUserId: 'u_1',
      );

      const memberTeam = TournamentTeamModel(
        id: 'team_1',
        tournamentId: '1',
        code: '123',
        name: 'Team 1',
        captainId: 'u_1',
        viewerUserId: 'u_2',
      );

      final ownerCta = getCtaState(t, ownerTeam);
      expect(ownerCta.label, equals('CONTINUE REGISTRATION'));

      final memberCta = getCtaState(t, memberTeam);
      expect(memberCta.label, equals('VIEW TEAM LOBBY'));
    });

    test('Priority 9: Live + No registration + Full -> JOIN NOW with waitlist subNote', () {
      final t = TournamentModel(
        id: '1',
        name: 'T',
        game: 'G',
        bannerImageUrl: '',
        gameLogoUrl: '',
        prizePool: 0,
        viewersCount: 0,
        status: TournamentStatus.live,
        startTime: now,
        organizer: 'O',
        maxSlots: 16,
        filledSlots: 16,
      );

      final cta = getCtaState(t, null);
      expect(cta.type, equals(CtaType.liveFullNoRegistration));
      expect(cta.label, equals('JOIN NOW'));
      expect(cta.subNote, contains('added to the waitlist'));
    });

    test('Priority 10: Live + No registration + Slots available -> JOIN NOW • FREE', () {
      final t = TournamentModel(
        id: '1',
        name: 'T',
        game: 'G',
        bannerImageUrl: '',
        gameLogoUrl: '',
        prizePool: 0,
        viewersCount: 0,
        status: TournamentStatus.live,
        startTime: now,
        organizer: 'O',
        maxSlots: 16,
        filledSlots: 10,
        entryFee: 0,
      );

      final cta = getCtaState(t, null);
      expect(cta.type, equals(CtaType.liveJoinNow));
      expect(cta.label, equals('JOIN NOW • FREE'));
    });
  });
}
