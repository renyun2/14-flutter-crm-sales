import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth?.user;

    return Scaffold(
      appBar: AppBar(title: const Text('个人中心')),
      body: ListView(
        children: [
          ListTile(
            title: Text(user?.name ?? ''),
            subtitle: Text('工号 ${user?.employeeNo ?? ''} · 角色 ${user?.role ?? ''}'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('消息通知'),
            onTap: () => context.push('/notifications'),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('业绩报表'),
            onTap: () => context.push('/reports'),
          ),
          if (user?.isManager == true)
            ListTile(
              leading: const Icon(Icons.approval),
              title: const Text('审批中心'),
              onTap: () => context.push('/approvals'),
            ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('退出登录'),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
