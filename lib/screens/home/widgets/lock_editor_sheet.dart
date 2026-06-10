import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blekey_sdk/flutter_blekey_sdk.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../ble_key/ble_key_controller.dart';
import '../models.dart';

/// Shows the lock creation/editing step-by-step bottom sheet.
///
/// Returns [LockEditorResult] on save, or `null` if dismissed.
Future<LockEditorResult?> showLockEditorSheet(
  BuildContext context, {
  LockItem? initial,
}) {
  final l10n = AppLocalizations.of(context)!;
  final nameController = TextEditingController(text: initial?.name ?? '');
  final numberController = TextEditingController(text: initial?.number ?? '');
  final locationController =
      TextEditingController(text: initial?.location ?? '');
  var switchState = initial?.switchState ?? 'locked';
  var currentStep = 0;
  var selectedMac = '';
  var sdkBusy = false;
  var sdkMessage = '';
  JsonMap? readLockId;

  return showModalBottomSheet<LockEditorResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return FractionallySizedBox(
            heightFactor: 0.92,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.of(context).viewInsets.bottom + 12,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      initial == null
                          ? l10n.lockWizardCreateTitle
                          : l10n.lockWizardEditTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Stepper(
                      type: StepperType.vertical,
                      currentStep: currentStep,
                      onStepTapped: (value) {
                        setSheetState(() => currentStep = value);
                      },
                      controlsBuilder: (context, details) {
                        final isLast = currentStep == 5;
                        return Row(
                          children: [
                            FilledButton(
                              onPressed: isLast
                                  ? () {
                                      final name = nameController.text.trim();
                                      final number =
                                          numberController.text.trim();
                                      final location =
                                          locationController.text.trim();
                                      if (name.isEmpty || number.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              l10n.lockWizardFillRequired,
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      Navigator.of(context).pop(
                                        LockEditorResult(
                                          createPayload:
                                              _buildLockCreatePayload(
                                            name: name,
                                            vendorLockId: number,
                                            location: location,
                                            switchState: switchState,
                                            readLockId: readLockId,
                                          ),
                                          updatePayload:
                                              _buildLockUpdatePayload(
                                            name: name,
                                            location: location,
                                            switchState: switchState,
                                          ),
                                        ),
                                      );
                                    }
                                  : () => setSheetState(
                                      () => currentStep = currentStep + 1,
                                    ),
                              child: Text(
                                isLast
                                    ? l10n.keyWizardSave
                                    : l10n.keyWizardNext,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (currentStep > 0)
                              OutlinedButton(
                                onPressed: () => setSheetState(
                                  () => currentStep = currentStep - 1,
                                ),
                                child: Text(l10n.keyWizardPrevious),
                              ),
                          ],
                        );
                      },
                      steps: [
                        // Step 0: Connect Device
                        Step(
                          title: Text(l10n.keyWizardStepConnect),
                          isActive: currentStep >= 0,
                          content: Consumer<BleKeyController>(
                            builder: (context, controller, _) {
                              if (selectedMac.isEmpty &&
                                  controller.devices.isNotEmpty) {
                                selectedMac =
                                    controller.devices.first.mac ?? '';
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.lockWizardConnectHint),
                                  const SizedBox(height: 8),
                                  FilledButton.icon(
                                    onPressed: sdkBusy
                                        ? null
                                        : () async {
                                            setSheetState(() {
                                              sdkBusy = true;
                                              sdkMessage =
                                                  l10n.keyWizardScanning;
                                            });
                                            try {
                                              await controller.ensureReady();
                                              await controller.startScan(
                                                timeoutMs: 10000,
                                              );
                                              setSheetState(() {
                                                sdkMessage =
                                                    l10n.keyWizardScanStarted;
                                              });
                                            } catch (error) {
                                              setSheetState(() {
                                                sdkMessage =
                                                    '${l10n.lockWizardPrepareFailed}: ${_formatRequestError(error)}';
                                              });
                                            } finally {
                                              setSheetState(
                                                () => sdkBusy = false,
                                              );
                                            }
                                          },
                                    icon: const Icon(
                                      Icons.bluetooth_searching,
                                    ),
                                    label: Text(
                                      controller.scanning
                                          ? l10n.keyWizardScanningShort
                                          : l10n.keyWizardScanKey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: selectedMac.isEmpty
                                        ? null
                                        : selectedMac,
                                    decoration: const InputDecoration(
                                      labelText: 'MAC',
                                    ),
                                    items: controller.devices
                                        .where(
                                          (device) =>
                                              device.mac?.isNotEmpty == true,
                                        )
                                        .map(
                                          (device) => DropdownMenuItem(
                                            value: device.mac,
                                            child: Text(
                                              '${device.name ?? l10n.unnamedDevice} ${device.mac}',
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: sdkBusy
                                        ? null
                                        : (value) => setSheetState(
                                            () => selectedMac = value ?? ''),
                                  ),
                                  const SizedBox(height: 8),
                                  FilledButton.tonalIcon(
                                    onPressed:
                                        sdkBusy || selectedMac.isEmpty
                                            ? null
                                            : () async {
                                                setSheetState(() {
                                                  sdkBusy = true;
                                                  sdkMessage = l10n
                                                      .lockWizardPreparingCollector;
                                                });
                                                try {
                                                  await _prepareLockCollector(
                                                    context
                                                        .read<
                                                            BleKeyController>(),
                                                    selectedMac,
                                                  );
                                                  setSheetState(() {
                                                    sdkMessage = l10n
                                                        .lockWizardCollectorReady;
                                                  });
                                                } catch (error) {
                                                  setSheetState(() {
                                                    sdkMessage =
                                                        '${l10n.lockWizardPrepareFailed}: $error';
                                                  });
                                                } finally {
                                                  setSheetState(
                                                    () => sdkBusy = false,
                                                  );
                                                }
                                              },
                                    icon: sdkBusy
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.sensors),
                                    label:
                                        Text(l10n.lockWizardPrepareAction),
                                  ),
                                  if (sdkMessage.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(sdkMessage),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                        // Step 1: Read Lock ID
                        Step(
                          title: Text(l10n.lockWizardStepReadId),
                          isActive: currentStep >= 1,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.lockWizardReadHint),
                              const SizedBox(height: 8),
                              FilledButton.tonalIcon(
                                onPressed: sdkBusy
                                    ? null
                                    : () async {
                                        setSheetState(() {
                                          sdkBusy = true;
                                          sdkMessage =
                                              l10n.lockWizardWaitingReport;
                                        });
                                        try {
                                          final report =
                                              await _waitForLockIdReport(
                                            context.read<BleKeyController>(),
                                          );
                                          final lockId =
                                              _extractHardwareId(report);
                                          if (lockId == null ||
                                              lockId.isEmpty) {
                                            throw StateError(
                                              l10n.lockWizardParseFailed,
                                            );
                                          }
                                          setSheetState(() {
                                            readLockId = report;
                                            numberController.text = lockId;
                                            if (nameController.text
                                                .trim()
                                                .isEmpty) {
                                              nameController.text = lockId;
                                            }
                                            sdkMessage =
                                                '${l10n.lockWizardReadSuccess}: $lockId';
                                          });
                                        } catch (error) {
                                          setSheetState(() {
                                            sdkMessage =
                                                '${l10n.lockWizardReadFailed}: $error';
                                          });
                                        } finally {
                                          setSheetState(
                                            () => sdkBusy = false,
                                          );
                                        }
                                      },
                                icon: sdkBusy
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.touch_app_outlined),
                                label: Text(l10n.lockWizardReadAction),
                              ),
                              if (sdkMessage.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(sdkMessage),
                              ],
                              const SizedBox(height: 8),
                              TextField(
                                controller: numberController,
                                enabled: initial == null,
                                decoration: InputDecoration(
                                  labelText: l10n.lockWizardLockNumber,
                                  helperText:
                                      l10n.lockWizardLockNumberHelper,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Step 2: Basic Information
                        Step(
                          title: Text(l10n.lockWizardStepBasic),
                          isActive: currentStep >= 2,
                          content: TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: l10n.lockWizardLockName,
                            ),
                          ),
                        ),
                        // Step 3: Status
                        Step(
                          title: Text(l10n.lockWizardStepStatus),
                          isActive: currentStep >= 3,
                          content: DropdownButtonFormField<String>(
                            initialValue: switchState,
                            decoration: InputDecoration(
                              labelText: l10n.lockWizardSwitchState,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'locked',
                                child: Text(l10n.lockStateLocked),
                              ),
                              DropdownMenuItem(
                                value: 'unlocked',
                                child: Text(l10n.lockStateUnlocked),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setSheetState(() => switchState = value);
                              }
                            },
                          ),
                        ),
                        // Step 4: Location
                        Step(
                          title: Text(l10n.lockWizardStepLocation),
                          isActive: currentStep >= 4,
                          content: TextField(
                            controller: locationController,
                            decoration: InputDecoration(
                              labelText: l10n.lockWizardLocation,
                            ),
                          ),
                        ),
                        // Step 5: Confirm
                        Step(
                          title: Text(l10n.wizardConfirmStep),
                          isActive: currentStep >= 5,
                          content: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${l10n.lockWizardLockNameSummary}: ${nameController.text.trim().isEmpty ? '-' : nameController.text.trim()}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${l10n.lockWizardLockNumberSummary}: ${numberController.text.trim().isEmpty ? '-' : numberController.text.trim()}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${l10n.lockWizardLocationSummary}: ${locationController.text.trim().isEmpty ? '-' : locationController.text.trim()}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${l10n.lockWizardSwitchStateSummary}: ${switchState == 'locked' ? l10n.lockStateLocked : l10n.lockStateUnlocked}',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// ─── SDK helper methods ──────────────────────────────────────────────────────

const Map<String, Object?> _sdkConnectArgs = <String, Object?>{
  'secret': 'FFFFFFFFFFFFFFFFFFFF',
  'oldSecret': 'FFFFFFFFFFFFFFFFFFFF',
  'sign': 1,
  'lic': 'FFFFFFFFFFFFFFFF',
};

Future<void> _prepareLockCollector(
  BleKeyController controller,
  String mac,
) async {
  await controller.executeVendorOperationAndWait(
    index: 0,
    expectedOperationName: 'ConnectKey',
    mac: mac,
    args: _sdkConnectArgs,
    timeout: const Duration(seconds: 15),
  );
  await controller.executeVendorOperationAndWait(
    index: 8,
    expectedOperationName: 'SetReadLockIdKey',
    mac: mac,
    args: _sdkConnectArgs,
    timeout: const Duration(seconds: 15),
  );
}

Future<JsonMap> _waitForLockIdReport(BleKeyController controller) async {
  final result = await controller.waitForOperationResult(
    expectedOperationName: 'Report',
    where: (result) {
      final objText = result.objText ?? result.obj?.toString() ?? '';
      return _extractCommand(objText) == 19 ||
          objText.toLowerCase().contains('cmd=19');
    },
    timeout: const Duration(seconds: 90),
  );
  return _sdkResultToJson('Report', result);
}

JsonMap _sdkResultToJson(
    String operationName, BleKeyOperationResult result) {
  final obj = _normalizeSdkObject(result.obj);
  final objText = result.objText ?? obj.toString();
  final json = <String, dynamic>{
    'operation': operationName,
    'ret': result.ret,
    'code': result.code,
    'msg': result.msg,
    'obj': obj,
    'objText': objText,
  };
  final id = _extractHardwareIdFromObject(obj) ??
      _extractHardwareIdFromText(objText);
  if (id != null) json['id'] = id;
  final cmd = _extractCommand(objText);
  if (cmd != null) json['cmd'] = cmd;
  return json;
}

Object _normalizeSdkObject(Object? value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  if (value is List) {
    return value
        .map<Object>((item) => _normalizeSdkObject(item))
        .toList(growable: false);
  }
  return value ?? '';
}

int? _extractCommand(String text) {
  final match =
      RegExp(r'cmd\s*[=:]\s*(\d+)', caseSensitive: false).firstMatch(text);
  if (match == null) return null;
  return int.tryParse(match.group(1) ?? '');
}

String? _extractHardwareIdFromObject(Object? value) {
  if (value is Map) {
    final json = Map<String, dynamic>.from(value);
    for (final key in const ['mac', 'vendorKeyId', 'keyId', 'id', 'sign']) {
      final candidate = json[key]?.toString().trim();
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }
    for (final nestedValue in json.values) {
      final nested = _extractHardwareIdFromObject(nestedValue);
      if (nested != null) return nested;
    }
    return null;
  }
  if (value is List) {
    for (final item in value) {
      final nested = _extractHardwareIdFromObject(item);
      if (nested != null) return nested;
    }
    return null;
  }
  return value == null
      ? null
      : _extractHardwareIdFromText(value.toString());
}

String? _extractHardwareIdFromText(String text) {
  final patterns = <RegExp>[
    RegExp(r'keyId\s*[=:]\s*([0-9A-Fa-f]{6,})'),
    RegExp(r'lockid\s*[=:]\s*([0-9A-Fa-f]{6,})', caseSensitive: false),
    RegExp(r'lockId\s*[=:]\s*([0-9A-Fa-f]{6,})'),
    RegExp(r'\bid\s*[=:]\s*([0-9A-Fa-f]{6,})'),
  ];
  for (final pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) return match.group(1);
  }
  return null;
}

String? _extractHardwareId(JsonMap sdkResult) {
  final direct = _extractHardwareIdFromObject(sdkResult['id']) ??
      _extractHardwareIdFromObject(sdkResult['obj']);
  if (direct != null && direct.isNotEmpty) return direct;
  return _extractHardwareIdFromText(
    sdkResult['objText']?.toString() ?? sdkResult['obj']?.toString() ?? '',
  );
}

JsonMap _buildLockCreatePayload({
  required String name,
  required String vendorLockId,
  required String location,
  required String switchState,
  JsonMap? readLockId,
}) {
  final metadata = <String, dynamic>{
    'provisioningFlow': 'app_lock_create',
    'captureMethod': 'ReadLockId',
    'usingKeyVendorKeyId': '',
    'department': 'Cereb',
    'status': 'uninstalled',
    'switchState': switchState,
    'battery': 100,
    'signal': 'Unknown',
    'location': location,
    'latitude': null,
    'longitude': null,
    'source': 'android_app',
    'capturedAt': DateTime.now().toIso8601String(),
  };
  if (readLockId != null) {
    metadata['readLockId'] = readLockId;
  }
  return <String, dynamic>{
    'vendor': 'smartlock',
    'vendorLockId': vendorLockId,
    'name': name,
    'assetId': null,
    'metadata': metadata,
  };
}

JsonMap _buildLockUpdatePayload({
  required String name,
  required String location,
  required String switchState,
}) {
  return <String, dynamic>{
    'name': name,
    'assetId': null,
    'metadata': <String, dynamic>{
      'location': location,
      'switchState': switchState,
      'source': 'android_app',
      'updatedFrom': 'app_lock_edit',
      'capturedAt': DateTime.now().toIso8601String(),
    },
  };
}

String _formatRequestError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final details = _extractErrorDetails(error.response?.data);
    if (status != null && details.isNotEmpty) {
      return 'HTTP $status: $details';
    }
    if (details.isNotEmpty) return details;
    if (status != null) return 'HTTP $status';
    return error.message ?? error.toString();
  }
  return error.toString();
}

String _extractErrorDetails(dynamic data) {
  if (data == null) return '';
  if (data is String) return data;
  if (data is List) {
    final parts = data
        .map((e) => _extractErrorDetails(e))
        .where((e) => e.isNotEmpty);
    return parts.join('; ');
  }
  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    for (final key in const ['message', 'error', 'msg', 'detail']) {
      final text = map[key]?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    final errors = map['errors'] ?? map['details'] ?? map['violations'];
    final nested = _extractErrorDetails(errors);
    if (nested.isNotEmpty) return nested;
    return map.toString();
  }
  return data.toString();
}
