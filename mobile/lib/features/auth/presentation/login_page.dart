import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_provider.dart';
import '../../shared/presentation/widgets.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _employeeNo = TextEditingController(text: 'S001');
  final _password = TextEditingController(text: '123456');
  var _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).login(_employeeNo.text.trim(), _password.text);
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _employeeNo,
              decoration: const InputDecoration(labelText: '工号', hintText: 'S001 / M001 / A001'),
            ),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: '密码'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: Text(_loading ? '登录中...' : '登录'),
              ),
            ),
            const SizedBox(height: 12),
            const Text('测试账号：S001/M001/A001，密码 123456', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
