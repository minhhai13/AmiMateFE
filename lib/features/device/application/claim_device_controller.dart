import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../data/models/claim_device_request.dart';
import 'device_controller.dart';

class ClaimDeviceState {
  const ClaimDeviceState({
    this.isSubmitting = false,
    this.failureMessage,
  });

  final bool isSubmitting;
  final String? failureMessage;
}

final claimDeviceControllerProvider =
    NotifierProvider<ClaimDeviceController, ClaimDeviceState>(
      ClaimDeviceController.new,
    );

class ClaimDeviceController extends Notifier<ClaimDeviceState> {
  @override
  ClaimDeviceState build() => const ClaimDeviceState();

  Future<bool> claim(ClaimDeviceRequest request) async {
    state = const ClaimDeviceState(isSubmitting: true);
    try {
      await ref.read(deviceRepositoryProvider).claimDevice(request);
      state = const ClaimDeviceState();
      return true;
    } on ApiFailure catch (failure) {
      state = ClaimDeviceState(failureMessage: failure.message);
      return false;
    } on FormatException {
      state = const ClaimDeviceState(
        failureMessage: 'Máy chủ trả về thông tin thiết bị không hợp lệ.',
      );
      return false;
    }
  }
}
