import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/router/app_router.dart';
import '../../application/device_controller.dart';
import '../../data/models/device_response.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(deviceListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiết bị của tôi'),
        actions: [
          IconButton(
            key: const Key('dashboard-settings'),
            tooltip: 'Cài đặt',
            onPressed: () => context.pushNamed(AppRouteNames.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: devices.when(
          loading: () => const Center(
            child: CircularProgressIndicator(key: Key('devices-loading')),
          ),
          error: (error, stackTrace) => _DeviceErrorState(
            message: _errorMessage(error),
            onRetry: () => ref.read(deviceListProvider.notifier).reload(),
          ),
          data: (items) => items.isEmpty
              ? _EmptyDevicesState(onAddDevice: () => _openClaim(context, ref))
              : _DeviceList(
                  devices: items,
                  onRefresh: () =>
                      ref.read(deviceListProvider.notifier).reload(),
                  onSelect: (device) => context.pushNamed(
                    AppRouteNames.chatHistory,
                    pathParameters: {'deviceId': device.deviceId},
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('dashboard-add-device'),
        onPressed: () => _openClaim(context, ref),
        icon: const Icon(Icons.add_link_rounded),
        label: const Text('Thêm thiết bị'),
      ),
    );
  }

  Future<void> _openClaim(BuildContext context, WidgetRef ref) async {
    await context.pushNamed(AppRouteNames.claimDevice);
    if (context.mounted) {
      await ref.read(deviceListProvider.notifier).reload();
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiFailure) return error.message;
    return 'Không thể tải danh sách thiết bị. Vui lòng thử lại.';
  }
}

class _DeviceList extends StatelessWidget {
  const _DeviceList({
    required this.devices,
    required this.onRefresh,
    required this.onSelect,
  });

  final List<DeviceResponse> devices;
  final Future<void> Function() onRefresh;
  final ValueChanged<DeviceResponse> onSelect;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        key: const Key('device-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        itemCount: devices.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final device = devices[index];
          return _DeviceCard(device: device, onTap: () => onSelect(device));
        },
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device, required this.onTap});

  final DeviceResponse device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final localCreatedAt = device.createdAt.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final createdDate = localizations.formatMediumDate(localCreatedAt);
    final createdTime = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localCreatedAt),
    );

    return Card(
      child: InkWell(
        key: Key('device-${device.deviceId}'),
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.smart_toy_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.deviceId,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Đã kết nối $createdDate · $createdTime',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDevicesState extends StatelessWidget {
  const _EmptyDevicesState({required this.onAddDevice});

  final VoidCallback onAddDevice;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.smart_toy_outlined,
                size: 44,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có thiết bị nào',
              key: const Key('devices-empty-title'),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Liên kết robot AmiMate để bắt đầu xem lịch sử hội thoại của bé.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onAddDevice,
              icon: const Icon(Icons.add_link_rounded),
              label: const Text('Thêm thiết bị đầu tiên'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceErrorState extends StatelessWidget {
  const _DeviceErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 52,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa tải được thiết bị',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              key: const Key('devices-error-message'),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              key: const Key('devices-retry'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
