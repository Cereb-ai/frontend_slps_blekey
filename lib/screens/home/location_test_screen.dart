import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../states/location_provider.dart';

class LocationTestScreen extends StatelessWidget {
  const LocationTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocationProvider>();
    final location = provider.location;

    return Scaffold(
      appBar: AppBar(title: const Text('定位测试')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '定位状态',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _ValueRow(label: '状态', value: _stateLabel(provider.state)),
                    _ValueRow(
                      label: '纬度 lat',
                      value: location?.lat.toStringAsFixed(7) ?? '—',
                    ),
                    _ValueRow(
                      label: '经度 lng',
                      value: location?.lng.toStringAsFixed(7) ?? '—',
                    ),
                    _ValueRow(
                      label: '精度',
                      value: location == null
                          ? '—'
                          : '${location.accuracy.toStringAsFixed(1)} 米',
                    ),
                    if (provider.error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '错误：${provider.error}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: provider.loading
                  ? null
                  : () => context.read<LocationProvider>().getEventLocation(),
              icon: provider.loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(provider.loading ? '正在获取定位…' : '获取当前位置'),
            ),
            if (provider.needsLocationSettings) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: provider.openLocationSettings,
                icon: const Icon(Icons.location_off_outlined),
                label: const Text('打开手机定位设置'),
              ),
            ],
            if (provider.needsAppSettings) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: provider.openAppSettings,
                icon: const Icon(Icons.settings_outlined),
                label: const Text('打开应用权限设置'),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              '点击按钮后，App 会检查定位服务、请求使用期间定位权限，并读取一次高精度当前位置。',
            ),
          ],
        ),
      ),
    );
  }

  String _stateLabel(AppLocationState state) => switch (state) {
    AppLocationState.idle => '尚未测试',
    AppLocationState.checking => '正在检查权限并获取位置',
    AppLocationState.ready => '定位成功',
    AppLocationState.serviceDisabled => '手机定位服务未开启',
    AppLocationState.denied => '定位权限被拒绝',
    AppLocationState.permanentlyDenied => '定位权限被永久拒绝',
    AppLocationState.failed => '定位失败',
  };
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 92, child: Text(label)),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
