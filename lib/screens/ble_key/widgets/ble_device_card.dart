import 'package:flutter/material.dart';
import 'package:flutter_blekey_sdk/flutter_blekey_sdk.dart';

class BleDeviceCard extends StatelessWidget {
  const BleDeviceCard({required this.device, super.key});

  final BleKeyDevice device;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.vpn_key_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name?.isNotEmpty == true ? device.name! : '未命名钥匙',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(device.mac ?? '无 MAC 地址'),
                if (device.keyId?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  SelectableText('keyId: ${device.keyId}'),
                ],
                if (device.scanRecord?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  SelectableText('scan: ${device.scanRecord}'),
                ],
              ],
            ),
          ),
          Text(device.rssi == null ? '--' : '${device.rssi} dBm'),
        ],
      ),
    );
  }
}
