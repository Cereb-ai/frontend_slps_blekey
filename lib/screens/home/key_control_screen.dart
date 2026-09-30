import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blekey_sdk/flutter_blekey_sdk.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api.dart';
import '../../l10n/app_localizations.dart';
import '../../models/current_task_package.dart';
import '../../services/ble_task_service.dart';
import '../../services/ble_record.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/offline_data_store.dart';
import '../ble_key/ble_key_controller.dart';
import '../../states/global_user.dart';
import '../../states/location_provider.dart';
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
    this.sign = 1,
    this.lic = 'FFFFFFFFFFFFFFFF',
    this.secret = 'FFFFFFFFFFFFFFFFFFFF',
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

  /// Per-key SDK connection parameters returned by `/slps/keys`.
  final int sign;
  final String lic;
  final String secret;

  factory KeyControlScreen.fromArgs(Map<String, dynamic>? args) {
    final data = args ?? const <String, dynamic>{};
    return KeyControlScreen(
      keyId: (data['keyId'] ?? '').toString(),
      name: (data['name'] ?? '-').toString(),
      number: (data['number'] ?? '').toString(),
      bleMac: (data['bleMac'] ?? '').toString(),
      keyType: (data['keyType'] ?? 'standard').toString(),
      sign: data['sign'] is num
          ? (data['sign'] as num).toInt()
          : int.tryParse(data['sign']?.toString() ?? '') ?? 1,
      lic: (data['lic'] ?? data['license'] ?? 'FFFFFFFFFFFFFFFF').toString(),
      secret: (data['secret'] ?? 'FFFFFFFFFFFFFFFFFFFF').toString(),
    );
  }

  @override
  State<KeyControlScreen> createState() => _KeyControlScreenState();
}

class _KeyControlScreenState extends State<KeyControlScreen>
    with WidgetsBindingObserver {
  static const _pendingEventsKeyPrefix = 'ble_key_pending_lock_events_v1_';
  static const _localSyncStatusKey = '_localSyncStatus';
  static const _localSyncedAtKey = '_localSyncedAt';

  bool _busy = false;
  bool _taskLoading = false;
  CurrentTaskPackage? _task;
  Map<String, dynamic>? _taskMetadata;
  Map<String, dynamic>? _receipt;
  String? _taskError;
  String? _historyError;
  bool _keyVerified = false;
  bool _readingHistory = false;
  bool _liveReportDuringHistory = false;
  late Future<void> _pendingLoaded;
  BleTaskService get _service =>
      BleTaskService(_bleController!.executeVendorOperationAndWait);
  String? _selectedMac;
  List<LockItem> _availableLocks = <LockItem>[];
  _KeyConnectionPhase _connectionPhase = _KeyConnectionPhase.idle;
  bool _autoConnectInFlight = false;
  bool _wasScanning = false;
  Completer<void>? _connectionCompleter;
  BleKeyController? _bleController;
  StreamSubscription<BleKeyEvent>? _reportSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Future<void> _reportProcessing = Future<void>.value();
  bool _authorized = false;
  bool _syncingPendingEvents = false;
  bool _hasNetworkConnection = true;
  List<Map<String, dynamic>> _pendingEvents = <Map<String, dynamic>>[];

  late final TextEditingController _secretController;
  late final TextEditingController _signController;
  late final TextEditingController _licController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secretController = TextEditingController(text: widget.secret);
    _signController = TextEditingController(text: widget.sign.toString());
    _licController = TextEditingController(text: widget.lic);
    _selectedMac = _preferredBleMac();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = context.read<BleKeyController>();
      _bleController = controller;
      controller.addListener(_onBleControllerChanged);
      _reportSubscription = controller.operationEvents.listen(_onSdkEvent);
      unawaited(_startConnectivityMonitoring());
      _pendingLoaded = _loadPendingEventsAndSync();
      unawaited(_loadTask());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final controller = _bleController;
    controller?.removeListener(_onBleControllerChanged);
    unawaited(_reportSubscription?.cancel());
    unawaited(_connectivitySubscription?.cancel());
    if (controller != null) {
      unawaited(_releaseBleResources(controller));
    }
    _secretController.dispose();
    _signController.dispose();
    _licController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshConnectivityAndSync());
    }
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
        _completeConnectionAttempt(
          StateError('The configured BLE key was not found.'),
        );
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
      _completeConnectionAttempt(StateError('Unable to start BLE scan.'));
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
    _wasScanning = false;
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
      await _service.verifyKey(widget.number);
      if (!mounted) {
        _completeConnectionAttempt(StateError('页面已关闭'));
        return;
      }
      _keyVerified = true;
      if (mounted) {
        setState(() => _connectionPhase = _KeyConnectionPhase.connected);
      }
      await _readHistory();
      _completeConnectionAttempt();
    } catch (error) {
      _keyVerified = false;
      await controller.executeVendorOperation(index: 1);
      if (mounted) {
        setState(() => _connectionPhase = _KeyConnectionPhase.failed);
      }
      _completeConnectionAttempt(error);
    } finally {
      _autoConnectInFlight = false;
    }
  }

  void _completeConnectionAttempt([Object? error]) {
    final completer = _connectionCompleter;
    if (completer == null || completer.isCompleted) return;
    if (error == null) {
      completer.complete();
    } else {
      completer.completeError(error);
    }
  }

  Future<void> _ensureConnected() async {
    if (_connectionPhase == _KeyConnectionPhase.connected &&
        _selectedMac != null &&
        _selectedMac!.isNotEmpty) {
      return;
    }

    final activeAttempt = _connectionCompleter;
    if (activeAttempt != null && !activeAttempt.isCompleted) {
      return activeAttempt.future;
    }

    final completer = Completer<void>();
    _connectionCompleter = completer;
    unawaited(_beginAutoConnect());
    try {
      await completer.future.timeout(const Duration(seconds: 100));
    } finally {
      if (identical(_connectionCompleter, completer)) {
        _connectionCompleter = null;
      }
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
        if ([device.key, device.keyId].any((id) => id?.trim() == vendorKeyId)) {
          final mac = device.mac;
          if (mac != null && mac.isNotEmpty) return mac;
        }
      }
    }

    return null;
  }

  Future<CurrentTaskPackage?> _loadTask() async {
    final token = GlobalUser.instance.token;
    if (!mounted) return null;
    setState(() {
      _taskLoading = true;
      _task = null;
      _taskError = null;
      _taskMetadata = null;
    });
    try {
      if (token == null || token.isEmpty) throw StateError('请重新登录');
      final task = CurrentTaskPackage.fromJson(
        await Api.getCurrentTaskPackage(token: token, keyId: widget.keyId),
      );
      if (task.vendorKeyId != widget.number) throw StateError('任务包钥匙标识与页面不一致');
      final key = await Api.getLockKey(token: token, keyId: widget.keyId);
      final metadata = key['currentTask'] is Map
          ? Map<String, dynamic>.from(key['currentTask'] as Map)
          : null;
      if (_connectionPhase != _KeyConnectionPhase.connected) {
        _secretController.text = (key['secret'] ?? widget.secret).toString();
        _signController.text = (key['sign'] ?? widget.sign).toString();
        _licController.text = (key['lic'] ?? widget.lic).toString();
      }
      if (metadata == null ||
          metadata['id'] != task.taskId ||
          metadata['geofenceRequired'] is! bool ||
          DateTime.tryParse(metadata['updatedAt']?.toString() ?? '') !=
              DateTime.parse(task.taskUpdatedAt)) {
        throw StateError('无法核实当前任务定位限制或版本，请刷新后重试');
      }
      if (task.isOffline && metadata['geofenceRequired'] == true) {
        throw StateError('此任务要求手机定位，不能下载到离线钥匙');
      }
      var locks = <LockItem>[];
      try {
        locks = (await Api.listLockDevices(
          token: token,
        )).map(_mapApiLock).toList();
      } catch (_) {
        if (!task.isOffline) rethrow;
      }
      final receipt = await OfflineDataStore.readObject(
        'key_receipt_${widget.keyId}',
      );
      if (!mounted) return null;
      setState(() {
        _task = task;
        _taskMetadata = metadata;
        _receipt = receipt;
        _availableLocks = locks;
      });
      return task;
    } catch (error) {
      if (mounted) setState(() => _taskError = _taskFailure(error));
      return null;
    } finally {
      if (mounted) setState(() => _taskLoading = false);
    }
  }

  String _taskFailure(Object error) {
    if (error is DioException) {
      return switch (error.response?.statusCode) {
        400 => '设备类型不支持或请求不合法',
        401 => '登录已过期，请重新登录',
        403 => '无权使用该任务',
        404 => '暂无有效任务',
        _ => '任务加载失败，请联网重试',
      };
    }
    return error.toString();
  }

  String get _pendingEventsKey => '$_pendingEventsKeyPrefix${widget.keyId}';

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

  Future<void> _authorizeKey() async {
    if (_busy || _taskLoading) return;
    setState(() {
      _busy = true;
      _authorized = false;
    });
    try {
      final displayed = _task;
      final task = await _loadTask();
      if (task == null) return;
      // A changed mode/version requires the user to see the new action first.
      if (displayed == null ||
          displayed.taskId != task.taskId ||
          displayed.taskUpdatedAt != task.taskUpdatedAt ||
          displayed.payloadHash != task.payloadHash) {
        throw StateError('任务已变化，请核对后再次操作');
      }
      final token = GlobalUser.instance.token!;
      await _ensureConnected();
      if (!mounted) return;
      await _service.verifyKey(task.vendorKeyId);
      if (!mounted) return;
      if (!task.isOffline) {
        bool geofenceSatisfied = false;
        if (_taskMetadata?['geofenceRequired'] == true) {
          final location = await context
              .read<LocationProvider>()
              .getEventLocation();
          final fence = _taskMetadata?['geofence'];
          if (location != null &&
              fence is Map &&
              fence['latitude'] is num &&
              fence['longitude'] is num &&
              fence['radiusMeters'] is num) {
            final radius = (fence['radiusMeters'] as num).toDouble();
            geofenceSatisfied =
                radius > 0 &&
                Geolocator.distanceBetween(
                          location.lat,
                          location.lng,
                          (fence['latitude'] as num).toDouble(),
                          (fence['longitude'] as num).toDouble(),
                        ) +
                        location.accuracy <=
                    radius;
          }
        }
        for (final vendorId in task.lockIds) {
          final matches = _availableLocks
              .where((lock) => lock.number == vendorId)
              .toList();
          if (matches.length != 1) throw StateError('无法确定锁 $vendorId 的平台 ID');
          final decision = await Api.decideAccess(
            token: token,
            keyId: widget.keyId,
            lockId: matches.single.id,
            at: DateTime.now().toUtc(),
            geofenceSatisfied: geofenceSatisfied,
            clientTraceId:
                'ble_control_${DateTime.now().microsecondsSinceEpoch}_${matches.single.id}',
          );
          if (decision['allowed'] != true ||
              decision['taskId'] != task.taskId) {
            throw StateError(
              '锁 $vendorId 未获当前任务授权：${decision['reasons'] ?? '任务已变化'}',
            );
          }
        }
      }
      final config = await Api.getProvisioningConfig(token: token);
      final time = AccessDecisionTime.resolveKeyLocalTime(config);
      if (time == null) throw StateError('平台未返回钥匙校时时间');
      if (!mounted || !_keyVerified) return;
      await _service.writeTask(
        task,
        time,
        isActive: () => mounted && _keyVerified,
      );
      if (task.isOffline) {
        final receipt = task.receipt(widget.keyId);
        await OfflineDataStore.saveObject(
          'key_receipt_${widget.keyId}',
          receipt,
        );
        if (mounted) setState(() => _receipt = receipt);
        await _service.disconnect();
        _keyVerified = false;
        if (mounted) {
          setState(() => _connectionPhase = _KeyConnectionPhase.idle);
        }
      } else if (mounted) {
        setState(() => _authorized = true);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              task.isOffline ? '离线任务已写入钥匙，可断开手机使用' : '在线授权成功，请保持蓝牙连接后用钥匙碰锁',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败：$error')));
      }
      if (_keyVerified) {
        try {
          await _service.disconnect();
        } catch (_) {}
        _keyVerified = false;
        if (mounted) {
          setState(() => _connectionPhase = _KeyConnectionPhase.idle);
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onSdkEvent(BleKeyEvent event) {
    if (event.operationName == 'DisconnectKey') {
      _wasScanning = false;
      _keyVerified = false;
      if (mounted) {
        setState(() {
          _authorized = false;
          _connectionPhase = _KeyConnectionPhase.idle;
        });
      }
      return;
    }
    final report = event.operationResult;
    if (event.operationName != 'Report' ||
        report?.obj is! Map ||
        !_keyVerified) {
      return;
    }
    if (_readingHistory) _liveReportDuringHistory = true;
    final raw = Map<String, dynamic>.from(report!.obj as Map);
    if (raw['cmd'] != 10 && raw['command'] != 10) return;
    _reportProcessing = _reportProcessing.then((_) async {
      try {
        await _pendingLoaded;
        await _enqueueRecord(raw);
        await _syncPendingEvents();
      } catch (error) {
        if (mounted) setState(() => _historyError = error.toString());
      }
    });
  }

  Future<void> _enqueueRecord(Map<String, dynamic> raw) async {
    final record = BleRecord(raw);
    final lock = _availableLocks
        .where((item) => item.number == record.vendorLockId)
        .firstOrNull;
    final payload = record.payload(
      keyId: widget.keyId,
      vendorKeyId: widget.number,
      deviceId: _selectedMac ?? widget.keyId,
      lockId: lock?.id,
    );
    await _enqueuePendingEvent(payload);
  }

  Future<void> _readHistory() async {
    if (_readingHistory || !_keyVerified) return;
    _readingHistory = true;
    _liveReportDuringHistory = false;
    try {
      await _pendingLoaded;
      final records = await _service.readRecords(
        _bleController!.operationEvents,
      );
      // Preserve non-switch records (e.g. CMD=19); clearRecords erases all records.
      var allSupported = true;
      for (final record in records) {
        if (record['cmd'] != 10 && record['command'] != 10) {
          allSupported = false;
          continue;
        }
        await _enqueueRecord(record);
      }
      await _reportProcessing;
      await _syncPendingEvents();
      final allUploaded = _pendingEvents.every(
        (event) => event[_localSyncStatusKey] == 'uploaded',
      );
      if (mounted &&
          records.isNotEmpty &&
          allSupported &&
          allUploaded &&
          !_liveReportDuringHistory &&
          !_authorized &&
          _keyVerified) {
        await _service.clearRecords();
      }
      if (mounted) {
        setState(() => _historyError = allUploaded ? null : '记录待补传，钥匙记录已保留');
      }
    } catch (error) {
      if (mounted) setState(() => _historyError = '历史记录未完成同步，钥匙记录已保留：$error');
    } finally {
      _readingHistory = false;
    }
  }

  Future<void> _loadPendingEventsAndSync() async {
    final preferences = await SharedPreferences.getInstance();
    final values = preferences.getStringList(_pendingEventsKey) ?? <String>[];
    final pending = <Map<String, dynamic>>[];
    for (final value in values) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) pending.add(Map<String, dynamic>.from(decoded));
      } catch (_) {}
    }
    if (mounted) setState(() => _pendingEvents = pending);
    await _syncPendingEvents();
  }

  Future<void> _startConnectivityMonitoring() async {
    final connectivity = Connectivity();
    _applyConnectivity(await connectivity.checkConnectivity());
    _connectivitySubscription = connectivity.onConnectivityChanged.listen(
      _applyConnectivity,
    );
  }

  Future<void> _refreshConnectivityAndSync() async {
    _applyConnectivity(
      await Connectivity().checkConnectivity(),
      forceSync: true,
    );
  }

  void _applyConnectivity(
    List<ConnectivityResult> results, {
    bool forceSync = false,
  }) {
    final connected = results.any(
      (result) => result != ConnectivityResult.none,
    );
    _hasNetworkConnection = connected;
    if (mounted) setState(() {});
    if (connected && (forceSync || _pendingEvents.isNotEmpty)) {
      _reportProcessing = _reportProcessing.then((_) => _syncPendingEvents());
    }
  }

  Future<void> _enqueuePendingEvent(Map<String, dynamic> payload) async {
    if (_pendingEvents.any(
      (event) => event['vendorEventId'] == payload['vendorEventId'],
    )) {
      return;
    }
    _pendingEvents = <Map<String, dynamic>>[
      ..._pendingEvents,
      <String, dynamic>{...payload, _localSyncStatusKey: 'pending'},
    ];
    await _savePendingEvents();
    if (mounted) setState(() {});
  }

  Future<void> _savePendingEvents() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setStringList(
      _pendingEventsKey,
      _pendingEvents.map(jsonEncode).toList(),
    );
    if (!saved) throw StateError('记录未能保存到本机，保留钥匙记录');
  }

  Future<void> _syncPendingEvents() async {
    final token = GlobalUser.instance.token;
    if (token == null ||
        token.isEmpty ||
        _pendingEvents.isEmpty ||
        _syncingPendingEvents ||
        !_hasNetworkConnection) {
      return;
    }
    _syncingPendingEvents = true;
    try {
      while (true) {
        final index = _pendingEvents.indexWhere(
          (event) => event[_localSyncStatusKey] != 'uploaded',
        );
        if (index < 0) break;
        final payload = BleRecord.normalizePayload(_pendingEvents[index])
          ..remove(_localSyncStatusKey)
          ..remove(_localSyncedAtKey);
        await Api.createLockEvent(token: token, payload: payload);
        final uploaded = <String, dynamic>{
          ...payload,
          _localSyncStatusKey: 'uploaded',
          _localSyncedAtKey: DateTime.now().toUtc().toIso8601String(),
        };
        _pendingEvents = List<Map<String, dynamic>>.from(_pendingEvents)
          ..[index] = uploaded;
        await _savePendingEvents();
        if (mounted) setState(() {});
      }
    } catch (_) {
      // Keep every record and its current state. Opening this page again,
      // receiving another report, or tapping retry resumes pending uploads.
    } finally {
      _syncingPendingEvents = false;
    }
  }

  Map<String, Object?> _baseSdkArgs({String? keyLocalTime}) {
    return <String, Object?>{
      'secret': _secretController.text.trim(),
      'oldSecret': _secretController.text.trim(),
      'sign': int.tryParse(_signController.text.trim()) ?? 1,
      'lic': _licController.text.trim(),
      if (keyLocalTime != null && keyLocalTime.isNotEmpty) 'time': keyLocalTime,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<BleKeyController>();

    return Scaffold(
      appBar: AppBar(title: const Text('钥匙授权与任务')),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _taskMetadata?['name']?.toString() ?? '当前授权任务',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_taskLoading) const LinearProgressIndicator(),
                  if (_taskError != null) Text(_taskError!),
                  if (_task case final task?) ...[
                    Text(
                      task.isOffline
                          ? '离线任务 · 下载后可断开手机使用'
                          : '在线任务 · 操作期间需保持蓝牙连接',
                    ),
                    Text('Task ID: ${task.taskId}'),
                    Text('授权锁：${task.lockIds.join('、')}'),
                    Text(task.scheduleLabel),
                    if (task.isOffline && _receipt != null) ...[
                      Text(
                        task.matchesReceipt(_receipt)
                            ? '已下载 · ${_receipt!['downloadedAt']}'
                            : '需要更新：钥匙中的任务可能已过期',
                      ),
                      const Text('服务端删除任务不会即时撤销钥匙中的离线任务，需重新连接覆盖或等待过期。'),
                    ],
                  ],
                  TextButton.icon(
                    onPressed: _busy || _authorized || _taskLoading
                        ? null
                        : _loadTask,
                    icon: const Icon(Icons.refresh),
                    label: const Text('刷新当前任务'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _KeyConnectionSettingsCard(
            signController: _signController,
            licController: _licController,
            secretController: _secretController,
            enabled:
                !_busy &&
                !_autoConnectInFlight &&
                _connectionPhase != _KeyConnectionPhase.connecting &&
                _connectionPhase != _KeyConnectionPhase.connected,
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
            idleLabel: l10n.keyUnlockReadyToConnect,
            connectLabel: l10n.keyUnlockConnectAction,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy || _authorized || _taskLoading || _task == null
                ? null
                : _authorizeKey,
            icon: Icon(_authorized ? Icons.verified_user : Icons.key),
            label: Text(
              _authorized
                  ? '已授权（持续监听开关锁）'
                  : _task?.isOffline == true
                  ? (_receipt == null
                        ? '下载离线任务'
                        : _task!.matchesReceipt(_receipt)
                        ? '重新下载离线任务'
                        : '更新离线任务')
                  : '在线授权',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
            ),
          ),
          if (_historyError != null) Text(_historyError!),
          if (_keyVerified)
            TextButton(
              onPressed: _busy || _readingHistory ? null : _readHistory,
              child: const Text('补读并同步钥匙记录'),
            ),
          if (_authorized || _pendingEvents.isNotEmpty) ...[
            const SizedBox(height: 12),
            _EventSyncCard(
              authorized: _authorized,
              networkConnected: _hasNetworkConnection,
              pendingEvents: _pendingEvents,
              onRetry: _syncPendingEvents,
            ),
          ],
          if (_busy) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}

class _EventSyncCard extends StatelessWidget {
  const _EventSyncCard({
    required this.authorized,
    required this.networkConnected,
    required this.pendingEvents,
    required this.onRetry,
  });

  final bool authorized;
  final bool networkConnected;
  final List<Map<String, dynamic>> pendingEvents;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleEvents = pendingEvents.reversed.take(5).toList();
    final pendingCount = pendingEvents
        .where(
          (event) =>
              event[_KeyControlScreenState._localSyncStatusKey] != 'uploaded',
        )
        .length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  authorized ? Icons.sensors : Icons.cloud_off,
                  color: authorized
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    authorized ? '授权状态：持续监听中' : '开关锁记录',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  networkConnected ? Icons.cloud_done : Icons.cloud_off,
                  size: 18,
                  color: networkConnected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(networkConnected ? '网络已连接' : '当前离线'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '本地记录 ${pendingEvents.length} 条 · '
              '${pendingCount == 0 ? '全部已上报' : '待上报 $pendingCount 条'}',
            ),
            for (final event in visibleEvents) ...[
              const Divider(height: 16),
              Text(
                '${_eventStateLabel(event)} · ${event['vendorLockId'] ?? '-'} '
                '· ${_syncStateLabel(event)} · ${event['eventTime'] ?? '-'}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (pendingCount > 0) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => unawaited(onRetry()),
                icon: const Icon(Icons.sync),
                label: const Text('立即重试上报'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _eventStateLabel(Map<String, dynamic> event) {
    try {
      final normalized = BleRecord.normalizePayload(event);
      final raw = normalized['rawPayload'];
      final operation = raw is Map ? raw['operation'] : null;
      final label = operation == 'unlock'
          ? '开锁'
          : operation == 'lock'
          ? '关锁'
          : '未知操作';
      return '$label · ${normalized['result'] == 'success' ? '成功' : '失败'}';
    } on FormatException {
      return '记录结果不完整';
    }
  }

  static String _syncStateLabel(Map<String, dynamic> event) {
    return event[_KeyControlScreenState._localSyncStatusKey] == 'uploaded'
        ? '已上报'
        : '待上报';
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

bool _macLabelMatches(String mac, String vendorKeyId) {
  final left = mac.replaceAll(':', '').replaceAll('-', '').toLowerCase();
  final right = vendorKeyId
      .replaceAll(':', '')
      .replaceAll('-', '')
      .toLowerCase();
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
    required this.idleLabel,
    required this.connectLabel,
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
  final String idleLabel;
  final String connectLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = switch (phase) {
      _KeyConnectionPhase.scanning => scanningLabel,
      _KeyConnectionPhase.connecting => connectingLabel,
      _KeyConnectionPhase.connected => connectedLabel,
      _KeyConnectionPhase.failed => failedLabel,
      _ => idleLabel,
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
    final boundKeyMacText =
        connectedMac ?? (boundMac.isNotEmpty ? boundMac : vendorKeyId);

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
                          '$boundKeyMacLabel: $boundKeyMacText',
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
            if (phase == _KeyConnectionPhase.failed ||
                phase == _KeyConnectionPhase.idle) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: busy ? null : onRetry,
                icon: Icon(
                  phase == _KeyConnectionPhase.idle
                      ? Icons.bluetooth
                      : Icons.refresh,
                ),
                label: Text(
                  phase == _KeyConnectionPhase.idle ? connectLabel : retryLabel,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KeyConnectionSettingsCard extends StatelessWidget {
  const _KeyConnectionSettingsCard({
    required this.signController,
    required this.licController,
    required this.secretController,
    required this.enabled,
  });

  final TextEditingController signController;
  final TextEditingController licController;
  final TextEditingController secretController;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ExpansionTile(
        title: Text(l10n.keyAdvancedConnectionSettings),
        subtitle: Text(l10n.keyAdvancedUnlockSettingsHint),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          TextField(
            controller: signController,
            enabled: enabled,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'sign'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: licController,
            enabled: enabled,
            decoration: const InputDecoration(labelText: 'lic'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: secretController,
            enabled: enabled,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'secret'),
          ),
        ],
      ),
    );
  }
}
