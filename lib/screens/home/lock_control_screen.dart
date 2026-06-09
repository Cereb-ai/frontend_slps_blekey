import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../ble_key/ble_key_controller.dart';
import '../../states/global_user.dart';

class LockControlScreen extends StatefulWidget {
  const LockControlScreen({
    super.key,
    required this.lockId,
    required this.name,
    required this.number,
    required this.location,
    required this.switchState,
  });

  final String lockId;
  final String name;
  final String number;
  final String location;
  final String switchState;

  factory LockControlScreen.fromArgs(Map<String, dynamic>? args) {
    final data = args ?? const <String, dynamic>{};
    return LockControlScreen(
      lockId: (data['lockId'] ?? '').toString(),
      name: (data['name'] ?? '-').toString(),
      number: (data['number'] ?? '-').toString(),
      location: (data['location'] ?? '-').toString(),
      switchState: (data['switchState'] ?? 'locked').toString(),
    );
  }

  @override
  State<LockControlScreen> createState() => _LockControlScreenState();
}

class _LockControlScreenState extends State<LockControlScreen> {
  bool _busy = false;
  late String _switchState;
  String? _selectedMac;
  final TextEditingController _secretController = TextEditingController(
    text: 'FFFFFFFFFFFFFFFFFFFF',
  );
  final TextEditingController _signController = TextEditingController(
    text: '0',
  );
  final TextEditingController _licController = TextEditingController(
    text: 'FFFFFFFFFFFFFFFF',
  );

  @override
  void initState() {
    super.initState();
    _switchState = widget.switchState;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BleKeyController>().preparePermissions();
    });
  }

  @override
  void dispose() {
    _secretController.dispose();
    _signController.dispose();
    _licController.dispose();
    super.dispose();
  }

  Future<void> _setSwitchState(String nextState) async {
    if (_busy || nextState == _switchState) return;
    if (_selectedMac == null || _selectedMac!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先扫描并选择钥匙 MAC')));
      return;
    }

    final token = GlobalUser.instance.token;
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('登录状态已失效，请重新登录')));
      return;
    }

    setState(() => _busy = true);
    try {
      final controller = context.read<BleKeyController>();
      await controller.executeVendorOperationAndWait(
        index: 0,
        expectedOperationName: 'ConnectKey',
        mac: _selectedMac,
        args: _sdkArgs(nextState),
        timeout: const Duration(seconds: 15),
      );
      await controller.executeVendorOperationAndWait(
        index: 15,
        expectedOperationName: 'SetDateTime',
        mac: _selectedMac,
        args: _sdkArgs(nextState),
        timeout: const Duration(seconds: 15),
      );
      await controller.executeVendorOperationAndWait(
        index: 6,
        expectedOperationName: 'SetUserKey',
        mac: _selectedMac,
        args: _sdkArgs(nextState),
        timeout: const Duration(seconds: 20),
      );
      await controller.executeVendorOperationAndWait(
        index: 7,
        expectedOperationName: 'SetOnline',
        mac: _selectedMac,
        args: _sdkArgs(nextState),
        timeout: const Duration(seconds: 20),
      );
      await controller.executeVendorOperation(
        index: 20,
        mac: _selectedMac,
        args: _sdkArgs(nextState),
      );

      await Api.updateLockDevice(
        token: token,
        id: widget.lockId,
        payload: <String, dynamic>{
          'metadata': <String, dynamic>{
            'switchState': nextState,
            'source': 'app_lock_control',
            'controlMac': _selectedMac,
            'controlChannel': 'flutter_blekey_sdk',
            'controlledAt': DateTime.now().toIso8601String(),
          },
        },
      );
      if (!mounted) return;
      setState(() => _switchState = nextState);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nextState == 'unlocked' ? '开锁指令已提交' : '关锁指令已提交'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('控制失败: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Map<String, Object?> _sdkArgs(String nextState) {
    return <String, Object?>{
      'secret': _secretController.text.trim(),
      'oldSecret': _secretController.text.trim(),
      'sign': int.tryParse(_signController.text.trim()) ?? 0,
      'lic': _licController.text.trim(),
      'lockIds': widget.number,
      'switchCount': 1,
      'unlock': nextState == 'unlocked',
    };
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BleKeyController>();
    if (_selectedMac == null && controller.devices.isNotEmpty) {
      _selectedMac = controller.devices.first.mac;
    }
    final isLocked = _switchState == 'locked';

    return Scaffold(
      appBar: AppBar(title: const Text('锁控制')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('编号: ${widget.number}'),
                    const SizedBox(height: 4),
                    Text('位置: ${widget.location}'),
                    const SizedBox(height: 4),
                    Text('当前状态: ${isLocked ? '已上锁' : '已解锁'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'SDK 控制配置',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text('${controller.devices.length} 台钥匙'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: _busy
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
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedMac,
                      decoration: const InputDecoration(labelText: '钥匙 MAC'),
                      items: controller.devices
                          .where((device) => (device.mac ?? '').isNotEmpty)
                          .map(
                            (device) => DropdownMenuItem<String>(
                              value: device.mac,
                              child: Text(
                                '${device.name ?? '未命名'}  ${device.mac ?? ''}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _busy
                          ? null
                          : (value) => setState(() => _selectedMac = value),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _secretController,
                      enabled: !_busy,
                      decoration: const InputDecoration(labelText: 'secret'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _signController,
                      enabled: !_busy,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'sign'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _licController,
                      enabled: !_busy,
                      decoration: const InputDecoration(labelText: 'lic'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : () => _setSwitchState('unlocked'),
              icon: const Icon(Icons.lock_open),
              label: const Text('开锁'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _busy ? null : () => _setSwitchState('locked'),
              icon: const Icon(Icons.lock_outline),
              label: const Text('关锁'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            if (_busy) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
