import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_provider.dart';
import '../../shared/presentation/widgets.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final tasks = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('工作台')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('你好，${auth?.user.name ?? ''}（${auth?.user.role ?? ''}）'),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('业绩摘要'),
              subtitle: tasks.when(
                data: (items) => Text('待办 ${items.where((t) => t.status != 'done').length} 项'),
                loading: () => const Text('加载中...'),
                error: (e, _) => Text(e.toString()),
              ),
              trailing: TextButton(onPressed: () => context.push('/reports'), child: const Text('查看报表')),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Shortcut('线索', Icons.leaderboard, () => context.push('/leads')),
              _Shortcut('拜访', Icons.event, () => context.push('/visits')),
              _Shortcut('任务', Icons.task, () => context.push('/tasks')),
              _Shortcut('合同', Icons.description, () => context.push('/contracts')),
              _Shortcut('报价', Icons.request_quote, () => context.push('/quotes')),
              _Shortcut('产品', Icons.inventory, () => context.push('/products')),
              _Shortcut('消息', Icons.notifications, () => context.push('/notifications')),
              if (auth?.user.isManager == true)
                _Shortcut('审批', Icons.approval, () => context.push('/approvals')),
            ],
          ),
          const SizedBox(height: 16),
          const Text('今日待办', style: TextStyle(fontWeight: FontWeight.bold)),
          tasks.when(
            data: (items) => Column(
              children: items
                  .where((t) => t.status != 'done')
                  .take(5)
                  .map(
                    (t) => ListTile(
                      title: Text(t.title),
                      subtitle: Text(t.dueAt),
                      trailing: t.overdue ? const Chip(label: Text('逾期')) : null,
                      onTap: () => context.push('/tasks'),
                    ),
                  )
                  .toList(),
            ),
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(tasksProvider)),
          ),
        ],
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 88,
        child: Column(
          children: [Icon(icon), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 12))],
        ),
      ),
    );
  }
}
