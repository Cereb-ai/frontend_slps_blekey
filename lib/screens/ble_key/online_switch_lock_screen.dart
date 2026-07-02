import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ble_key_controller.dart';
import 'widgets/ble_device_card.dart';
import 'widgets/section_panel.dart';

enum _FlowStepStatus { pending, running, success, failed }

class OnlineSwitchLockScreen extends StatefulWidget {
  const OnlineSwitchLockScreen({super.key});

  @override
  State<OnlineSwitchLockScreen> createState() => _OnlineSwitchLockScreenState();
}

class _OnlineSwitchLockScreenState extends State<OnlineSwitchLockScreen> {
  String? _selectedMac;
  int? _runningStep;
  BleKeyController? _bleController;
  final TextEditingController _secretController = TextEditingController(
    text: 'FFFFFFFFFFFFFFFFFFFF',
  );
  final TextEditingController _signController = TextEditingController(
    text: '1',
  );
  final TextEditingController _licController = TextEditingController(
    text: 'FFFFFFFFFFFFFFFF',
  );
  final TextEditingController _lockIdsController = TextEditingController(
    text: '202307151005,202307150990,202401270221',
  );
  final List<_FlowStepStatus> _statuses = List<_FlowStepStatus>.filled(
    _flowSteps.length,
    _FlowStepStatus.pending,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = context.read<BleKeyController>();
      _bleController = controller;
      controller.preparePermissions();
    });
  }

  @override
  void dispose() {
    final controller = _bleController;
    if (controller != null && controller.scanning) {
      unawaited(controller.stopScan());
    }
    _secretController.dispose();
    _signController.dispose();
    _licController.dispose();
    _lockIdsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BleKeyController>();
    if (_selectedMac == null && controller.devices.isNotEmpty) {
      _selectedMac = controller.devices.first.mac;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置开关锁钥匙（在线）'),
        actions: [
          IconButton(
            tooltip: '清空显示',
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
              title: '钥匙选择',
              trailing: Text('${controller.devices.length} 台'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: _runningStep != null
                        ? null
                        : controller.scanning
                        ? controller.stopScan
                        : () => controller.startScan(timeoutMs: 10000),
                    icon: Icon(
                      controller.scanning
                          ? Icons.bluetooth_disabled
                          : Icons.bluetooth_searching,
                    ),
                    label: Text(controller.scanning ? '停止扫描' : '扫描钥匙'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedMac,
                    decoration: const InputDecoration(labelText: '钥匙 MAC'),
                    items: controller.devices
                        .where((device) => device.mac != null)
                        .map(
                          (device) => DropdownMenuItem<String>(
                            value: device.mac,
                            child: Text(
                              '${device.name ?? '未命名'}  ${device.mac ?? ''}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _runningStep != null
                        ? null
                        : (value) => setState(() => _selectedMac = value),
                  ),
                  const SizedBox(height: 12),
                  if (controller.devices.isEmpty)
                    const Text('请先扫描并选择要授权的蓝牙钥匙。')
                  else
                    ...controller.devices.map(
                      (device) => BleDeviceCard(device: device),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionPanel(
              title: '授权参数',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _secretController,
                    enabled: _runningStep == null,
                    decoration: const InputDecoration(labelText: '钥匙当前密钥'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _signController,
                    enabled: _runningStep == null,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'sign'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _licController,
                    enabled: _runningStep == null,
                    decoration: const InputDecoration(labelText: 'lic'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _lockIdsController,
                    enabled: _runningStep == null,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: '授权锁号',
                      helperText: '多个锁号用逗号分隔',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionPanel(
              title: '流程',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < _flowSteps.length; i++)
                    _FlowStepTile(
                      index: i + 1,
                      title: _flowSteps[i].title,
                      subtitle: _flowSteps[i].subtitle,
                      status: _statuses[i],
                      buttonText: _flowSteps[i].buttonText,
                      enabled: _runningStep == null,
                      onPressed: _buttonActionForStep(i, controller),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionPanel(
              title: '回调返回数据',
              trailing: Text('${controller.operationResults.length} 条'),
              child: controller.operationResults.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        '钥匙开关锁后，请查看 onReport 回调；CMD 参数为 10 的记录是开关锁数据。',
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: controller.operationResults
                          .map(
                            (line) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: SelectableText(line),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  VoidCallback? _buttonActionForStep(
    int stepIndex,
    BleKeyController controller,
  ) {
    if (_runningStep != null) return null;
    return switch (stepIndex) {
      0 => () => _runStep(stepIndex, controller.initialize),
      1 => () => _runOperationStep(stepIndex, controller, operationIndex: 0),
      2 => () => _runOperationStep(stepIndex, controller, operationIndex: 15),
      3 => () => _runOperationStep(stepIndex, controller, operationIndex: 6),
      4 => () => _runOperationStep(stepIndex, controller, operationIndex: 7),
      5 => () => _markWaitingForReport(stepIndex),
      _ => null,
    };
  }

  Future<void> _runOperationStep(
    int stepIndex,
    BleKeyController controller, {
    required int operationIndex,
  }) async {
    if (_selectedMac == null || _selectedMac!.isEmpty) {
      _showSnack('请先扫描并选择钥匙 MAC');
      return;
    }
    await _runStep(
      stepIndex,
      () => controller.executeVendorOperation(
        index: operationIndex,
        mac: _selectedMac,
        args: _commonArgs,
      ),
    );
  }

  void _markWaitingForReport(int stepIndex) {
    setState(() => _statuses[stepIndex] = _FlowStepStatus.running);
    _showSnack('请保持蓝牙连接并用钥匙开关授权锁，然后查看 onReport 回调。');
  }

  Future<void> _runStep(int index, Future<void> Function() task) async {
    setState(() {
      _runningStep = index;
      _statuses[index] = _FlowStepStatus.running;
    });
    try {
      await task();
      if (!mounted) return;
      setState(() => _statuses[index] = _FlowStepStatus.success);
    } catch (_) {
      if (!mounted) return;
      setState(() => _statuses[index] = _FlowStepStatus.failed);
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _runningStep = null);
      }
    }
  }

  Map<String, Object?> get _commonArgs => <String, Object?>{
    'secret': _secretController.text.trim(),
    'oldSecret': _secretController.text.trim(),
    'sign': int.tryParse(_signController.text.trim()) ?? 1,
    'lic': _licController.text.trim(),
    'lockIds': _lockIdsController.text.trim(),
  };

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FlowStep {
  const _FlowStep(this.title, this.subtitle, this.buttonText);

  final String title;
  final String subtitle;
  final String buttonText;
}

const List<_FlowStep> _flowSteps = <_FlowStep>[
  _FlowStep('初始化 SDK', 'InitSDK', 'InitSDK'),
  _FlowStep('连接钥匙', 'connectToKey', 'connectToKey'),
  _FlowStep('钥匙校时', 'setDateTime', 'setDateTime'),
  _FlowStep('设置开关锁钥匙', 'setUserKey', 'setUserKey'),
  _FlowStep('设置在线授权', 'setOnline', 'setOnline'),
  _FlowStep('钥匙开关授权的锁', '等待 onReport，CMD=10 为开关锁数据', '等待 onReport'),
];

class _FlowStepTile extends StatelessWidget {
  const _FlowStepTile({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.buttonText,
    required this.enabled,
    required this.onPressed,
  });

  final int index;
  final String title;
  final String subtitle;
  final _FlowStepStatus status;
  final String buttonText;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = switch (status) {
      _FlowStepStatus.pending => Icons.radio_button_unchecked,
      _FlowStepStatus.running => Icons.sync,
      _FlowStepStatus.success => Icons.check_circle,
      _FlowStepStatus.failed => Icons.error,
    };
    final color = switch (status) {
      _FlowStepStatus.pending => colorScheme.onSurfaceVariant,
      _FlowStepStatus.running => colorScheme.primary,
      _FlowStepStatus.success => Colors.green,
      _FlowStepStatus.failed => colorScheme.error,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$index. $title',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(subtitle),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 132,
            child: OutlinedButton(
              onPressed: enabled ? onPressed : null,
              child: Text(
                status == _FlowStepStatus.running ? '执行中' : buttonText,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
