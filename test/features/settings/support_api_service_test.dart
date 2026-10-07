import 'package:flutter_test/flutter_test.dart';
import 'package:blastix_esports/core/api/api_client.dart';
import 'package:blastix_esports/core/api/api_endpoints.dart';
import 'package:blastix_esports/core/services/device_info_service.dart';
import 'package:blastix_esports/core/services/storage_service.dart';
import 'package:blastix_esports/features/settings/data/models/support_models.dart';
import 'package:blastix_esports/features/settings/data/services/support_api_service.dart';

class FakeStorageService extends StorageService {}

class FakeDeviceInfoService extends DeviceInfoService {}

class MockSupportApiClient extends ApiClient {
  String? lastEndpoint;
  dynamic lastData;

  MockSupportApiClient()
      : super(FakeStorageService(), FakeDeviceInfoService());

  @override
  Future<dynamic> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dynamic options,
  }) async {
    lastEndpoint = endpoint;
    lastData = data;
    return {'status': 'success', 'data': {'id': 'test_id'}};
  }
}

void main() {
  group('Support Models & Service Unit Tests', () {
    late MockSupportApiClient mockApiClient;
    late SupportApiService supportApiService;

    setUp(() {
      mockApiClient = MockSupportApiClient();
      supportApiService = SupportApiService(mockApiClient);
    });

    test('ReportIssueRequest serialization and deserialization', () {
      const request = ReportIssueRequest(
        issueType: 'Bug / Glitch',
        description: 'Screen frozen on tournament join',
        tournamentName: 'BlastX Weekly Cup',
        deviceModel: 'Samsung S24',
        appVersion: '1.0.0',
        osVersion: 'Android 14',
        deviceType: 'ANDROID',
        userId: 'usr_123',
        userName: 'Player1',
        userEmail: 'player1@test.com',
        userPhone: '+919876543210',
        freeFireUid: '11223344',
        inGameName: 'ProShooter',
      );

      final json = request.toJson();
      expect(json['issue_type'], 'Bug / Glitch');
      expect(json['description'], 'Screen frozen on tournament join');
      expect(json['tournament_name'], 'BlastX Weekly Cup');
      expect(json['device_model'], 'Samsung S24');
      expect(json['user_id'], 'usr_123');
      expect(json['user_email'], 'player1@test.com');
      expect(json['free_fire_uid'], '11223344');

      final deserialized = ReportIssueRequest.fromJson(json);
      expect(deserialized.issueType, 'Bug / Glitch');
      expect(deserialized.description, 'Screen frozen on tournament join');
      expect(deserialized.userId, 'usr_123');
      expect(deserialized.userEmail, 'player1@test.com');
    });

    test('ContactSupportRequest serialization and deserialization', () {
      const request = ContactSupportRequest(
        subject: 'Wallet Payout Issue',
        category: 'Prize & Wallet Payouts',
        message: 'Where is my reward payout?',
        userId: 'usr_456',
        userName: 'Gamer2',
        userEmail: 'gamer2@test.com',
        deviceModel: 'iPhone 15 Pro',
        appVersion: '1.0.0',
        osVersion: 'iOS 17.5.1',
        deviceType: 'IOS',
      );

      final json = request.toJson();
      expect(json['subject'], 'Wallet Payout Issue');
      expect(json['category'], 'Prize & Wallet Payouts');
      expect(json['message'], 'Where is my reward payout?');
      expect(json['user_id'], 'usr_456');
      expect(json['device_model'], 'iPhone 15 Pro');

      final deserialized = ContactSupportRequest.fromJson(json);
      expect(deserialized.subject, 'Wallet Payout Issue');
      expect(deserialized.category, 'Prize & Wallet Payouts');
      expect(deserialized.userId, 'usr_456');
    });

    test('SupportApiService submitReportIssue posts to reportIssue endpoint',
        () async {
      const request = ReportIssueRequest(
        issueType: 'Bug / Glitch',
        description: 'App lag during stream',
      );

      final success = await supportApiService.submitReportIssue(request);

      expect(success, isTrue);
      expect(mockApiClient.lastEndpoint, ApiEndpoints.reportIssue);
      expect(mockApiClient.lastData['issue_type'], 'Bug / Glitch');
      expect(mockApiClient.lastData['description'], 'App lag during stream');
    });

    test('SupportApiService submitContactSupport posts to contactSupport endpoint',
        () async {
      const request = ContactSupportRequest(
        subject: 'Help required',
        category: 'General Query',
        message: 'How to create squad?',
      );

      final success = await supportApiService.submitContactSupport(request);

      expect(success, isTrue);
      expect(mockApiClient.lastEndpoint, ApiEndpoints.contactSupport);
      expect(mockApiClient.lastData['subject'], 'Help required');
      expect(mockApiClient.lastData['category'], 'General Query');
    });
  });
}
