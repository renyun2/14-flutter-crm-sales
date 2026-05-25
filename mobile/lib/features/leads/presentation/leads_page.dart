import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/crm_repository.dart';
import '../../shared/presentation/widgets.dart';

class LeadsPage extends ConsumerStatefulWidget {
  const LeadsPage({super.key});

  @override
  ConsumerState<LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends ConsumerState<LeadsPage> {
  String? _status;
  var _overdueOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('线索列表'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => context.push('/lead/create')),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('逾期'),
                  selected: _overdueOnly,
                  onSelected: (v) => setState(() => _overdueOnly = v),
                ),
                ...['new', 'contacted', 'qualified'].map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text(s),
                      selected: _status == s,
                      onSelected: (_) => setState(() => _status = _status == s ? null : s),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: ref.read(crmRepositoryProvider).getLeads(status: _status, overdue: _overdueOnly ? true : null),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) return const LoadingView();
                if (snap.hasError) return ErrorView(message: snap.error.toString());
                final items = snap.data ?? [];
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final lead = items[i];
                    return ListTile(
                      title: Text(lead.title),
                      subtitle: Text('${lead.company} · ${lead.source}'),
                      trailing: lead.overdue ? const Chip(label: Text('逾期')) : Text(lead.status),
                      onTap: () => context.push('/lead/${lead.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
