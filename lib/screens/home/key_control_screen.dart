import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blekey_sdk/flutter_blekey_sdk.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../l10n/app_localizations.dart';
import '../../routes.dart';
import '../ble_key/ble_key_controller.dart';
import '../../states/global_user.dart';
import '../clearance/clearance_models.dart';
import '../../utils/access_decision_time.dart';
import 'models.dart';

enum _KeyConnectionPhase { idle, scanning, connecting, connected, failed }

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
    this.bleMac = '',
    required this.keyType,
  });

  /// Platform key id (matches `/slps/keys` record id).
  final String keyId;

  /// User-facing key name.
  final String name;

  /// Vendor/hardware key id from readKeyInfo (e.g. 202606050001).
  final String number;

  /// BLE MAC captured during key provisioning (e.g. 54:6C:50:8F:75:52).
  final String bleMac;

  /// Key capability (`bluetooth`, `fingerprint`, etc.).
  final String keyType;

  factory KeyControlScreen.fromArgs(Map<String, dynamic>? args) {
    final data = args ?? const <String, dynamic>{};
    return KeyControlScreen(
      keyId: (data['keyId'] ?? '').toString(),
      name: (data['name'] ?? '-').toString(),
      number: (data['number'] ?? '').toString(),
      bleMac: (data['bleMac'] ?? '').toString(),
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
  _KeyConnectionPhase _connectionPhase = _KeyConnectionPhase.idle;
  bool _autoConnectInFlight = false;
  bool _wasScanning = false;
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

  @override
  void initState() {
    super.initState();
    _selectedMac = _preferredBleMac();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = context.read<BleKeyController>();
      _bleController = controller;
      controller.addListener(_onBleControllerChanged);
      _loadLocks();
      _beginAutoConnect();
    });
  }

  @override
  void dispose() {
    final controller = _bleController;
    controller?.removeListener(_onBleControllerChanged);
    if (controller != null) {
      unawaited(_releaseBleResources(controller));
    }
    _secretController.dispose();
    _signController.dispose();
    _licController.dispose();
    super.dispose();
  }

  Future<void> _releaseBleResources(BleKeyController controller) async {
    final shouldDisconnect =
        _selectedMac != null &&
        (_connectionPhase == _KeyConnectionPhase.connected ||
            _connectionPhase == _KeyConnectionPhase.connecting);
    final args = _baseSdkArgs();
    if (controller.scanning) {
      await controller.stopScan();
    }
    if (!shouldDisconnect) return;
    await controller.executeVendorOperation(index: 1, args: args);
  }

  void _onBleControllerChanged() {
    final controller = _bleController;
    if (controller == null || !mounted) return;

    if (controller.scanning) {
      _wasScanning = true;
      if (_connectionPhase != _KeyConnectionPhase.connecting &&
          _connectionPhase != _KeyConnectionPhase.connected) {
        setState(() => _connectionPhase = _KeyConnectionPhase.scanning);
      }
      _tryConnectWhenTargetFound(controller);
      return;
    }

    if (_wasScanning &&
        _connectionPhase != _KeyConnectionPhase.connected &&
        !_autoConnectInFlight) {
      _wasScanning = false;
      final matchedMac = _findDeviceMac(controller);
      if (matchedMac != null) {
        _selectedMac = matchedMac;
        unawaited(_connectToKey(controller));
      } else if (_connectionPhase != _KeyConnectionPhase.connecting) {
        setState(() => _connectionPhase = _KeyConnectionPhase.failed);
      }
    }
  }

  Future<void> _beginAutoConnect() async {
    final controller = context.read<BleKeyController>();
    setState(() => _connectionPhase = _KeyConnectionPhase.scanning);
    try {
      await controller.preparePermissions();
      await controller.ensureReady();
      if (!mounted) return;

      final existingMac = _findDeviceMac(controller);
      if (existingMac != null) {
        _selectedMac = existingMac;
        await _connectToKey(controller);
        return;
      }

      _wasScanning = true;
      await controller.startScan(timeoutMs: 15000);
    } catch (_) {
      if (mounted) {
        setState(() => _connectionPhase = _KeyConnectionPhase.failed);
      }
    }
  }

  Future<void> _retryAutoConnect() async {
    if (_autoConnectInFlight || _busy) return;
    final controller = context.read<BleKeyController>();
    if (controller.scanning) {
      await controller.stopScan();
    }
    setState(() => _connectionPhase = _KeyConnectionPhase.scanning);
    await _beginAutoConnect();
  }

  void _tryConnectWhenTargetFound(BleKeyController controller) {
    if (_autoConnectInFlight ||
        _connectionPhase == _KeyConnectionPhase.connected ||
        _connectionPhase == _KeyConnectionPhase.connecting) {
      return;
    }

    final matchedMac = _findDeviceMac(controller);
    if (matchedMac == null) return;

    _selectedMac = matchedMac;
    unawaited(_connectToKey(controller));
  }

  Future<void> _connectToKey(BleKeyController controller) async {
    if (_autoConnectInFlight ||
        _connectionPhase == _KeyConnectionPhase.connected) {
      return;
    }
    final mac = _selectedMac;
    if (mac == null || mac.isEmpty) return;

    _autoConnectInFlight = true;
    if (mounted) {
      setState(() => _connectionPhase = _KeyConnectionPhase.connecting);
    }
    try {
      if (controller.scanning) {
        await controller.stopScan();
      }
      await controller.executeVendorOperationAndWait(
        index: 0,
        expectedOperationName: 'ConnectKey',
        mac: mac,
        args: _baseSdkArgs(),
        timeout: const Duration(seconds: 15),
      );
      if (mounted) {
        setState(() => _connectionPhase = _KeyConnectionPhase.connected);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _connectionPhase = _KeyConnectionPhase.failed);
      }
    } finally {
      _autoConnectInFlight = false;
    }
  }

  String? _preferredBleMac() {
    final bleMac = widget.bleMac.trim();
    if (bleMac.isNotEmpty) return bleMac;
    final number = widget.number.trim();
    if (_looksLikeBleMac(number)) return number;
    return null;
  }

  bool _looksLikeBleMac(String value) {
    final normalized = value.replaceAll(':', '').replaceAll('-', '').trim();
    return RegExp(r'^[0-9a-fA-F]{12}$').hasMatch(normalized);
  }

  String? _normalizeMac(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return trimmed.replaceAll(':', '').replaceAll('-', '').toLowerCase();
  }

  bool _macMatches(String? a, String? b) {
    final left = _normalizeMac(a);
    final right = _normalizeMac(b);
    return left != null && right != null && left == right;
  }

  String? _findDeviceMac(BleKeyController controller) {
    final preferredMac = _preferredBleMac();
    if (preferredMac != null) {
      for (final device in controller.devices) {
        final mac = device.mac;
        if (mac != null && mac.isNotEmpty && _macMatches(mac, preferredMac)) {
          return mac;
        }
      }
    }

    final vendorKeyId = widget.number.trim();
    if (vendorKeyId.isNotEmpty) {
      for (final device in controller.devices) {
        final deviceKey = device.key?.trim() ?? '';
        if (deviceKey.isNotEmpty && deviceKey == vendorKeyId) {
          final mac = device.mac;
          if (mac != null && mac.isNotEmpty) return mac;
        }
      }
    }

    if (controller.devices.length == 1) {
      final mac = controller.devices.first.mac;
      if (mac != null && mac.isNotEmpty) return mac;
    }

    return null;
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
    if (_connectionPhase != _KeyConnectionPhase.connected ||
        _selectedMac == null ||
        _selectedMac!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.keyUnlockKeyNotConnected)));
      if (_connectionPhase == _KeyConnectionPhase.failed) {
        await _retryAutoConnect();
      }
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

      // 1) Ensure BLE connection (auto-connected on entry; reconnect if needed).
      if (_connectionPhase != _KeyConnectionPhase.connected) {
        await controller.executeVendorOperationAndWait(
          index: 0,
          expectedOperationName: 'ConnectKey',
          mac: _selectedMac,
          args: _sdkArgs(),
          timeout: const Duration(seconds: 15),
        );
      }

      // 2) Backend authorization for this (key, lock) pair.
      final provisioningConfig = await _getProvisioningConfigSafely(
        token: token,
      );
      final decisionAt = AccessDecisionTime.resolveDecisionAt(
        provisioningConfig,
      );
      final decision = await Api.decideAccess(
        token: token,
        keyId: widget.keyId,
        lockId: lock.id,
        at: DateTime.parse(decisionAt),
        geofenceSatisfied: true,
        clientTraceId:
            'ble_unlock_${DateTime.now().millisecondsSinceEpoch}_${lock.id}',
      );
      final allowed = decision['allowed'] == true;
      if (!allowed) {
        final reasons = _formatDecisionReasons(decision['reasons']);
        final blockedByGroupLockout = _reasonsIndicateGroupLockout(
          decision['reasons'],
        );
        if (blockedByGroupLockout && mounted) {
          await _showGroupLockoutBlockedDialog(
            reasons: reasons,
            taskId: decision['taskId']?.toString(),
          );
        }
        throw StateError('${l10n.keyUnlockAuthDenied}: $reasons');
      }

      // 3) SetDateTime (use platform timezone from provisioning config)
      final keyLocalTime = AccessDecisionTime.resolveKeyLocalTime(
        provisioningConfig,
      );
      await controller.executeVendorOperationAndWait(
        index: 15,
        expectedOperationName: 'SetDateTime',
        mac: _selectedMac,
        args: _sdkArgs(keyLocalTime: keyLocalTime),
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

  Map<String, Object?> _baseSdkArgs({String? keyLocalTime}) {
    return <String, Object?>{
      'secret': _secretController.text.trim(),
      'oldSecret': _secretController.text.trim(),
      'sign': int.tryParse(_signController.text.trim()) ?? 1,
      'lic': _licController.text.trim(),
      'lockIds': _selectedLock?.number ?? '',
      if (keyLocalTime != null && keyLocalTime.isNotEmpty)
        'time': keyLocalTime,
    };
  }

  Map<String, Object?> _sdkArgs({String? keyLocalTime}) =>
      _baseSdkArgs(keyLocalTime: keyLocalTime);

  Future<Map<String, dynamic>?> _getProvisioningConfigSafely({
    required String token,
  }) async {
    try {
      return await Api.getProvisioningConfig(
        token: token,
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      return null;
    }
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

  bool _reasonsIndicateGroupLockout(dynamic reasons) {
    if (reasons is! List) return false;
    for (final item in reasons) {
      if (isGroupLockoutBlockedReason(item.toString())) return true;
    }
    return false;
  }

  Future<void> _showGroupLockoutBlockedDialog({
    required String reasons,
    String? taskId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearanceBlockedDialogTitle),
        content: Text(l10n.clearanceBlockedDialogBody(reasons)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.clearanceGoToTasks),
          ),
        ],
      ),
    );
    if (go == true && mounted) {
      await Navigator.of(context).pushNamed(
        Routes.workerClearance,
        arguments: <String, dynamic>{'taskId': taskId},
      );
    }
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
          _KeyConnectionCard(
            phase: _connectionPhase,
            vendorKeyId: widget.number,
            boundMac: widget.bleMac,
            connectedMac: _selectedMac,
            busy: _busy || _autoConnectInFlight,
            scanning: controller.scanning,
            onRetry: _retryAutoConnect,
            sectionLabel: l10n.keyUnlockConnectionSection,
            boundKeyMacLabel: l10n.keyUnlockKeyMacReadonly,
            scanningLabel: l10n.keyUnlockScanningKey,
            connectingLabel: l10n.keyUnlockConnectingKey,
            connectedLabel: l10n.keyUnlockKeyConnected,
            failedLabel: l10n.keyUnlockKeyConnectFailed,
            retryLabel: l10n.keyUnlockRetryConnect,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy || _connectionPhase != _KeyConnectionPhase.connected
                ? null
                : () => _setSwitchState('unlocked'),
            icon: const Icon(Icons.lock_open),
            label: Text(l10n.keyUnlockUnlockAction),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _busy || _connectionPhase != _KeyConnectionPhase.connected
                ? null
                : () => _setSwitchState('locked'),
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

bool _macLabelMatches(String mac, String vendorKeyId) {
  final left = mac.replaceAll(':', '').replaceAll('-', '').toLowerCase();
  final right = vendorKeyId.replaceAll(':', '').replaceAll('-', '').toLowerCase();
  return left == right;
}

class _KeyConnectionCard extends StatelessWidget {
  const _KeyConnectionCard({
    required this.phase,
    required this.vendorKeyId,
    required this.boundMac,
    required this.connectedMac,
    required this.busy,
    required this.scanning,
    required this.onRetry,
    required this.sectionLabel,
    required this.boundKeyMacLabel,
    required this.scanningLabel,
    required this.connectingLabel,
    required this.connectedLabel,
    required this.failedLabel,
    required this.retryLabel,
  });

  final _KeyConnectionPhase phase;
  final String vendorKeyId;
  final String boundMac;
  final String? connectedMac;
  final bool busy;
  final bool scanning;
  final VoidCallback onRetry;
  final String sectionLabel;
  final String boundKeyMacLabel;
  final String scanningLabel;
  final String connectingLabel;
  final String connectedLabel;
  final String failedLabel;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = switch (phase) {
      _KeyConnectionPhase.scanning => scanningLabel,
      _KeyConnectionPhase.connecting => connectingLabel,
      _KeyConnectionPhase.connected => connectedLabel,
      _KeyConnectionPhase.failed => failedLabel,
      _ => scanningLabel,
    };
    final statusIcon = switch (phase) {
      _KeyConnectionPhase.connected => Icons.bluetooth_connected,
      _KeyConnectionPhase.failed => Icons.bluetooth_disabled,
      _ => Icons.bluetooth_searching,
    };
    final statusColor = switch (phase) {
      _KeyConnectionPhase.connected => theme.colorScheme.primary,
      _KeyConnectionPhase.failed => theme.colorScheme.error,
      _ => theme.colorScheme.onSurfaceVariant,
    };
    final showSpinner =
        phase == _KeyConnectionPhase.scanning ||
        phase == _KeyConnectionPhase.connecting ||
        scanning;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(sectionLabel, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(statusLabel, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Text(
                          '${boundKeyMacLabel}: ${connectedMac ?? (boundMac.isNotEmpty ? boundMac : vendorKeyId)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (vendorKeyId.isNotEmpty &&
                            connectedMac != null &&
                            !_macLabelMatches(connectedMac!, vendorKeyId))
                          Text(
                            'Key ID: $vendorKeyId',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (showSpinner)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            if (phase == _KeyConnectionPhase.failed) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: busy ? null : onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
