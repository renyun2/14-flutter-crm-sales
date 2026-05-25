import 'package:flutter/foundation.dart';

@immutable
class CrmUser {
  const CrmUser({
    required this.id,
    required this.employeeNo,
    required this.name,
    required this.role,
    this.managerId,
    this.teamId,
  });

  factory CrmUser.fromJson(Map<String, dynamic> json) => CrmUser(
        id: json['id'] as String,
        employeeNo: json['employee_no'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        managerId: json['manager_id'] as String?,
        teamId: json['team_id'] as String?,
      );

  final String id;
  final String employeeNo;
  final String name;
  final String role;
  final String? managerId;
  final String? teamId;

  bool get isManager => role == 'manager' || role == 'admin';
}

@immutable
class Lead {
  const Lead({
    required this.id,
    required this.title,
    required this.company,
    required this.source,
    required this.status,
    required this.ownerId,
    this.lastFollowAt,
    this.overdue = false,
  });

  factory Lead.fromJson(Map<String, dynamic> json) => Lead(
        id: json['id'] as String,
        title: json['title'] as String,
        company: json['company'] as String,
        source: json['source'] as String,
        status: json['status'] as String,
        ownerId: json['owner_id'] as String,
        lastFollowAt: json['last_follow_at'] as String?,
        overdue: json['overdue'] == true || json['overdue'] == 1,
      );

  final String id;
  final String title;
  final String company;
  final String source;
  final String status;
  final String ownerId;
  final String? lastFollowAt;
  final bool overdue;
}

@immutable
class FollowUp {
  const FollowUp({
    required this.id,
    required this.content,
    required this.createdAt,
    this.userName,
  });

  factory FollowUp.fromJson(Map<String, dynamic> json) => FollowUp(
        id: json['id'] as String,
        content: json['content'] as String,
        createdAt: json['created_at'] as String,
        userName: json['user_name'] as String?,
      );

  final String id;
  final String content;
  final String createdAt;
  final String? userName;
}

@immutable
class Opportunity {
  const Opportunity({
    required this.id,
    required this.title,
    required this.customerId,
    required this.customerName,
    required this.stage,
    required this.stageLabel,
    required this.amount,
    required this.weightedAmount,
    required this.ownerId,
  });

  factory Opportunity.fromJson(Map<String, dynamic> json) => Opportunity(
        id: json['id'] as String,
        title: json['title'] as String,
        customerId: json['customer_id'] as String,
        customerName: json['customer_name'] as String? ?? '',
        stage: json['stage'] as String,
        stageLabel: json['stageLabel'] as String? ?? json['stage'] as String,
        amount: (json['amount'] as num).toDouble(),
        weightedAmount: (json['weighted_amount'] as num).toDouble(),
        ownerId: json['owner_id'] as String,
      );

  final String id;
  final String title;
  final String customerId;
  final String customerName;
  final String stage;
  final String stageLabel;
  final double amount;
  final double weightedAmount;
  final String ownerId;
}

@immutable
class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.industry,
    required this.address,
    required this.tags,
    required this.ownerId,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as String,
        name: json['name'] as String,
        industry: json['industry'] as String? ?? '',
        address: json['address'] as String? ?? '',
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        ownerId: json['owner_id'] as String,
      );

  final String id;
  final String name;
  final String industry;
  final String address;
  final List<String> tags;
  final String ownerId;
}

@immutable
class Contact {
  const Contact({
    required this.id,
    required this.customerId,
    required this.name,
    required this.phone,
    required this.title,
  });

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json['id'] as String,
        customerId: json['customer_id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String? ?? '',
        title: json['title'] as String? ?? '',
      );

  final String id;
  final String customerId;
  final String name;
  final String phone;
  final String title;
}

@immutable
class Visit {
  const Visit({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.title,
    required this.plannedAt,
    required this.status,
    required this.address,
    this.checkInAt,
    this.summary = '',
    this.photoUrls = const [],
  });

  factory Visit.fromJson(Map<String, dynamic> json) => Visit(
        id: json['id'] as String,
        customerId: json['customer_id'] as String,
        customerName: json['customer_name'] as String? ?? '',
        title: json['title'] as String,
        plannedAt: json['planned_at'] as String,
        status: json['status'] as String,
        address: json['address'] as String? ?? '',
        checkInAt: json['check_in_at'] as String?,
        summary: json['summary'] as String? ?? '',
        photoUrls: (json['photoUrls'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
      );

  final String id;
  final String customerId;
  final String customerName;
  final String title;
  final String plannedAt;
  final String status;
  final String address;
  final String? checkInAt;
  final String summary;
  final List<String> photoUrls;
}

@immutable
class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.dueAt,
    required this.status,
    required this.overdue,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
        id: json['id'] as String,
        title: json['title'] as String,
        dueAt: json['due_at'] as String,
        status: json['status'] as String,
        overdue: json['overdue'] == true || json['overdue'] == 1,
      );

  final String id;
  final String title;
  final String dueAt;
  final String status;
  final bool overdue;
}

@immutable
class Contract {
  const Contract({
    required this.id,
    required this.title,
    required this.customerName,
    required this.amount,
    required this.status,
    this.approvalStatus,
  });

  factory Contract.fromJson(Map<String, dynamic> json) => Contract(
        id: json['id'] as String,
        title: json['title'] as String,
        customerName: json['customer_name'] as String? ?? '',
        amount: (json['amount'] as num).toDouble(),
        status: json['status'] as String,
        approvalStatus: json['approval_status'] as String?,
      );

  final String id;
  final String title;
  final String customerName;
  final double amount;
  final String status;
  final String? approvalStatus;
}

@immutable
class Quote {
  const Quote({
    required this.id,
    required this.title,
    required this.total,
    required this.discount,
    required this.opportunityId,
    this.items = const [],
  });

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
        id: json['id'] as String,
        title: json['title'] as String,
        total: (json['total'] as num).toDouble(),
        discount: (json['discount'] as num?)?.toDouble() ?? 0,
        opportunityId: json['opportunity_id'] as String,
        items: (json['items'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            const [],
      );

  final String id;
  final String title;
  final double total;
  final double discount;
  final String opportunityId;
  final List<Map<String, dynamic>> items;
}

@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.unitPrice,
    required this.unit,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        sku: json['sku'] as String,
        unitPrice: (json['unit_price'] as num).toDouble(),
        unit: json['unit'] as String? ?? '套',
      );

  final String id;
  final String name;
  final String sku;
  final double unitPrice;
  final String unit;
}

@immutable
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.readFlag,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: json['type'] as String,
        readFlag: json['read_flag'] == 1,
        createdAt: json['created_at'] as String,
      );

  final String id;
  final String title;
  final String body;
  final String type;
  final bool readFlag;
  final String createdAt;
}

@immutable
class ReportSummary {
  const ReportSummary({
    required this.funnel,
    required this.trend,
    required this.ranking,
    required this.kpis,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) => ReportSummary(
        funnel: (json['funnel'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        trend: (json['trend'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        ranking: (json['ranking'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        kpis: Map<String, dynamic>.from(json['kpis'] as Map),
      );

  final List<Map<String, dynamic>> funnel;
  final List<Map<String, dynamic>> trend;
  final List<Map<String, dynamic>> ranking;
  final Map<String, dynamic> kpis;
}

const opportunityStages = [
  ('initial', '初步接触'),
  ('qualification', '需求确认'),
  ('proposal', '方案报价'),
  ('negotiation', '谈判'),
  ('won', '赢单'),
  ('lost', '输单'),
];
