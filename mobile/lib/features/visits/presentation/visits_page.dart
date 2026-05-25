import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/storage/visit_draft_storage.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/crm_repository.dart';
import '../../auth/application/auth_provider.dart';
import '../../shared/presentation/widgets.dart';

final visitDraftStorageProvider = Provider((_) => VisitDraftStorage());

class VisitsPage extends ConsumerStatefulWidget {
  const VisitsPage({super.key});

  @override
  ConsumerState<VisitsPage> createState() => _VisitsPageState();
}

class _VisitsPageState extends ConsumerState<VisitsPage> {
  var _calendarView = true;
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final visits = ref.watch(visitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('拜访计划'),
        actions: [
          IconButton(
            icon: Icon(_calendarView ? Icons.list : Icons.calendar_month),
            onPressed: () => setState(() => _calendarView = !_calendarView),
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: () => context.push('/visit/create')),
        ],
      ),
      body: visits.when(
        data: (items) {
          if (_calendarView) {
            final dayVisits = _selected == null
                ? items
                : items.where((v) {
                    final d = DateTime.parse(v.plannedAt);
                    return d.year == _selected!.year && d.month == _selected!.month && d.day == _selected!.day;
                  }).toList();
            return Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focused,
                  selectedDayPredicate: (d) => _selected != null && isSameDay(d, _selected),
                  onDaySelected: (selected, focused) => setState(() {
                    _selected = selected;
                    _focused = focused;
                  }),
                  eventLoader: (day) => items.where((v) {
                    final d = DateTime.parse(v.plannedAt);
                    return d.year == day.year && d.month == day.month && d.day == day.day;
                  }).toList(),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: dayVisits.length,
                    itemBuilder: (_, i) => _VisitTile(visit: dayVisits[i]),
                  ),
                ),
              ],
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) => _VisitTile(visit: items[i]),
          );
        },
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(visitsProvider)),
      ),
    );
  }
}

class _VisitTile extends StatelessWidget {
  const _VisitTile({required this.visit});
  final Visit visit;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(visit.title),
      subtitle: Text('${visit.customerName} · ${visit.plannedAt}'),
      trailing: Text(visit.status),
      onTap: () => context.push('/visit/${visit.id}'),
    );
  }
}

class VisitDetailPage extends ConsumerStatefulWidget {
  const VisitDetailPage({super.key, required this.visitId});
  final String visitId;

  @override
  ConsumerState<VisitDetailPage> createState() => _VisitDetailPageState();
}

class _VisitDetailPageState extends ConsumerState<VisitDetailPage> {
  Visit? _visit;
  final _summary = TextEditingController();
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final visit = await ref.read(crmRepositoryProvider).getVisit(widget.visitId);
    final draft = ref.read(visitDraftStorageProvider).getDraft(widget.visitId);
    setState(() {
      _visit = visit;
      _selectedAddress = visit.address;
      _summary.text = draft ?? visit.summary;
    });
  }

  Future<void> _saveDraft() async {
    await ref.read(visitDraftStorageProvider).saveDraft(widget.visitId, _summary.text);
    if (mounted) showSnack(context, '纪要草稿已暂存');
  }

  Future<void> _checkIn() async {
    if (_selectedAddress == null || _selectedAddress!.isEmpty) {
      showSnack(context, '请选择签到地址');
      return;
    }
    await ref.read(crmRepositoryProvider).checkInVisit(widget.visitId, _selectedAddress!);
    await _load();
  }

  Future<void> _submit() async {
    await ref.read(crmRepositoryProvider).updateVisit(
          widget.visitId,
          status: 'completed',
          summary: _summary.text,
          photoUrls: ['https://example.com/mock-photo.jpg'],
        );
    await ref.read(visitDraftStorageProvider).clearDraft(widget.visitId);
    if (mounted) showSnack(context, '拜访已完成');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final visit = _visit;
    if (visit == null) return const Scaffold(body: LoadingView());

    return Scaffold(
      appBar: AppBar(title: Text(visit.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('客户：${visit.customerName}'),
          Text('计划时间：${visit.plannedAt}'),
          Text('状态：${visit.status}'),
          if (visit.checkInAt != null) Text('签到时间：${visit.checkInAt}'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedAddress,
            decoration: const InputDecoration(labelText: '签到地址（Mock 定位）'),
            items: [
              visit.address,
              '上海市浦东新区世纪大道100号',
              '上海市静安区南京西路200号',
            ].where((e) => e.isNotEmpty).toSet().map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
            onChanged: (v) => setState(() => _selectedAddress = v),
          ),
          ElevatedButton(onPressed: _checkIn, child: const Text('签到')),
          const SizedBox(height: 12),
          TextField(
            controller: _summary,
            decoration: const InputDecoration(labelText: '拜访纪要'),
            maxLines: 5,
            onChanged: (_) => _saveDraft(),
          ),
          Row(
            children: [
              TextButton(onPressed: _saveDraft, child: const Text('保存草稿')),
              ElevatedButton(onPressed: _submit, child: const Text('提交完成')),
            ],
          ),
        ],
      ),
    );
  }
}

class VisitCreatePage extends ConsumerStatefulWidget {
  const VisitCreatePage({super.key});

  @override
  ConsumerState<VisitCreatePage> createState() => _VisitCreatePageState();
}

class _VisitCreatePageState extends ConsumerState<VisitCreatePage> {
  final _title = TextEditingController();
  Customer? _customer;
  DateTime _planned = DateTime.now().add(const Duration(days: 1));

  Future<void> _pickCustomer() async {
    final customers = await ref.read(crmRepositoryProvider).getCustomers();
    if (!mounted) return;
    final picked = await showModalBottomSheet<Customer>(
      context: context,
      builder: (ctx) => ListView(
        children: customers.map((c) => ListTile(title: Text(c.name), onTap: () => Navigator.pop(ctx, c))).toList(),
      ),
    );
    if (picked != null) setState(() => _customer = picked);
  }

  Future<void> _submit() async {
    if (_customer == null || _title.text.trim().isEmpty) {
      showSnack(context, '请选择客户并填写标题');
      return;
    }
    final visit = await ref.read(crmRepositoryProvider).createVisit(
          customerId: _customer!.id,
          title: _title.text.trim(),
          plannedAt: _planned.toIso8601String(),
          address: _customer!.address,
        );
    if (!mounted) return;
    context.replace('/visit/${visit.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新建拜访')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: Text(_customer?.name ?? '选择客户'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickCustomer,
            ),
            TextField(controller: _title, decoration: const InputDecoration(labelText: '标题')),
            ListTile(
              title: const Text('计划时间'),
              subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(_planned)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _planned,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _planned = date);
              },
            ),
            ElevatedButton(onPressed: _submit, child: const Text('创建')),
          ],
        ),
      ),
    );
  }
}
