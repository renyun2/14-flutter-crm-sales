import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/models.dart';
import '../../../data/repositories/crm_repository.dart';
import '../../auth/application/auth_provider.dart';
import '../../shared/presentation/widgets.dart';

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  final _search = TextEditingController();
  String? _tag;

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider(_search.text.trim().isEmpty ? null : _search.text.trim()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('客户列表'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => context.push('/customer/create')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                labelText: '搜索客户',
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: () => setState(() {})),
              ),
              onSubmitted: (_) => setState(() {}),
            ),
          ),
          Wrap(
            spacing: 8,
            children: ['重点客户', 'VIP'].map((tag) {
              return FilterChip(
                label: Text(tag),
                selected: _tag == tag,
                onSelected: (_) => setState(() => _tag = _tag == tag ? null : tag),
              );
            }).toList(),
          ),
          Expanded(
            child: customers.when(
              data: (items) {
                final filtered = _tag == null ? items : items.where((c) => c.tags.contains(_tag)).toList();
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final c = filtered[i];
                    return ListTile(
                      title: Text(c.name),
                      subtitle: Text('${c.industry} · ${c.address}'),
                      trailing: c.tags.isNotEmpty ? Chip(label: Text(c.tags.first)) : null,
                      onTap: () => context.push('/customer/${c.id}'),
                    );
                  },
                );
              },
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(customersProvider(null))),
            ),
          ),
        ],
      ),
    );
  }
}

class Customer360Page extends ConsumerStatefulWidget {
  const Customer360Page({super.key, required this.customerId});
  final String customerId;

  @override
  ConsumerState<Customer360Page> createState() => _Customer360PageState();
}

class _Customer360PageState extends ConsumerState<Customer360Page> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _data;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final data = await ref.read(crmRepositoryProvider).getCustomer360(widget.customerId);
    setState(() => _data = data);
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) return const Scaffold(body: LoadingView());

    return Scaffold(
      appBar: AppBar(
        title: Text(data['name'] as String),
        actions: [
          IconButton(
            icon: const Icon(Icons.contacts),
            onPressed: () => context.push('/customer/${widget.customerId}/contacts'),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: '商机'),
            Tab(text: '合同'),
            Tab(text: '拜访'),
            Tab(text: '线索'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ListTab(items: (data['opportunities'] as List?) ?? [], titleKey: 'title'),
          _ListTab(items: (data['contracts'] as List?) ?? [], titleKey: 'title'),
          _ListTab(items: (data['visits'] as List?) ?? [], titleKey: 'title'),
          _ListTab(items: (data['leads'] as List?) ?? [], titleKey: 'title'),
        ],
      ),
    );
  }
}

class _ListTab extends StatelessWidget {
  const _ListTab({required this.items, required this.titleKey});
  final List<dynamic> items;
  final String titleKey;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('暂无数据'));
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = Map<String, dynamic>.from(items[i] as Map);
        return ListTile(title: Text(item[titleKey]?.toString() ?? ''));
      },
    );
  }
}

class CustomerCreatePage extends ConsumerStatefulWidget {
  const CustomerCreatePage({super.key});

  @override
  ConsumerState<CustomerCreatePage> createState() => _CustomerCreatePageState();
}

class _CustomerCreatePageState extends ConsumerState<CustomerCreatePage> {
  final _name = TextEditingController();
  final _industry = TextEditingController();
  final _address = TextEditingController();

  Future<void> _submit() async {
    final c = await ref.read(crmRepositoryProvider).createCustomer(
          name: _name.text.trim(),
          industry: _industry.text.trim(),
          address: _address.text.trim(),
        );
    if (!mounted) return;
    context.replace('/customer/${c.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新建客户')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: '客户名称')),
            TextField(controller: _industry, decoration: const InputDecoration(labelText: '行业')),
            TextField(controller: _address, decoration: const InputDecoration(labelText: '地址')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _submit, child: const Text('保存')),
          ],
        ),
      ),
    );
  }
}

class ContactsPage extends ConsumerStatefulWidget {
  const ContactsPage({super.key, required this.customerId});
  final String customerId;

  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage> {
  List<Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await ref.read(crmRepositoryProvider).getContacts(widget.customerId);
    setState(() => _contacts = items);
  }

  Future<void> _add() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新增联系人'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '姓名')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: '电话')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(crmRepositoryProvider).createContact(
          customerId: widget.customerId,
          name: nameCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
        );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('联系人'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _add)],
      ),
      body: ListView.builder(
        itemCount: _contacts.length,
        itemBuilder: (_, i) {
          final c = _contacts[i];
          return ListTile(
            title: Text(c.name),
            subtitle: Text('${c.title} · ${c.phone}'),
            trailing: IconButton(
              icon: const Icon(Icons.phone),
              onPressed: () => showMockCallDialog(context, c.phone),
            ),
          );
        },
      ),
    );
  }
}
