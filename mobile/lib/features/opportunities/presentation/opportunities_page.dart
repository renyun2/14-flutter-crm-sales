import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/models.dart';
import '../../../data/repositories/crm_repository.dart';
import '../../shared/presentation/widgets.dart';

class OpportunitiesPage extends ConsumerStatefulWidget {
  const OpportunitiesPage({super.key});

  @override
  ConsumerState<OpportunitiesPage> createState() => _OpportunitiesPageState();
}

class _OpportunitiesPageState extends ConsumerState<OpportunitiesPage> {
  Map<String, List<Opportunity>> _byStage = {};
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(crmRepositoryProvider).getOpportunities();
      setState(() => _byStage = data.byStage);
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _move(Opportunity opp, String newStage) async {
    try {
      await ref.read(crmRepositoryProvider).updateOpportunityStage(opp.id, newStage);
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('商机看板')),
      body: _loading
          ? const LoadingView()
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: opportunityStages.map((stage) {
                  final key = stage.$1;
                  final label = stage.$2;
                  final items = _byStage[key] ?? [];
                  return DragTarget<Opportunity>(
                    onWillAcceptWithDetails: (_) => true,
                    onAcceptWithDetails: (details) => _move(details.data, key),
                    builder: (context, candidate, rejected) {
                      return Container(
                        width: 240,
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        color: candidate.isNotEmpty ? Colors.blue.shade50 : Colors.grey.shade100,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$label (${items.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...items.map(
                              (opp) => Draggable<Opportunity>(
                                data: opp,
                                feedback: Material(
                                  elevation: 4,
                                  child: SizedBox(
                                    width: 200,
                                    child: ListTile(title: Text(opp.title)),
                                  ),
                                ),
                                childWhenDragging: Opacity(opacity: 0.4, child: _OppCard(opp: opp)),
                                child: _OppCard(
                                  opp: opp,
                                  onTap: () => context.push('/opportunity/${opp.id}'),
                                  onAdvance: () {
                                    final idx = opportunityStages.indexWhere((s) => s.$1 == opp.stage);
                                    if (idx >= 0 && idx < opportunityStages.length - 1) {
                                      _move(opp, opportunityStages[idx + 1].$1);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
    );
  }
}

class _OppCard extends ConsumerWidget {
  const _OppCard({required this.opp, this.onTap, this.onAdvance});
  final Opportunity opp;
  final VoidCallback? onTap;
  final VoidCallback? onAdvance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(opp.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(opp.customerName),
              Text(formatMoney(opp.amount)),
              if (onAdvance != null)
                TextButton(onPressed: onAdvance, child: const Text('推进阶段')),
            ],
          ),
        ),
      ),
    );
  }
}

class OpportunityDetailPage extends ConsumerStatefulWidget {
  const OpportunityDetailPage({super.key, required this.opportunityId});
  final String opportunityId;

  @override
  ConsumerState<OpportunityDetailPage> createState() => _OpportunityDetailPageState();
}

class _OpportunityDetailPageState extends ConsumerState<OpportunityDetailPage> {
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ref.read(crmRepositoryProvider).getOpportunity(widget.opportunityId);
    setState(() => _data = data);
  }

  Future<void> _advance(String stage) async {
    await ref.read(crmRepositoryProvider).updateOpportunityStage(widget.opportunityId, stage);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) return const Scaffold(body: LoadingView());
    final quotes = (data['quotes'] as List?) ?? [];
    return Scaffold(
      appBar: AppBar(title: Text(data['title'] as String)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('阶段：${data['stageLabel'] ?? data['stage']}'),
          Text('金额：${formatMoney((data['amount'] as num).toDouble())}'),
          Text('加权：${formatMoney((data['weighted_amount'] as num).toDouble())}'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: opportunityStages.map((s) {
              return OutlinedButton(
                onPressed: () => _advance(s.$1),
                child: Text(s.$2),
              );
            }).toList(),
          ),
          const Divider(),
          const Text('关联报价'),
          ...quotes.map(
            (q) => ListTile(
              title: Text(q['title'] as String),
              subtitle: Text(formatMoney((q['total'] as num).toDouble())),
              onTap: () => context.push('/quote/${q['id']}'),
            ),
          ),
        ],
      ),
    );
  }
}
