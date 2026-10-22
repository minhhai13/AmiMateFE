import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../auth/application/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.settings_outlined,
                      size: 32,
                      color: Color(0xFF1677D2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'AmiMate',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Quản lý robot và lịch sử hội thoại của gia đình bạn.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Tài khoản', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('settings-sign-out'),
              onPressed: authState.isSubmitting
                  ? null
                  : () => _confirmSignOut(context, ref),
              icon: authState.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout),
              label: Text(
                authState.isSubmitting ? 'Đang đăng xuất...' : 'Đăng xuất',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
            ),
            if (authState.failureMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                authState.failureMessage!,
                key: const Key('settings-auth-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất khỏi AmiMate?'),
        content: const Text(
          'Bạn sẽ cần đăng nhập lại để xem thiết bị và lịch sử hội thoại.',
        ),
        actions: [
          TextButton(
            key: const Key('settings-sign-out-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            key: const Key('settings-sign-out-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(authControllerProvider.notifier).signOut();
    if (!context.mounted) return;

    final authState = ref.read(authControllerProvider);
    if (authState.status == AuthSessionStatus.unauthenticated) {
      context.goNamed(AppRouteNames.login);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            authState.failureMessage ??
                'Không thể đăng xuất. Vui lòng thử lại.',
          ),
        ),
      );
  }
}
