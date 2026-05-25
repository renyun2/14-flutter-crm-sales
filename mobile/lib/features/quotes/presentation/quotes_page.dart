import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/models.dart';
import '../../../data/repositories/crm_repository.dart';
import '../../shared/presentation/widgets.dart';

class QuotesPage extends ConsumerStatefulWidget {
  const QuotesPage({super.key});

  @override
  ConsumerState<QuotesPage> createState() => _QuotesPageState();
}

class _QuotesPageState extends ConsumerState<QuotesPage> {
  List<Quote> _items = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await ref.read(crmRepositoryProvider).getQuotes();
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('报价列表')),
      body: _loading
          ? const LoadingView()
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final q = _items[i];
                return ListTile(
                  title: Text(q.title),
                  subtitle: Text('折扣 ${(q.discount * 100).toStringAsFixed(0)}%'),
                  trailing: Text(formatMoney(q.total)),
                  onTap: () => context.push('/quote/${q.id}'),
                );
              },
            ),
    );
  }
}

class QuoteEditPage extends ConsumerStatefulWidget {
  const QuoteEditPage({super.key, required this.quoteId});
  final String quoteId;

  @override
  ConsumerState<QuoteEditPage> createState() => _QuoteEditPageState();
}

class _QuoteEditPageState extends ConsumerState<QuoteEditPage> {
  Quote? _quote;
  final _title = TextEditingController();
  var _discount = 0.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final quote = await ref.read(crmRepositoryProvider).getQuote(widget.quoteId);
    setState(() {
      _quote = quote;
      _title.text = quote.title;
      _discount = quote.discount;
    });
  }

  Future<void> _save() async {
    if (_discount < 0 || _discount > 0.3) {
      showSnack(context, '折扣需在 0-30% 之间');
      return;
    }
    await ref.read(crmRepositoryProvider).updateQuote(
          widget.quoteId,
          title: _title.text.trim(),
          discount: _discount,
        );
    if (mounted) showSnack(context, '已保存');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final quote = _quote;
    if (quote == null) return const Scaffold(body: LoadingView());

    return Scaffold(
      appBar: AppBar(title: const Text('报价编辑')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: '标题')),
          Text('合计：${formatMoney(quote.total)}'),
          Slider(
            value: _discount,
            min: 0,
            max: 0.3,
            divisions: 30,
            label: '${(_discount * 100).toStringAsFixed(0)}%',
            onChanged: (v) => setState(() => _discount = v),
          ),
          const Text('行项目'),
          ...quote.items.map(
            (item) => ListTile(
              title: Text(item['product_name']?.toString() ?? ''),
              subtitle: Text('数量 ${item['quantity']}'),
              trailing: Text(formatMoney((item['unit_price'] as num).toDouble())),
            ),
          ),
          ElevatedButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
    );
  }
}
