import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/models.dart';
import '../../../data/repositories/crm_repository.dart';
import '../../shared/presentation/widgets.dart';

class ContractsPage extends ConsumerStatefulWidget {
  const ContractsPage({super.key});

  @override
  ConsumerState<ContractsPage> createState() => _ContractsPageState();
}

class _ContractsPageState extends ConsumerState<ContractsPage> {
  List<Contract> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await ref.read(crmRepositoryProvider).getContracts();
    setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('合同列表')),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final c = _items[i];
          return ListTile(
            title: Text(c.title),
            subtitle: Text('${c.customerName} · ${c.status}'),
            trailing: Text(formatMoney(c.amount)),
            onTap: () => context.push('/contract/${c.id}'),
          );
        },
      ),
    );
  }
}

class ContractDetailPage extends ConsumerStatefulWidget {
  const ContractDetailPage({super.key, required this.contractId});
  final String contractId;

  @override
  ConsumerState<ContractDetailPage> createState() => _ContractDetailPageState();
}

class _ContractDetailPageState extends ConsumerState<ContractDetailPage> {
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ref.read(crmRepositoryProvider).getContract(widget.contractId);
    setState(() => _data = data);
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) return const Scaffold(body: LoadingView());
    final approvals = (data['approvals'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(data['title'] as String)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('客户：${data['customer_name']}'),
          Text('金额：${formatMoney((data['amount'] as num).toDouble())}'),
          Text('状态：${data['status']}'),
          if (data['approval_status'] != null) Text('审批：${data['approval_status']}'),
          const Divider(),
          const Text('审批流', style: TextStyle(fontWeight: FontWeight.bold)),
          ...approvals.map(
            (a) => ListTile(
              title: Text(a['status'] as String),
              subtitle: Text('${a['requester_name'] ?? ''} · ${a['created_at']}'),
            ),
          ),
        ],
      ),
    );
  }
}

class ApprovalsPage extends ConsumerStatefulWidget {
  const ApprovalsPage({super.key});

  @override
  ConsumerState<ApprovalsPage> createState() => _ApprovalsPageState();
}

class _ApprovalsPageState extends ConsumerState<ApprovalsPage> {
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await ref.read(crmRepositoryProvider).getApprovals();
      setState(() => _items = items);
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    }
  }

  Future<void> _resolve(String id, bool approved) async {
    await ref.read(crmRepositoryProvider).resolveApproval(id, approved, comment: approved ? '同意' : '驳回');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('审批中心')),
      body: _items.isEmpty
          ? const Center(child: Text('暂无待审批'))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final a = _items[i];
                return ListTile(
                  title: Text(a['contract_title'] as String? ?? ''),
                  subtitle: Text('${a['requester_name']} · ${formatMoney((a['amount'] as num).toDouble())}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.check), onPressed: () => _resolve(a['id'] as String, true)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => _resolve(a['id'] as String, false)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
