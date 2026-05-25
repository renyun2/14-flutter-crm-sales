import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/crm_repository.dart';
import '../../auth/application/auth_provider.dart';
import '../../shared/presentation/widgets.dart';

class TasksPage extends ConsumerWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('任务中心')),
      body: tasks.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final t = items[i];
            return ListTile(
              title: Text(t.title),
              subtitle: Text(t.dueAt),
              trailing: t.overdue
                  ? const Chip(label: Text('逾期'))
                  : t.status == 'done'
                      ? const Icon(Icons.check)
                      : IconButton(
                          icon: const Icon(Icons.done),
                          onPressed: () async {
                            await ref.read(crmRepositoryProvider).completeTask(t.id);
                            ref.invalidate(tasksProvider);
                          },
                        ),
            );
          },
        ),
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(tasksProvider)),
      ),
    );
  }
}
