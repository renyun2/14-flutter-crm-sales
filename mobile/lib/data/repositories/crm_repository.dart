import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../models/models.dart';

class CrmRepository {
  CrmRepository(this._dio);
  final Dio _dio;

  Future<({String token, CrmUser user})> login(String employeeNo, String password) async {
    final res = await _dio.post('/api/auth/login', data: {
      'employeeNo': employeeNo,
      'password': password,
    });
    return (
      token: res.data['token'] as String,
      user: CrmUser.fromJson(Map<String, dynamic>.from(res.data['user'] as Map)),
    );
  }

  Future<CrmUser> me() async {
    final res = await _dio.get('/api/auth/me');
    return CrmUser.fromJson(Map<String, dynamic>.from(res.data['user'] as Map));
  }

  Future<List<Lead>> getLeads({String? status, String? source, bool? overdue}) async {
    final res = await _dio.get('/api/leads', queryParameters: {
      if (status != null) 'status': status,
      if (source != null) 'source': source,
      if (overdue == true) 'overdue': '1',
    });
    return (res.data['items'] as List)
        .map((e) => Lead.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<({Lead lead, List<FollowUp> followUps})> getLead(String id) async {
    final res = await _dio.get('/api/leads/$id');
    final data = Map<String, dynamic>.from(res.data as Map);
    final followUps = (data.remove('followUps') as List? ?? [])
        .map((e) => FollowUp.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return (lead: Lead.fromJson(data), followUps: followUps);
  }

  Future<Lead> createLead({required String title, required String company, String? source}) async {
    final res = await _dio.post('/api/leads', data: {
      'title': title,
      'company': company,
      'source': source ?? '官网',
    });
    return Lead.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> addFollowUp(String leadId, String content) async {
    await _dio.post('/api/leads/$leadId/follow-ups', data: {'content': content});
  }

  Future<({String customerId, String opportunityId})> convertLead(String leadId) async {
    final res = await _dio.post('/api/leads/$leadId/convert');
    return (
      customerId: res.data['customerId'] as String,
      opportunityId: res.data['opportunityId'] as String,
    );
  }

  Future<({List<Opportunity> items, Map<String, List<Opportunity>> byStage})> getOpportunities() async {
    final res = await _dio.get('/api/opportunities');
    final items = (res.data['items'] as List)
        .map((e) => Opportunity.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final byStageRaw = Map<String, dynamic>.from(res.data['byStage'] as Map);
    final byStage = byStageRaw.map(
      (k, v) => MapEntry(
        k,
        (v as List).map((e) => Opportunity.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      ),
    );
    return (items: items, byStage: byStage);
  }

  Future<Map<String, dynamic>> getOpportunity(String id) async {
    final res = await _dio.get('/api/opportunities/$id');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Opportunity> updateOpportunityStage(String id, String stage) async {
    final res = await _dio.patch('/api/opportunities/$id/stage', data: {'stage': stage});
    return Opportunity.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<List<Customer>> getCustomers({String? q, String? tag}) async {
    final res = await _dio.get('/api/customers', queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (tag != null) 'tag': tag,
    });
    return (res.data['items'] as List)
        .map((e) => Customer.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> getCustomer360(String id) async {
    final res = await _dio.get('/api/customers/$id');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Customer> createCustomer({required String name, String? industry, String? address}) async {
    final res = await _dio.post('/api/customers', data: {
      'name': name,
      'industry': industry,
      'address': address,
    });
    return Customer.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<List<Contact>> getContacts(String customerId) async {
    final res = await _dio.get('/api/contacts', queryParameters: {'customerId': customerId});
    return (res.data['items'] as List)
        .map((e) => Contact.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Contact> createContact({
    required String customerId,
    required String name,
    String? phone,
    String? title,
  }) async {
    final res = await _dio.post('/api/contacts', data: {
      'customerId': customerId,
      'name': name,
      'phone': phone,
      'title': title,
    });
    return Contact.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<List<Visit>> getVisits() async {
    final res = await _dio.get('/api/visits');
    return (res.data['items'] as List)
        .map((e) => Visit.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Visit> getVisit(String id) async {
    final res = await _dio.get('/api/visits/$id');
    return Visit.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<Visit> createVisit({
    required String customerId,
    required String title,
    required String plannedAt,
    String? address,
  }) async {
    final res = await _dio.post('/api/visits', data: {
      'customerId': customerId,
      'title': title,
      'plannedAt': plannedAt,
      'address': address,
    });
    return Visit.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<Visit> checkInVisit(String id, String address) async {
    final res = await _dio.post('/api/visits/$id/check-in', data: {'address': address});
    return Visit.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<Visit> updateVisit(String id, {String? status, String? summary, List<String>? photoUrls}) async {
    final res = await _dio.patch('/api/visits/$id', data: {
      if (status != null) 'status': status,
      if (summary != null) 'summary': summary,
      if (photoUrls != null) 'photoUrls': photoUrls,
    });
    return Visit.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<List<Quote>> getQuotes() async {
    final res = await _dio.get('/api/quotes');
    return (res.data['items'] as List)
        .map((e) => Quote.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Quote> getQuote(String id) async {
    final res = await _dio.get('/api/quotes/$id');
    return Quote.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<Quote> updateQuote(String id, {String? title, double? discount, List<Map<String, dynamic>>? items}) async {
    final res = await _dio.put('/api/quotes/$id', data: {
      if (title != null) 'title': title,
      if (discount != null) 'discount': discount,
      if (items != null) 'items': items,
    });
    return Quote.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<List<Contract>> getContracts() async {
    final res = await _dio.get('/api/contracts');
    return (res.data['items'] as List)
        .map((e) => Contract.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> getContract(String id) async {
    final res = await _dio.get('/api/contracts/$id');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Contract> createContract({
    required String customerId,
    required String title,
    required double amount,
    String? opportunityId,
  }) async {
    final res = await _dio.post('/api/contracts', data: {
      'customerId': customerId,
      'title': title,
      'amount': amount,
      'opportunityId': opportunityId,
    });
    return Contract.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<List<Map<String, dynamic>>> getApprovals() async {
    final res = await _dio.get('/api/approvals');
    return (res.data['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> resolveApproval(String id, bool approved, {String? comment}) async {
    await _dio.post('/api/approvals/$id/resolve', data: {
      'approved': approved,
      'comment': comment,
    });
  }

  Future<List<TaskItem>> getTasks() async {
    final res = await _dio.get('/api/tasks');
    return (res.data['items'] as List)
        .map((e) => TaskItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> completeTask(String id) async {
    await _dio.patch('/api/tasks/$id', data: {'status': 'done'});
  }

  Future<List<Product>> getProducts() async {
    final res = await _dio.get('/api/products');
    return (res.data['items'] as List)
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ReportSummary> getReportSummary({String period = 'month'}) async {
    final res = await _dio.get('/api/reports/summary', queryParameters: {'period': period});
    return ReportSummary.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<List<NotificationItem>> getNotifications() async {
    final res = await _dio.get('/api/notifications');
    return (res.data['items'] as List)
        .map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _dio.patch('/api/notifications/$id/read');
  }
}

final crmRepositoryProvider = Provider<CrmRepository>((ref) {
  return CrmRepository(ref.watch(dioProvider));
});
