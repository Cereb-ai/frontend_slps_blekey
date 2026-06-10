import 'package:flutter/material.dart';
import 'package:flutter_blekey_sdk/flutter_blekey_sdk.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../l10n/app_localizations.dart';
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
    text: '1',
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
    final l10n = AppLocalizations.of(context)!;
    if (_busy || nextState == _switchState) return;
    if (_selectedMac == null || _selectedMac!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.lockControlSelectMacFirst)));
      return;
    }

    final token = GlobalUser.instance.token;
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sessionExpired)));
      return;
    }

    setState(() => _busy = true);
    try {
      final controller = context.read<BleKeyController>();

      // 1) App 连接钥匙
      await controller.executeVendorOperationAndWait(
        index: 0,
        expectedOperationName: 'ConnectKey',
        mac: _selectedMac,
        args: _sdkArgs(nextState),
        timeout: const Duration(seconds: 15),
      );

      // 2) App/后端开锁前鉴权（任务、时间、GPS 由后端策略判定）
      final keyId = await _resolveKeyIdByMac(token, _selectedMac!);
      if (keyId == null || keyId.isEmpty) {
        throw StateError('未找到该 MAC 对应的钥匙档案，请先创建并同步钥匙');
      }
      final decision = await Api.decideAccess(
        token: token,
        keyId: keyId,
        lockId: widget.lockId,
        at: DateTime.now(),
        clientTraceId:
            'ble_unlock_${DateTime.now().millisecondsSinceEpoch}_${widget.lockId}',
      );
      final allowed = decision['allowed'] == true;
      if (!allowed) {
        final reasons = _formatDecisionReasons(decision['reasons']);
        throw StateError('后端鉴权拒绝：$reasons');
      }

      // 3) App 给钥匙 SetDateTime 校时
      await controller.executeVendorOperationAndWait(
        index: 15,
        expectedOperationName: 'SetDateTime',
        mac: _selectedMac,
        args: _sdkArgs(nextState),
        timeout: const Duration(seconds: 15),
      );

      // 4) App 给钥匙 SetUserKey 写 lockIds + timeBlocks + offline=0
      await controller.executeVendorOperationAndWait(
        index: 6,
        expectedOperationName: 'SetUserKey',
        mac: _selectedMac,
        args: _sdkArgs(nextState),
        timeout: const Duration(seconds: 20),
      );

      // 5) 设置在线模式
      await controller.executeVendorOperationAndWait(
        index: 7,
        expectedOperationName: 'SetOnline',
        mac: _selectedMac,
        args: _sdkArgs(nextState),
        timeout: const Duration(seconds: 20),
      );

      // 6) 保持蓝牙连接，用钥匙开锁；等待 CMD=10 回调确认
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已完成在线授权，请保持蓝牙连接并用钥匙操作锁体。')),
      );
      final report = await controller.waitForOperationResult(
        expectedOperationName: 'Report',
        where: _isCmd10SwitchReport,
        timeout: const Duration(seconds: 90),
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
            'controlReport': report.obj,
            'controlReportText': report.objText,
          },
        },
      );
      if (!mounted) return;
      setState(() => _switchState = nextState);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextState == 'unlocked'
                ? l10n.lockControlUnlockSubmitted
                : l10n.lockControlLockSubmitted,
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.lockControlFailed}: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Map<String, Object?> _sdkArgs(String nextState) {
    return <String, Object?>{
      'secret': _secretController.text.trim(),
      'oldSecret': _secretController.text.trim(),
      'sign': int.tryParse(_signController.text.trim()) ?? 1,
      'lic': _licController.text.trim(),
      'lockIds': widget.number,
    };
  }

  Future<String?> _resolveKeyIdByMac(String token, String mac) async {
    final keys = await Api.listLockKeys(
      token: token,
      query: <String, dynamic>{'vendorKeyId': mac, 'limit': 200},
    );
    final normalizedMac = mac.trim().toUpperCase();
    for (final key in keys) {
      final vendorKeyId = (key['vendorKeyId'] ?? '').toString().trim().toUpperCase();
      if (vendorKeyId == normalizedMac) {
        final id = (key['id'] ?? '').toString().trim();
        if (id.isNotEmpty) return id;
      }
    }

    final fallbackKeys = await Api.listLockKeys(
      token: token,
      query: const <String, dynamic>{'limit': 200},
    );
    for (final key in fallbackKeys) {
      final vendorKeyId = (key['vendorKeyId'] ?? '').toString().trim().toUpperCase();
      if (vendorKeyId == normalizedMac) {
        final id = (key['id'] ?? '').toString().trim();
        if (id.isNotEmpty) return id;
      }
    }
    return null;
  }

  String _formatDecisionReasons(dynamic reasons) {
    if (reasons is List) {
      final values = reasons.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
      if (values.isNotEmpty) return values.join(', ');
    }
    return 'unknown reason';
  }

  bool _isCmd10SwitchReport(BleKeyOperationResult result) {
    final cmd = _extractCommand(result.obj);
    if (cmd == 10) return true;
    final text = (result.objText ?? result.obj?.toString() ?? '').toLowerCase();
    return text.contains('cmd=10') ||
        text.contains('cmd:10') ||
        text.contains('command=10') ||
        text.contains('command:10');
  }

  int? _extractCommand(Object? value) {
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final direct = _toInt(map['cmd']) ?? _toInt(map['command']);
      if (direct != null) return direct;
      for (final nested in map.values) {
        final cmd = _extractCommand(nested);
        if (cmd != null) return cmd;
      }
      return null;
    }
    if (value is List) {
      for (final item in value) {
        final cmd = _extractCommand(item);
        if (cmd != null) return cmd;
      }
      return null;
    }
    if (value == null) return null;
    final text = value.toString();
    final match = RegExp(r'cmd\s*[=:]\s*(\d+)', caseSensitive: false).firstMatch(text) ??
        RegExp(r'command\s*[=:]\s*(\d+)', caseSensitive: false).firstMatch(text);
    if (match == null) return null;
    return int.tryParse(match.group(1) ?? '');
  }

  int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<BleKeyController>();
    if (_selectedMac == null && controller.devices.isNotEmpty) {
      _selectedMac = controller.devices.first.mac;
    }
    final isLocked = _switchState == 'locked';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.lockControlTitle)),
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
                    Text(
                      '${l10n.lockWizardLockNumberSummary}: ${widget.number}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.lockWizardLocationSummary}: ${widget.location}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.lockControlCurrentStatus}: ${isLocked ? l10n.lockStateLocked : l10n.lockStateUnlocked}',
                    ),
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
                            l10n.lockControlSdkConfig,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          l10n.lockControlKeyCount(controller.devices.length),
                        ),
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
                      label: Text(
                        controller.scanning
                            ? l10n.lockControlStopScan
                            : l10n.keyWizardScanKey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedMac,
                      decoration: InputDecoration(
                        labelText: l10n.lockControlKeyMac,
                      ),
                      items: controller.devices
                          .where((device) => (device.mac ?? '').isNotEmpty)
                          .map(
                            (device) => DropdownMenuItem<String>(
                              value: device.mac,
                              child: Text(
                                '${device.name ?? l10n.unnamedDevice}  ${device.mac ?? ''}',
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
              label: Text(l10n.lockControlUnlockAction),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _busy ? null : () => _setSwitchState('locked'),
              icon: const Icon(Icons.lock_outline),
              label: Text(l10n.lockControlLockAction),
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
