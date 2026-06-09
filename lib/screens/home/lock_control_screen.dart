import 'package:flutter/material.dart';
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
      'switchCount': 1,
      'unlock': nextState == 'unlocked',
    };
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
