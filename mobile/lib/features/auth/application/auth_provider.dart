import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/crm_repository.dart';

@immutable
class AuthState {
  const AuthState({required this.token, required this.user});
  final String token;
  final CrmUser user;
}

class AuthNotifier extends Notifier<AuthState?> {
  @override
  AuthState? build() => null;

  Future<void> restore() async {
    final storage = ref.read(tokenStorageProvider);
    final token = await storage.getToken();
    if (token == null) return;
    try {
      final user = await ref.read(crmRepositoryProvider).me();
      state = AuthState(token: token, user: user);
    } catch (_) {
      await storage.clearToken();
    }
  }

  Future<void> login(String employeeNo, String password) async {
    final result = await ref.read(crmRepositoryProvider).login(employeeNo, password);
    await ref.read(tokenStorageProvider).saveToken(result.token);
    state = AuthState(token: result.token, user: result.user);
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clearToken();
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState?>(AuthNotifier.new);

final leadsProvider = FutureProvider.autoDispose<List<Lead>>((ref) async {
  return ref.read(crmRepositoryProvider).getLeads();
});

final opportunitiesProvider = FutureProvider.autoDispose<({List<Opportunity> items, Map<String, List<Opportunity>> byStage})>((ref) async {
  return ref.read(crmRepositoryProvider).getOpportunities();
});

final customersProvider = FutureProvider.autoDispose.family<List<Customer>, String?>((ref, query) async {
  return ref.read(crmRepositoryProvider).getCustomers(q: query);
});

final tasksProvider = FutureProvider.autoDispose<List<TaskItem>>((ref) async {
  return ref.read(crmRepositoryProvider).getTasks();
});

final visitsProvider = FutureProvider.autoDispose<List<Visit>>((ref) async {
  return ref.read(crmRepositoryProvider).getVisits();
});

final reportProvider = FutureProvider.autoDispose.family<ReportSummary, String>((ref, period) async {
  return ref.read(crmRepositoryProvider).getReportSummary(period: period);
});
