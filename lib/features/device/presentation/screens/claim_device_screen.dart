import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/claim_device_controller.dart';
import '../../data/models/claim_device_request.dart';

class ClaimDeviceScreen extends ConsumerStatefulWidget {
  const ClaimDeviceScreen({super.key});

  @override
  ConsumerState<ClaimDeviceScreen> createState() => _ClaimDeviceScreenState();
}

class _ClaimDeviceScreenState extends ConsumerState<ClaimDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deviceIdController = TextEditingController();
  final _pinCodeController = TextEditingController();

  @override
  void dispose() {
    _deviceIdController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final claimState = ref.watch(claimDeviceControllerProvider);

    ref.listen(claimDeviceControllerProvider, (previous, next) {
      if (previous?.failureMessage != next.failureMessage &&
          next.failureMessage != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.failureMessage!),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
      if (previous?.isSubmitting == true &&
          !next.isSubmitting &&
          next.failureMessage == null) {
        Navigator.of(context).pop(true);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Thêm thiết bị')),
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
                    Container(
                      width: 76,
                      height: 76,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        Icons.add_link_rounded,
                        size: 38,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Kết nối robot AmiMate',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nhập Device ID và mã PIN trên nhãn của robot.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 26),
                    TextFormField(
                      key: const Key('claim-device-id'),
                      controller: _deviceIdController,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'Device ID',
                        hintText: 'Ví dụ: AMI-123456',
                        prefixIcon: Icon(Icons.devices_other_outlined),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Vui lòng nhập Device ID.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('claim-pin-code'),
                      controller: _pinCodeController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Mã PIN',
                        hintText: 'Nhập 6 chữ số',
                        prefixIcon: Icon(Icons.pin_outlined),
                      ),
                      validator: (value) {
                        final pinCode = value ?? '';
                        if (pinCode.isEmpty) return 'Vui lòng nhập mã PIN.';
                        if (!RegExp(r'^\d{6}$').hasMatch(pinCode)) {
                          return 'Mã PIN phải gồm đúng 6 chữ số.';
                        }
                        return null;
                      },
                      onFieldSubmitted:
                          claimState.isSubmitting ? null : (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('claim-submit'),
                      onPressed: claimState.isSubmitting ? null : _submit,
                      child: claimState.isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Liên kết thiết bị'),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(claimDeviceControllerProvider.notifier)
        .claim(
          ClaimDeviceRequest(
            deviceId: _deviceIdController.text,
            pinCode: _pinCodeController.text,
          ),
        );
  }
}
