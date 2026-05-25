import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            ElevatedButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ],
      ),
    );
  }
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String formatMoney(num value) => '¥${value.toStringAsFixed(0)}';

Future<void> showMockCallDialog(BuildContext context, String phone) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Mock 外呼'),
      content: Text('正在模拟拨打 $phone ...'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('挂断')),
      ],
    ),
  );
}
