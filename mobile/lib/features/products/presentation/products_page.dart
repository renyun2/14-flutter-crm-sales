import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/models.dart';
import '../../../data/repositories/crm_repository.dart';
import '../../shared/presentation/widgets.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  List<Product> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await ref.read(crmRepositoryProvider).getProducts();
    setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('产品价目')),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final p = _items[i];
          return ListTile(
            title: Text(p.name),
            subtitle: Text('${p.sku} · ${p.unit}'),
            trailing: Text(formatMoney(p.unitPrice)),
          );
        },
      ),
    );
  }
}

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  List<NotificationItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await ref.read(crmRepositoryProvider).getNotifications();
    setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('消息')),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final n = _items[i];
          return ListTile(
            leading: Icon(n.readFlag ? Icons.mark_email_read : Icons.mark_email_unread),
            title: Text(n.title),
            subtitle: Text('${n.body}\n${n.createdAt}'),
            isThreeLine: true,
            onTap: () async {
              await ref.read(crmRepositoryProvider).markNotificationRead(n.id);
              await _load();
            },
          );
        },
      ),
    );
  }
}
