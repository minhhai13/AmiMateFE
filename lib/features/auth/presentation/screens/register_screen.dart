import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../application/auth_controller.dart';
import '../../data/models/auth_request.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isSubmitting = authState.isSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo tài khoản')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Bắt đầu cùng AmiMate',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tạo tài khoản phụ huynh để kết nối với robot của bé.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      key: const Key('register-email'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newUsername],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('register-password'),
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onFieldSubmitted: isSubmitting ? null : (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        helperText: 'Từ 8 đến 72 ký tự.',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _passwordVisible
                              ? 'Ẩn mật khẩu'
                              : 'Hiện mật khẩu',
                          onPressed: () => setState(
                            () => _passwordVisible = !_passwordVisible,
                          ),
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    if (authState.failureMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        authState.failureMessage!,
                        key: const Key('auth-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('register-submit'),
                      onPressed: isSubmitting ? null : _submit,
                      child: isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Tạo tài khoản'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: isSubmitting
                          ? null
                          : () => context.goNamed(AppRouteNames.login),
                      child: const Text('Đã có tài khoản? Đăng nhập'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Vui lòng nhập email.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Vui lòng nhập email hợp lệ.';
    }
    if (email.length > 255) return 'Email không được vượt quá 255 ký tự.';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Vui lòng nhập mật khẩu.';
    if (password.length < 8 || password.length > 72) {
      return 'Mật khẩu phải có từ 8 đến 72 ký tự.';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(authControllerProvider.notifier)
        .register(
          AuthRequest(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }
}
