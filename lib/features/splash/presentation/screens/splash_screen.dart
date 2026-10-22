import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/application/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authControllerProvider.notifier).restoreSession();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 58,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'AmiMate',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                if (authState.status == AuthSessionStatus.checking)
                  const CircularProgressIndicator()
                else if (authState.status == AuthSessionStatus.error) ...[
                  Text(
                    authState.failureMessage ??
                        'Không thể kiểm tra phiên đăng nhập.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref
                        .read(authControllerProvider.notifier)
                        .restoreSession(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
