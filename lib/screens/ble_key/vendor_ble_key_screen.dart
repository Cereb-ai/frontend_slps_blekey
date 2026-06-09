import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ble_key_controller.dart';
import 'widgets/ble_device_card.dart';
import 'widgets/section_panel.dart';

class VendorBleKeyScreen extends StatefulWidget {
  const VendorBleKeyScreen({super.key});

  @override
  State<VendorBleKeyScreen> createState() => _VendorBleKeyScreenState();
}

class _VendorBleKeyScreenState extends State<VendorBleKeyScreen> {
  int _selectedOperation = 0;
  String? _selectedMac;
  bool _unlock = false;
  final TextEditingController _secretController = TextEditingController(
    text: 'FFFFFFFFFFFFFFFFFFFF',
  );
  final TextEditingController _newSecretController = TextEditingController(
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
  final TextEditingController _switchCountController = TextEditingController(
    text: '1',
  );
  final TextEditingController _fingerIndexController = TextEditingController(
    text: '1',
  );
  final TextEditingController _taskIdsController = TextEditingController(
    text: '1,2,3',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BleKeyController>().preparePermissions();
    });
  }

  @override
  void dispose() {
    _secretController.dispose();
    _newSecretController.dispose();
    _signController.dispose();
    _licController.dispose();
    _lockIdsController.dispose();
    _switchCountController.dispose();
    _fingerIndexController.dispose();
    _taskIdsController.dispose();
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
        title: const Text('厂家 SDK 测试'),
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
              title: '扫描钥匙',
              trailing: Text('${controller.devices.length} 台'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedMac,
                    decoration: const InputDecoration(labelText: '选择钥匙 MAC'),
                    items: controller.devices
                        .map(
                          (device) => DropdownMenuItem<String>(
                            value: device.mac,
                            child: Text(
                              '${device.name ?? '未命名'}  ${device.mac ?? ''}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _selectedMac = value),
                  ),
                  const SizedBox(height: 12),
                  if (controller.devices.isNotEmpty)
                    ...controller.devices.map(
                      (device) => BleDeviceCard(device: device),
                    )
                  else
                    const Text('暂无设备。厂家 demo 是先扫描列表，再进入操作页。'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionPanel(
              title: '命令',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _selectedOperation,
                    decoration: const InputDecoration(labelText: '操作命令'),
                    items: [
                      for (var i = 0; i < vendorOperationNames.length; i++)
                        DropdownMenuItem<int>(
                          value: i,
                          child: Text('${i + 1}. ${vendorOperationNames[i]}'),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedOperation = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  _CommandFields(
                    operation: _selectedOperation,
                    secretController: _secretController,
                    newSecretController: _newSecretController,
                    signController: _signController,
                    licController: _licController,
                    lockIdsController: _lockIdsController,
                    switchCountController: _switchCountController,
                    fingerIndexController: _fingerIndexController,
                    taskIdsController: _taskIdsController,
                    unlock: _unlock,
                    onUnlockChanged: (value) {
                      setState(() => _unlock = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _execute(controller),
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('执行'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionPanel(
              title: '返回数据',
              trailing: Text('${controller.operationResults.length} 条'),
              child: controller.operationResults.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('暂无返回。执行命令后会显示 BleKeyCallback 回调结果。'),
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

  Future<void> _execute(BleKeyController controller) {
    return controller.executeVendorOperation(
      index: _selectedOperation,
      mac: _selectedMac,
      args: <String, Object?>{
        'secret': _secretController.text,
        'oldSecret': _secretController.text,
        'newSecret': _newSecretController.text,
        'sign': int.tryParse(_signController.text) ?? 1,
        'lic': _licController.text,
        'lockIds': _lockIdsController.text,
        'switchCount': int.tryParse(_switchCountController.text) ?? 1,
        'fingerIndex': int.tryParse(_fingerIndexController.text) ?? 1,
        'taskIds': _taskIdsController.text,
        'unlock': _unlock,
      },
    );
  }
}

class _CommandFields extends StatelessWidget {
  const _CommandFields({
    required this.operation,
    required this.secretController,
    required this.newSecretController,
    required this.signController,
    required this.licController,
    required this.lockIdsController,
    required this.switchCountController,
    required this.fingerIndexController,
    required this.taskIdsController,
    required this.unlock,
    required this.onUnlockChanged,
  });

  final int operation;
  final TextEditingController secretController;
  final TextEditingController newSecretController;
  final TextEditingController signController;
  final TextEditingController licController;
  final TextEditingController lockIdsController;
  final TextEditingController switchCountController;
  final TextEditingController fingerIndexController;
  final TextEditingController taskIdsController;
  final bool unlock;
  final ValueChanged<bool> onUnlockChanged;

  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[];
    if (operation == 0 || operation == 3 || operation == 9) {
      fields.add(
        TextField(
          controller: secretController,
          decoration: const InputDecoration(labelText: '当前密钥'),
        ),
      );
    }
    if (operation == 0) {
      fields.add(
        TextField(
          controller: signController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '钥匙标识 sign'),
        ),
      );
      fields.add(
        TextField(
          controller: licController,
          decoration: const InputDecoration(labelText: '许可号 lic'),
        ),
      );
    }
    if (operation == 3 || operation == 9) {
      fields.add(
        TextField(
          controller: newSecretController,
          decoration: const InputDecoration(labelText: '新密钥'),
        ),
      );
    }
    if (operation == 6 || operation == 19 || operation == 21) {
      fields.add(
        TextField(
          controller: lockIdsController,
          decoration: const InputDecoration(labelText: '锁号，逗号分隔'),
        ),
      );
    }
    if (operation == 17 || operation == 18 || operation == 23) {
      fields.add(
        TextField(
          controller: fingerIndexController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '指纹序号'),
        ),
      );
    }
    if (operation == 20) {
      fields.add(
        TextField(
          controller: switchCountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '开关次数'),
        ),
      );
      fields.add(
        SwitchListTile(
          value: unlock,
          onChanged: onUnlockChanged,
          title: const Text('开锁次数'),
          contentPadding: EdgeInsets.zero,
        ),
      );
    }
    if (operation == 25) {
      fields.add(
        TextField(
          controller: taskIdsController,
          decoration: const InputDecoration(labelText: '任务 ID，逗号分隔'),
        ),
      );
    }

    if (fields.isEmpty) {
      return const Text('该命令使用厂家 demo 默认参数。');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final field in fields) ...[field, const SizedBox(height: 8)],
      ],
    );
  }
}
