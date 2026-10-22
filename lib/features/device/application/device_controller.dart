import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/models/device_response.dart';
import '../data/repositories/device_repository.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(ref.watch(dioProvider));
});

final deviceListProvider =
    AsyncNotifierProvider.autoDispose<DeviceController, List<DeviceResponse>>(
      DeviceController.new,
      retry: (_, _) => null,
    );

class DeviceController extends AsyncNotifier<List<DeviceResponse>> {
  @override
  Future<List<DeviceResponse>> build() {
    return ref.watch(deviceRepositoryProvider).getMyDevices();
  }

  Future<void> reload() async {
    state = const AsyncLoading<List<DeviceResponse>>();
    state = await AsyncValue.guard(
      () => ref.read(deviceRepositoryProvider).getMyDevices(),
    );
  }
}
