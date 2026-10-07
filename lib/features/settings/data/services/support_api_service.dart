import 'package:flutter/foundation.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/support_models.dart';

class SupportApiService {
  final ApiClient _apiClient;

  SupportApiService(this._apiClient);

  /// Submit issue report to POST /v1/support/report-issue
  Future<bool> submitReportIssue(ReportIssueRequest request) async {
    try {
      await _apiClient.post(
        ApiEndpoints.reportIssue,
        data: request.toJson(),
      );
      return true;
    } catch (e) {
      debugPrint('SupportApiService.submitReportIssue error: $e');
      return false;
    }
  }

  /// Submit contact support ticket to POST /v1/support/contact
  Future<bool> submitContactSupport(ContactSupportRequest request) async {
    try {
      await _apiClient.post(
        ApiEndpoints.contactSupport,
        data: request.toJson(),
      );
      return true;
    } catch (e) {
      debugPrint('SupportApiService.submitContactSupport error: $e');
      return false;
    }
  }
}
