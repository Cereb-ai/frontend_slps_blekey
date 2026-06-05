import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../states/global_error_store.dart';
import 'ble_key_controller.dart';
import 'widgets/ble_device_card.dart';
import 'widgets/info_tile.dart';
import 'widgets/log_list.dart';
import 'widgets/section_panel.dart';

class BleKeyScreen extends StatefulWidget {
  const BleKeyScreen({super.key});

  @override
  State<BleKeyScreen> createState() => _BleKeyScreenState();
}

class _BleKeyScreenState extends State<BleKeyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BleKeyController>().preparePermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BleKeyController>();
    final errors = context.watch<GlobalErrorStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('蓝牙钥匙 SDK 测试'),
        actions: [
          IconButton(
            tooltip: '清空日志',
            onPressed: controller.clearLogs,
            icon: const Icon(Icons.cleaning_services_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SectionPanel(
              title: '连接准备',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: controller.initialize,
                    icon: const Icon(Icons.power_settings_new),
                    label: const Text('初始化 SDK'),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.scanning
                        ? controller.stopScan
                        : () => controller.startScan(timeoutMs: 10000),
                    icon: Icon(
                      controller.scanning
                          ? Icons.bluetooth_disabled
                          : Icons.bluetooth_searching,
                    ),
                    label: Text(controller.scanning ? '停止扫描' : '扫描钥匙'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionPanel(
              title: 'SDK 状态',
              child: Column(
                children: [
                  InfoTile(
                    label: '初始化',
                    value: controller.initialized ? '已完成' : '未初始化',
                  ),
                  InfoTile(
                    label: '系统版本',
                    value: controller.platformVersion ?? '待读取',
                  ),
                  InfoTile(
                    label: 'JAR 版本',
                    value: controller.sdkVersions['jar'] ?? '待读取',
                  ),
                  InfoTile(
                    label: 'SO 版本',
                    value: controller.sdkVersions['so'] ?? '待读取',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionPanel(
              title: '扫描设备',
              trailing: Text('${controller.devices.length} 台'),
              child: controller.devices.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('暂无设备。请先初始化 SDK，再扫描附近蓝牙钥匙。'),
                    )
                  : Column(
                      children: controller.devices
                          .map((device) => BleDeviceCard(device: device))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 12),
            const SectionPanel(
              title: '任务能力',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('文档流程包含连接钥匙、设置钥匙密钥、设置锁具密钥、采集锁号、授权开关锁和读取记录。'),
                  SizedBox(height: 8),
                  Text(
                    '当前 Flutter SDK 只暴露初始化、版本、扫描和事件流；任务写入类接口需要在 plugin 中继续封装后启用。',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionPanel(
              title: '全局异常',
              trailing: Text('${errors.errors.length} 条'),
              child: Text(errors.latest?.message ?? '暂无异常'),
            ),
            const SizedBox(height: 12),
            SectionPanel(
              title: '事件日志',
              child: LogList(logs: controller.logs),
            ),
          ],
        ),
      ),
    );
  }
}
