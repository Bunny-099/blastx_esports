import 'package:blastix_esports/features/live/data/models/tournament_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TournamentModel New Fields & Helpers Tests', () {
    test('fromJson parses starts_at, max_slots, filled_slots, and is_registered', () {
      final json = {
        'id': 'tourney_001',
        'title': 'Free Fire Pro Series',
        'game': 'Free Fire',
        'status': 'LIVE',
        'starts_at': '2026-10-10T15:30:00Z',
        'max_slots': 48,
        'filled_slots': 32,
        'is_registered': true,
      };

      final model = TournamentModel.fromJson(json);

      expect(model.id, equals('tourney_001'));
      expect(model.name, equals('Free Fire Pro Series'));
      expect(model.startsAt, isNotNull);
      expect(model.startsAt, equals(DateTime.parse('2026-10-10T15:30:00Z')));
      expect(model.maxSlots, equals(48));
      expect(model.filledSlots, equals(32));
      expect(model.isRegistered, isTrue);

      // Helper assertions
      expect(model.slotsText, equals('32/48 slots'));
      expect(model.slotsProgress, closeTo(32 / 48, 0.001));
      expect(model.isFull, isFalse);
    });

    test('isFull helper returns true when filled_slots >= max_slots', () {
      final json = {
        'id': 'tourney_002',
        'title': 'Free Fire Cup',
        'max_slots': 48,
        'filled_slots': 48,
        'is_registered': false,
      };

      final model = TournamentModel.fromJson(json);

      expect(model.isFull, isTrue);
      expect(model.slotsProgress, equals(1.0));
      expect(model.slotsText, equals('48/48 slots'));
    });

    test('null values fall back to mock safe defaults without breaking', () {
      final json = {
        'id': 'tourney_003',
        'title': 'Legacy Tournament',
      };

      final model = TournamentModel.fromJson(json);

      expect(model.startsAt, isNull);
      expect(model.maxSlots, isNull);
      expect(model.filledSlots, isNull);
      expect(model.isRegistered, isNull);

      // Fallback getters & helpers
      expect(model.effectiveFilledSlots, equals(32));
      expect(model.effectiveMaxSlots, equals(48));
      expect(model.effectiveIsRegistered, isFalse);
      expect(model.slotsText, equals('32/48 slots'));
      expect(model.slotsProgress, closeTo(32 / 48, 0.001));
      expect(model.isFull, isFalse);
    });

    test('toJson serializes new optional fields correctly', () {
      final model = TournamentModel(
        id: 'tourney_004',
        name: 'Grand Finals',
        game: 'Free Fire',
        bannerImageUrl: '',
        gameLogoUrl: '',
        prizePool: 50000,
        viewersCount: 1500,
        status: TournamentStatus.upcoming,
        startTime: DateTime.parse('2026-12-01T12:00:00Z'),
        organizer: 'BlastX',
        startsAt: DateTime.parse('2026-12-01T12:00:00Z'),
        maxSlots: 100,
        filledSlots: 95,
        isRegistered: true,
      );

      final json = model.toJson();

      expect(json['starts_at'], equals('2026-12-01T12:00:00.000Z'));
      expect(json['max_slots'], equals(100));
      expect(json['filled_slots'], equals(95));
      expect(json['is_registered'], isTrue);

      expect(model.slotsText, equals('95/100 slots'));
      expect(model.slotsProgress, equals(0.95));
      expect(model.isFull, isFalse);
    });
  });
}
