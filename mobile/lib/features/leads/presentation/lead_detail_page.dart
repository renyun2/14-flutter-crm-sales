import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/models.dart';
import '../../../data/repositories/crm_repository.dart';
import '../../shared/presentation/widgets.dart';

class LeadDetailPage extends ConsumerStatefulWidget {
  const LeadDetailPage({super.key, required this.leadId});
  final String leadId;

  @override
  ConsumerState<LeadDetailPage> createState() => _LeadDetailPageState();
}

class _LeadDetailPageState extends ConsumerState<LeadDetailPage> {
  final _followCtrl = TextEditingController();
  Lead? _lead;
  List<FollowUp> _followUps = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(crmRepositoryProvider).getLead(widget.leadId);
      setState(() {
        _lead = data.lead;
        _followUps = data.followUps;
      });
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addFollowUp() async {
    if (_followCtrl.text.trim().isEmpty) return;
    await ref.read(crmRepositoryProvider).addFollowUp(widget.leadId, _followCtrl.text.trim());
    _followCtrl.clear();
    await _load();
  }

  Future<void> _convert() async {
    final result = await ref.read(crmRepositoryProvider).convertLead(widget.leadId);
    if (!mounted) return;
    showSnack(context, '已转化为商机');
    context.push('/opportunity/${result.opportunityId}');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingView());
    final lead = _lead;
    if (lead == null) return const Scaffold(body: Center(child: Text('线索不存在')));

    return Scaffold(
      appBar: AppBar(title: Text(lead.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('公司：${lead.company}'),
          Text('来源：${lead.source} · 状态：${lead.status}'),
          if (lead.overdue) const Chip(label: Text('逾期')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _convert, child: const Text('转化商机')),
          const Divider(),
          const Text('跟进记录', style: TextStyle(fontWeight: FontWeight.bold)),
          ..._followUps.map(
            (f) => ListTile(
              title: Text(f.content),
              subtitle: Text('${f.userName ?? ''} · ${f.createdAt}'),
            ),
          ),
          TextField(
            controller: _followCtrl,
            decoration: const InputDecoration(
              labelText: '新增跟进（支持 @提及 Mock）',
              hintText: '例如：已电话沟通 @张经理',
            ),
            maxLines: 3,
          ),
          ElevatedButton(onPressed: _addFollowUp, child: const Text('提交跟进')),
        ],
      ),
    );
  }
}

class LeadCreatePage extends ConsumerStatefulWidget {
  const LeadCreatePage({super.key});

  @override
  ConsumerState<LeadCreatePage> createState() => _LeadCreatePageState();
}

class _LeadCreatePageState extends ConsumerState<LeadCreatePage> {
  final _title = TextEditingController();
  final _company = TextEditingController();
  final _source = TextEditingController(text: '官网');

  Future<void> _submit() async {
    final lead = await ref.read(crmRepositoryProvider).createLead(
          title: _title.text.trim(),
          company: _company.text.trim(),
          source: _source.text.trim(),
        );
    if (!mounted) return;
    context.replace('/lead/${lead.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新建线索')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _title, decoration: const InputDecoration(labelText: '标题')),
            TextField(controller: _company, decoration: const InputDecoration(labelText: '公司')),
            TextField(controller: _source, decoration: const InputDecoration(labelText: '来源')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _submit, child: const Text('保存')),
          ],
        ),
      ),
    );
  }
}
