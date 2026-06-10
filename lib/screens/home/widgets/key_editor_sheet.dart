import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blekey_sdk/flutter_blekey_sdk.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../ble_key/ble_key_controller.dart';
import '../models.dart';

/// Shows the key creation/editing step-by-step bottom sheet.
///
/// Returns [KeyEditorResult] on save, or `null` if dismissed.
Future<KeyEditorResult?> showKeyEditorSheet(
  BuildContext context, {
  KeyItem? initial,
}) {
  final l10n = AppLocalizations.of(context)!;
  final nameController = TextEditingController(text: initial?.name ?? '');
  final numberController = TextEditingController(text: initial?.number ?? '');
  var keyType = _normalizeKeyType(initial?.keyType) ?? 'standard';
  var status = initial?.status ?? 'active';
  var currentStep = 0;
  var selectedMac = '';
  var sdkBusy = false;
  var sdkMessage = '';
  JsonMap? readKeyInfo;

  return showModalBottomSheet<KeyEditorResult>(
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
                          ? l10n.keyWizardCreateTitle
                          : l10n.keyWizardEditTitle,
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
                        final isLast = currentStep == 2;
                        return Row(
                          children: [
                            FilledButton(
                              onPressed: isLast
                                  ? () {
                                      final name = nameController.text.trim();
                                      final number =
                                          numberController.text.trim();
                                      if (name.isEmpty || number.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              l10n.keyWizardFillRequired,
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      Navigator.of(context).pop(
                                        KeyEditorResult(
                                          createPayload:
                                              _buildKeyCreatePayload(
                                            name: name,
                                            vendorKeyId: number,
                                            keyType: keyType,
                                            status: status,
                                            bleMac: selectedMac,
                                            readKeyInfo: readKeyInfo,
                                          ),
                                          updatePayload:
                                              _buildKeyUpdatePayload(
                                            name: name,
                                            keyType: keyType,
                                            status: status,
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
                                  Text(l10n.keyWizardConnectHint),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: sdkBusy
                                              ? null
                                              : () async {
                                                  setSheetState(() {
                                                    sdkBusy = true;
                                                    sdkMessage =
                                                        l10n.keyWizardScanning;
                                                  });
                                                  try {
                                                    await controller
                                                        .ensureReady();
                                                    await controller.startScan(
                                                      timeoutMs: 10000,
                                                    );
                                                    setSheetState(() {
                                                      sdkMessage = l10n
                                                          .keyWizardScanStarted;
                                                    });
                                                  } catch (error) {
                                                    setSheetState(() {
                                                      sdkMessage =
                                                          '${l10n.keyWizardReadFailed}: ${_formatRequestError(error)}';
                                                    });
                                                  } finally {
                                                    setSheetState(() {
                                                      sdkBusy = false;
                                                    });
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
                                      ),
                                    ],
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
                                    onPressed: sdkBusy || selectedMac.isEmpty
                                        ? null
                                        : () async {
                                            setSheetState(() {
                                              sdkBusy = true;
                                              sdkMessage =
                                                  l10n.keyWizardReadingInfo;
                                            });
                                            try {
                                              final info =
                                                  await _readKeyHardware(
                                                context.read<BleKeyController>(),
                                                selectedMac,
                                              );
                                              final vendorKeyId =
                                                  _extractHardwareId(info) ??
                                                      selectedMac;
                                              final generatedName =
                                                  _defaultBleKeyName(
                                                      vendorKeyId);
                                              setSheetState(() {
                                                readKeyInfo = info;
                                                numberController.text =
                                                    vendorKeyId;
                                                keyType = _keyTypeFromInfo(info);
                                                final currentName =
                                                    nameController.text.trim();
                                                if (currentName.isEmpty ||
                                                    currentName.startsWith(
                                                        'BLE Key ')) {
                                                  nameController.text =
                                                      generatedName;
                                                }
                                                sdkMessage =
                                                    '${l10n.keyWizardReadSuccess}: $vendorKeyId';
                                              });
                                            } catch (error) {
                                              setSheetState(() {
                                                sdkMessage =
                                                    '${l10n.keyWizardReadFailed}: $error';
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
                                        : const Icon(Icons.key_outlined),
                                    label: Text(l10n.keyWizardReadAction),
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
                        // Step 1: Fill Information
                        Step(
                          title: Text(l10n.keyWizardStepInfo),
                          isActive: currentStep >= 1,
                          content: Column(
                            children: [
                              TextField(
                                controller: nameController,
                                decoration: InputDecoration(
                                  labelText: l10n.keyWizardKeyName,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: numberController,
                                enabled: initial == null,
                                decoration: InputDecoration(
                                  labelText: l10n.keyWizardKeyNumber,
                                  helperText: l10n.keyWizardKeyNumberHelper,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: keyType,
                                decoration: InputDecoration(
                                  labelText: l10n.keyWizardKeyType,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'standard',
                                    child: Text('standard'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'bluetooth',
                                    child: Text('bluetooth'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'fingerprint',
                                    child: Text('fingerprint'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'cellular',
                                    child: Text('cellular'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'display',
                                    child: Text('display'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'emergency',
                                    child: Text('emergency'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setSheetState(() => keyType = value);
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: status,
                                decoration: InputDecoration(
                                  labelText: l10n.keyWizardStatus,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'active',
                                    child: Text('active'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'damaged',
                                    child: Text('damaged'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'lost',
                                    child: Text('lost'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setSheetState(() => status = value);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        // Step 2: Confirm
                        Step(
                          title: Text(l10n.wizardConfirmStep),
                          isActive: currentStep >= 2,
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
                                  '${l10n.keyWizardKeyName}: ${nameController.text.trim().isEmpty ? '-' : nameController.text.trim()}',
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${l10n.keyWizardKeyNumberSummary}: ${numberController.text.trim().isEmpty ? '-' : numberController.text.trim()}',
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${l10n.keyWizardTypeSummary}: $keyType',
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${l10n.keyWizardStatusSummary}: $status',
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

Future<JsonMap> _readKeyHardware(
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
  final result = await controller.executeVendorOperationAndWait(
    index: 2,
    expectedOperationName: 'ReadKeyInfo',
    mac: mac,
    args: _sdkConnectArgs,
    timeout: const Duration(seconds: 15),
  );
  return _sdkResultToJson('ReadKeyInfo', result);
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

String _defaultBleKeyName(String identifier) => 'BLE Key $identifier';

String? _extractHardwareId(JsonMap sdkResult) {
  final direct = _extractHardwareIdFromObject(sdkResult['id']) ??
      _extractHardwareIdFromObject(sdkResult['obj']);
  if (direct != null && direct.isNotEmpty) return direct;
  return _extractHardwareIdFromText(
    sdkResult['objText']?.toString() ?? sdkResult['obj']?.toString() ?? '',
  );
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

int? _extractCommand(String text) {
  final match =
      RegExp(r'cmd\s*[=:]\s*(\d+)', caseSensitive: false).firstMatch(text);
  if (match == null) return null;
  return int.tryParse(match.group(1) ?? '');
}

/// Map legacy key type values to the canonical set
String? _normalizeKeyType(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  const legacyMap = <String, String>{
    '4g': 'cellular',
    '4G': 'cellular',
  };
  return legacyMap[raw] ?? raw;
}

String _keyTypeFromInfo(JsonMap sdkResult) {
  final objText =
      (sdkResult['objText'] ?? sdkResult['obj'] ?? '').toString().toLowerCase();
  final mode = _extractIntFromObject(sdkResult['obj'], 'mode') ??
      _extractIntFromText(objText, 'mode');

  if (objText.contains('bluetooth') || objText.contains('ble')) {
    return 'bluetooth';
  }
  if (objText.contains('4g') ||
      objText.contains('cellular') ||
      objText.contains('mobileparam')) {
    return 'cellular';
  }
  if (objText.contains('finger')) return 'fingerprint';
  if (mode == 1) return 'emergency';
  return 'standard';
}

int? _extractIntFromObject(Object? value, String key) {
  if (value is Map) {
    final json = Map<String, dynamic>.from(value);
    final direct = int.tryParse(json[key]?.toString() ?? '');
    if (direct != null) return direct;
    for (final nested in json.values) {
      final found = _extractIntFromObject(nested, key);
      if (found != null) return found;
    }
    return null;
  }
  if (value is List) {
    for (final item in value) {
      final found = _extractIntFromObject(item, key);
      if (found != null) return found;
    }
  }
  return null;
}

int? _extractIntFromText(String text, String field) {
  final match =
      RegExp('$field\\s*[=:]\\s*(\\d+)', caseSensitive: false)
          .firstMatch(text);
  if (match == null) return null;
  return int.tryParse(match.group(1) ?? '');
}

JsonMap _buildKeyCreatePayload({
  required String name,
  required String vendorKeyId,
  required String keyType,
  required String status,
  required String bleMac,
  JsonMap? readKeyInfo,
}) {
  final metadata = <String, dynamic>{
    'provisioningFlow': 'app_key_create',
    'department': 'Cereb',
    'source': 'android_app',
    'capturedAt': DateTime.now().toIso8601String(),
  };
  if (bleMac.isNotEmpty) {
    metadata['bleMac'] = bleMac;
  }
  if (readKeyInfo != null) {
    metadata['readKeyInfo'] = readKeyInfo;
  }
  return <String, dynamic>{
    'vendor': 'smartlock',
    'vendorKeyId': vendorKeyId,
    'keyType': keyType,
    'name': name,
    'ownerUserId': null,
    'sign': 1,
    'metadata': metadata,
  };
}

JsonMap _buildKeyUpdatePayload({
  required String name,
  required String keyType,
  required String status,
}) {
  return <String, dynamic>{
    'name': name,
    'keyType': keyType,
    'metadata': <String, dynamic>{
      'status': status,
      'department': 'Cereb',
      'source': 'android_app',
      'updatedFrom': 'app_key_edit',
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
