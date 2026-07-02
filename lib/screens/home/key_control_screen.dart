import 'package:flutter/material.dart';
import 'package:flutter_blekey_sdk/flutter_blekey_sdk.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../l10n/app_localizations.dart';
import '../ble_key/ble_key_controller.dart';
import '../../states/global_user.dart';
import 'models.dart';

/// Key-centric online unlock control.
///
/// Drives the same SDK flow as the legacy lock-centric screen, but the entry
/// point is a [KeyItem]. The user picks the [LockItem] to operate on inside
/// this screen, then runs the BLE/SDK flow for that pair.
class KeyControlScreen extends StatefulWidget {
  const KeyControlScreen({
    super.key,
    required this.keyId,
    required this.name,
    required this.number,
    required this.keyType,
  });

  /// Platform key id (matches `/slps/keys` record id).
  final String keyId;

  /// User-facing key name.
  final String name;

  /// Vendor key id, also used as the BLE MAC.
  final String number;

  /// Key capability (`bluetooth`, `fingerprint`, etc.).
  final String keyType;

  factory KeyControlScreen.fromArgs(Map<String, dynamic>? args) {
    final data = args ?? const <String, dynamic>{};
    return KeyControlScreen(
      keyId: (data['keyId'] ?? '').toString(),
      name: (data['name'] ?? '-').toString(),
      number: (data['number'] ?? '').toString(),
      keyType: (data['keyType'] ?? 'standard').toString(),
    );
  }

  @override
  State<KeyControlScreen> createState() => _KeyControlScreenState();
}

class _KeyControlScreenState extends State<KeyControlScreen> {
  bool _busy = false;
  bool _locksLoading = false;
  String? _selectedMac;
  LockItem? _selectedLock;
  List<LockItem> _availableLocks = <LockItem>[];

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
    _selectedMac = widget.number.isNotEmpty ? widget.number : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BleKeyController>().preparePermissions();
      _loadLocks();
    });
  }

  @override
  void dispose() {
    _secretController.dispose();
    _signController.dispose();
    _licController.dispose();
    super.dispose();
  }

  Future<void> _loadLocks() async {
    final token = GlobalUser.instance.token;
    if (token == null || token.isEmpty) return;
    setState(() => _locksLoading = true);
    try {
      final response = await Api.listLockDevices(token: token);
      final mapped = response.map(_mapApiLock).toList();
      if (!mounted) return;
      setState(() {
        _availableLocks = mapped;
        _locksLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _locksLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('锁列表加载失败: $error')));
    }
  }

  LockItem _mapApiLock(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString();
    final metadataRaw = json['metadata'];
    final metadata = metadataRaw is Map
        ? Map<String, dynamic>.from(metadataRaw)
        : const <String, dynamic>{};

    final name = (json['name'] ?? json['vendorLockId'] ?? id).toString();
    final number = (json['vendorLockId'] ?? id).toString();
    final location =
        (metadata['location'] ??
                metadata['address'] ??
                metadata['siteName'] ??
                '-')
            .toString();
    final switchStateRaw =
        (json['lastState'] ?? metadata['switchState'] ?? 'locked').toString();
    final switchState = switchStateRaw.toLowerCase() == 'unlocked'
        ? 'unlocked'
        : 'locked';
    final updatedAtRaw =
        (json['updatedAt'] ??
                (json['latestEvent'] is Map
                    ? (json['latestEvent'] as Map)['eventTime']
                    : null))
            ?.toString();
    final updatedAt = DateTime.tryParse(updatedAtRaw ?? '') ?? DateTime.now();
    final status = (json['status'] ?? metadata['status'] ?? 'uninstalled')
        .toString();

    return LockItem(
      id: id.isEmpty ? DateTime.now().microsecondsSinceEpoch.toString() : id,
      name: name,
      number: number,
      location: location,
      switchState: switchState,
      status: status,
      updatedAt: updatedAt,
    );
  }

  Future<void> _setSwitchState(String nextState) async {
    final l10n = AppLocalizations.of(context)!;
    if (_busy) return;

    if (_selectedLock == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.keyUnlockNoLockSelected)));
      return;
    }
    if (_selectedMac == null || _selectedMac!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.keyUnlockSelectMacFirst)));
      return;
    }

    final token = GlobalUser.instance.token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sessionExpired)));
      return;
    }

    final lock = _selectedLock!;
    if (nextState == lock.switchState) return;

    setState(() => _busy = true);
    try {
      final controller = context.read<BleKeyController>();

      // 1) App connects to the physical key.
      await controller.executeVendorOperationAndWait(
        index: 0,
        expectedOperationName: 'ConnectKey',
        mac: _selectedMac,
        args: _sdkArgs(),
        timeout: const Duration(seconds: 15),
      );

      // 2) Backend authorization for this (key, lock) pair.
      final decision = await Api.decideAccess(
        token: token,
        keyId: widget.keyId,
        lockId: lock.id,
        at: DateTime.now(),
        clientTraceId:
            'ble_unlock_${DateTime.now().millisecondsSinceEpoch}_${lock.id}',
      );
      final allowed = decision['allowed'] == true;
      if (!allowed) {
        final reasons = _formatDecisionReasons(decision['reasons']);
        throw StateError('后端鉴权拒绝：$reasons');
      }

      // 3) SetDateTime
      await controller.executeVendorOperationAndWait(
        index: 15,
        expectedOperationName: 'SetDateTime',
        mac: _selectedMac,
        args: _sdkArgs(),
        timeout: const Duration(seconds: 15),
      );
      // 4) SetUserKey with target lockId
      await controller.executeVendorOperationAndWait(
        index: 6,
        expectedOperationName: 'SetUserKey',
        mac: _selectedMac,
        args: _sdkArgs(),
        timeout: const Duration(seconds: 20),
      );
      // 5) SetOnline
      await controller.executeVendorOperationAndWait(
        index: 7,
        expectedOperationName: 'SetOnline',
        mac: _selectedMac,
        args: _sdkArgs(),
        timeout: const Duration(seconds: 20),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已完成在线授权，请保持蓝牙连接并用钥匙操作锁体。')));
      // 6) Wait for CMD=10 report confirming the switch happened.
      final report = await controller.waitForOperationResult(
        expectedOperationName: 'Report',
        where: _isCmd10SwitchReport,
        timeout: const Duration(seconds: 90),
      );

      await Api.updateLockDevice(
        token: token,
        id: lock.id,
        payload: <String, dynamic>{
          'metadata': <String, dynamic>{
            'switchState': nextState,
            'source': 'app_key_control',
            'controlMac': _selectedMac,
            'controlChannel': 'flutter_blekey_sdk',
            'controlledAt': DateTime.now().toIso8601String(),
            'controlReport': report.obj,
            'controlReportText': report.objText,
            'controlledByKeyId': widget.keyId,
          },
        },
      );
      if (!mounted) return;
      setState(() {
        _selectedLock = LockItem(
          id: lock.id,
          name: lock.name,
          number: lock.number,
          location: lock.location,
          switchState: nextState,
          status: lock.status,
          updatedAt: DateTime.now(),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextState == 'unlocked'
                ? l10n.keyUnlockUnlockSubmitted
                : l10n.keyUnlockLockSubmitted,
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.keyUnlockFailed}: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Map<String, Object?> _sdkArgs() {
    return <String, Object?>{
      'secret': _secretController.text.trim(),
      'oldSecret': _secretController.text.trim(),
      'sign': int.tryParse(_signController.text.trim()) ?? 1,
      'lic': _licController.text.trim(),
      'lockIds': _selectedLock?.number ?? '',
    };
  }

  String _formatDecisionReasons(dynamic reasons) {
    if (reasons is List) {
      final values = reasons
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList();
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
    final match =
        RegExp(r'cmd\s*[=:]\s*(\d+)', caseSensitive: false).firstMatch(text) ??
        RegExp(
          r'command\s*[=:]\s*(\d+)',
          caseSensitive: false,
        ).firstMatch(text);
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

    // If scanning found a device matching our default MAC, keep it visible.
    if (_selectedMac == null && controller.devices.isNotEmpty) {
      _selectedMac = controller.devices.first.mac;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.keyUnlockTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _KeyInfoCard(
            keyName: widget.name,
            keyId: widget.keyId,
            vendorKeyId: widget.number,
            keyType: widget.keyType,
          ),
          const SizedBox(height: 12),
          _TargetLockCard(
            locks: _availableLocks,
            loading: _locksLoading,
            selected: _selectedLock,
            onSelect: _busy
                ? null
                : (lock) => setState(() => _selectedLock = lock),
            onRetry: _busy ? null : _loadLocks,
            pickLockLabel: l10n.keyUnlockPickLock,
            selectedLockLabel: l10n.keyUnlockSelectedLock,
            hintLabel: l10n.keyUnlockPickLockHint,
            emptyLabel: l10n.keyUnlockNoLockAvailable,
            loadingLabel: l10n.keyUnlockLoadingLocks,
            sectionLabel: l10n.keyUnlockTargetLockSection,
          ),
          const SizedBox(height: 12),
          _SdkConfigCard(
            controller: controller,
            selectedMac: _selectedMac,
            busy: _busy,
            secretController: _secretController,
            signController: _signController,
            licController: _licController,
            onMacChanged: (value) => setState(() => _selectedMac = value),
            keyCountLabel: l10n.keyUnlockKeyCount(controller.devices.length),
            stopScanLabel: l10n.keyUnlockStopScan,
            scanLabel: l10n.keyWizardScanKey,
            sdkConfigLabel: l10n.keyUnlockSdkConfig,
            keyMacLabel: l10n.keyUnlockKeyMac,
            unnamedDeviceLabel: l10n.unnamedDevice,
            boundKeyMacLabel: l10n.keyUnlockKeyMacReadonly,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : () => _setSwitchState('unlocked'),
            icon: const Icon(Icons.lock_open),
            label: Text(l10n.keyUnlockUnlockAction),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _busy ? null : () => _setSwitchState('locked'),
            icon: const Icon(Icons.lock_outline),
            label: Text(l10n.keyUnlockLockAction),
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
    );
  }
}

class _KeyInfoCard extends StatelessWidget {
  const _KeyInfoCard({
    required this.keyName,
    required this.keyId,
    required this.vendorKeyId,
    required this.keyType,
  });

  final String keyName;
  final String keyId;
  final String vendorKeyId;
  final String keyType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(keyName, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('${l10n.keyWizardKeyNumberSummary}: $vendorKeyId'),
            const SizedBox(height: 4),
            Text('${l10n.keyWizardTypeSummary}: $keyType'),
            if (keyId.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('ID: $keyId'),
            ],
          ],
        ),
      ),
    );
  }
}

class _TargetLockCard extends StatelessWidget {
  const _TargetLockCard({
    required this.locks,
    required this.loading,
    required this.selected,
    required this.onSelect,
    required this.onRetry,
    required this.pickLockLabel,
    required this.selectedLockLabel,
    required this.hintLabel,
    required this.emptyLabel,
    required this.loadingLabel,
    required this.sectionLabel,
  });

  final List<LockItem> locks;
  final bool loading;
  final LockItem? selected;
  final ValueChanged<LockItem>? onSelect;
  final VoidCallback? onRetry;
  final String pickLockLabel;
  final String selectedLockLabel;
  final String hintLabel;
  final String emptyLabel;
  final String loadingLabel;
  final String sectionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(sectionLabel, style: theme.textTheme.titleMedium),
                ),
                if (onRetry != null)
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(pickLockLabel),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (selected != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$selectedLockLabel: ${selected!.name} · ${selected!.number}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(hintLabel, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            if (loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(loadingLabel),
                  ],
                ),
              )
            else if (locks.isEmpty)
              Text(emptyLabel)
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: locks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final lock = locks[index];
                    final isSelected =
                        selected != null && selected!.id == lock.id;
                    return Material(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.6,
                            )
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: onSelect == null ? null : () => onSelect!(lock),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lock.name,
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text('Number: ${lock.number}'),
                              if (lock.location.isNotEmpty &&
                                  lock.location != '-')
                                Text('Location: ${lock.location}'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SdkConfigCard extends StatelessWidget {
  const _SdkConfigCard({
    required this.controller,
    required this.selectedMac,
    required this.busy,
    required this.secretController,
    required this.signController,
    required this.licController,
    required this.onMacChanged,
    required this.keyCountLabel,
    required this.stopScanLabel,
    required this.scanLabel,
    required this.sdkConfigLabel,
    required this.keyMacLabel,
    required this.unnamedDeviceLabel,
    required this.boundKeyMacLabel,
  });

  final BleKeyController controller;
  final String? selectedMac;
  final bool busy;
  final TextEditingController secretController;
  final TextEditingController signController;
  final TextEditingController licController;
  final ValueChanged<String?> onMacChanged;
  final String keyCountLabel;
  final String stopScanLabel;
  final String scanLabel;
  final String sdkConfigLabel;
  final String keyMacLabel;
  final String unnamedDeviceLabel;
  final String boundKeyMacLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    sdkConfigLabel,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(keyCountLabel),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: busy
                  ? null
                  : controller.scanning
                  ? controller.stopScan
                  : () => controller.startScan(timeoutMs: 10000),
              icon: Icon(
                controller.scanning
                    ? Icons.bluetooth_disabled
                    : Icons.bluetooth_searching,
              ),
              label: Text(controller.scanning ? stopScanLabel : scanLabel),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedMac,
              decoration: InputDecoration(labelText: keyMacLabel),
              items: controller.devices
                  .where((device) => (device.mac ?? '').isNotEmpty)
                  .map(
                    (device) => DropdownMenuItem<String>(
                      value: device.mac,
                      child: Text(
                        '${device.name ?? unnamedDeviceLabel}  ${device.mac ?? ''}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: busy ? null : onMacChanged,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$boundKeyMacLabel: ${selectedMac ?? '-'}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: secretController,
              enabled: !busy,
              decoration: const InputDecoration(labelText: 'secret'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: signController,
              enabled: !busy,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'sign'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: licController,
              enabled: !busy,
              decoration: const InputDecoration(labelText: 'lic'),
            ),
          ],
        ),
      ),
    );
  }
}
