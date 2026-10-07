import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../splash/providers/splash_providers.dart';
import '../data/models/support_models.dart';
import '../data/services/support_api_service.dart';

final supportApiServiceProvider = Provider<SupportApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SupportApiService(apiClient);
});

class ReportIssueNotifier extends StateNotifier<AsyncValue<void>> {
  final SupportApiService _apiService;

  ReportIssueNotifier(this._apiService) : super(const AsyncValue.data(null));

  Future<bool> submitReport(ReportIssueRequest request) async {
    state = const AsyncValue.loading();
    try {
      final success = await _apiService.submitReportIssue(request);
      if (success) {
        state = const AsyncValue.data(null);
        return true;
      } else {
        state = AsyncValue.error(
            'Failed to submit issue report', StackTrace.current);
        return false;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final reportIssueProvider =
    StateNotifierProvider<ReportIssueNotifier, AsyncValue<void>>((ref) {
  final apiService = ref.watch(supportApiServiceProvider);
  return ReportIssueNotifier(apiService);
});

class ContactSupportNotifier extends StateNotifier<AsyncValue<void>> {
  final SupportApiService _apiService;

  ContactSupportNotifier(this._apiService) : super(const AsyncValue.data(null));

  Future<bool> sendMessage(ContactSupportRequest request) async {
    state = const AsyncValue.loading();
    try {
      final success = await _apiService.submitContactSupport(request);
      if (success) {
        state = const AsyncValue.data(null);
        return true;
      } else {
        state = AsyncValue.error(
            'Failed to send support message', StackTrace.current);
        return false;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final contactSupportProvider =
    StateNotifierProvider<ContactSupportNotifier, AsyncValue<void>>((ref) {
  final apiService = ref.watch(supportApiServiceProvider);
  return ContactSupportNotifier(apiService);
});
