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
import '../../services/offline_access_decision.dart';
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

  bool _busy = false;
  bool _locksLoading = false;
  String? _selectedMac;
  LockItem? _selectedLock;
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
      unawaited(_loadPendingEventsAndSync());
      _loadLocks();
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
      _completeConnectionAttempt();
    } catch (error) {
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
      await completer.future.timeout(const Duration(seconds: 35));
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
    final cached = (await OfflineDataStore.readList(
      'locks',
    )).map(_mapApiLock).toList();
    if (mounted && cached.isNotEmpty) {
      setState(() => _availableLocks = cached);
    }
    try {
      final response = await Api.listLockDevices(token: token);
      final mapped = response.map(_mapApiLock).toList();
      await OfflineDataStore.saveList('locks', response);
      if (!mounted) return;
      setState(() {
        _availableLocks = mapped;
        _locksLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _locksLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cached.isEmpty ? '锁列表加载失败: $error' : '网络不可用，已加载本地缓存的锁列表',
          ),
        ),
      );
    }
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
    final l10n = AppLocalizations.of(context)!;
    if (_busy) return;

    if (_selectedLock == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.keyUnlockNoLockSelected)));
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
    final controller = context.read<BleKeyController>();
    setState(() => _busy = true);
    try {
      // A single tap now performs scan + connection when needed, then carries
      // on with authorization and control. Connection failures are surfaced by
      // the common error handler below.
      await _ensureConnected();

      // 1) Resolve authorization for the currently selected lock. The app
      // deliberately does not send a task id; the backend selects the active
      // task for this key/lock pair.
      final provisioningConfig = await _getProvisioningConfigSafely(
        token: token,
      );
      final decisionAt = AccessDecisionTime.resolveDecisionAt(
        provisioningConfig,
      );
      final decision = await _decideAccess(
        token: token,
        lock: lock,
        decisionAt: DateTime.parse(decisionAt),
      );
      if (decision['allowed'] != true) {
        final reasons = decision['reasons'];
        final reasonText = reasons is List
            ? reasons.map((item) => item.toString()).join(', ')
            : reasons?.toString() ?? l10n.keyUnlockAuthDenied;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.keyUnlockAuthDenied}: $reasonText')),
        );
        return;
      }

      // 2) SetDateTime (use platform timezone from provisioning config)
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
      // 3) SetUserKey with target lockId
      await controller.executeVendorOperationAndWait(
        index: 6,
        expectedOperationName: 'SetUserKey',
        mac: _selectedMac,
        args: _sdkArgs(),
        timeout: const Duration(seconds: 20),
      );
      // 4) SetOnline
      await controller.executeVendorOperationAndWait(
        index: 7,
        expectedOperationName: 'SetOnline',
        mac: _selectedMac,
        args: _sdkArgs(),
        timeout: const Duration(seconds: 20),
      );

      if (!mounted) return;
      setState(() => _authorized = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            decision['offline'] == true
                ? '离线授权成功，记录已本地缓存，联网后自动上报。'
                : '授权成功，现在可持续开关锁，所有记录都会自动上报。',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.keyUnlockFailed}: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Map<String, dynamic>> _decideAccess({
    required String token,
    required LockItem lock,
    required DateTime decisionAt,
  }) async {
    try {
      return await Api.decideAccess(
        token: token,
        keyId: widget.keyId,
        lockId: lock.id,
        at: decisionAt,
        geofenceSatisfied: true,
        clientTraceId:
            'ble_control_${DateTime.now().millisecondsSinceEpoch}_${lock.id}',
      );
    } on DioException catch (error) {
      if (error.response != null) rethrow;
      return decideOfflineAccess(
        tasks: await OfflineDataStore.readList('tasks'),
        keyId: widget.keyId,
        lockId: lock.id,
        userId: GlobalUser.instance.userId,
        at: decisionAt.toLocal(),
      );
    }
  }

  void _onSdkEvent(BleKeyEvent event) {
    final report = event.operationResult;
    if (event.type != 'operationResult' ||
        event.operationName != 'Report' ||
        report == null ||
        !_isCmd10SwitchReport(report) ||
        _selectedLock == null) {
      return;
    }
    _reportProcessing = _reportProcessing.then(
      (_) => _handleSwitchReportSafely(report),
    );
  }

  Future<void> _handleSwitchReportSafely(BleKeyOperationResult report) async {
    try {
      await _handleSwitchReport(report);
    } catch (error, stackTrace) {
      debugPrint('开关锁记录处理失败: $error\n$stackTrace');
    }
  }

  Future<void> _handleSwitchReport(BleKeyOperationResult report) async {
    if (!mounted) return;
    final lock = _selectedLock;
    if (lock == null) return;
    final reportStatus = _extractReportStatus(report.obj);
    if (reportStatus == null) return;
    final nextState = reportStatus == 1 ? 'unlocked' : 'locked';
    final operationLocation =
        (await context.read<LocationProvider>().getEventLocation())
            ?.toRawPayload();
    final payload = _buildSwitchEventPayload(
      lock: lock,
      requestedState: nextState,
      report: report,
      operationLocation: operationLocation,
    );
    await _enqueuePendingEvent(payload);
    await _syncPendingEvents();
    if (!mounted) return;
    setState(() {
      final updatedLock = LockItem(
        id: lock.id,
        name: lock.name,
        number: lock.number,
        location: lock.location,
        switchState: nextState,
        status: lock.status,
        updatedAt: DateTime.now(),
      );
      _selectedLock = updatedLock;
      _availableLocks = _availableLocks
          .map((item) => item.id == lock.id ? updatedLock : item)
          .toList();
    });
  }

  int? _extractReportStatus(Object? value) {
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final direct = _toInt(map['status']) ?? _toInt(map['flag']);
      if (direct != null) return direct == 0 ? 0 : 1;
      for (final nested in map.values) {
        final status = _extractReportStatus(nested);
        if (status != null) return status;
      }
    }
    return null;
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
    _pendingEvents = <Map<String, dynamic>>[..._pendingEvents, payload];
    await _savePendingEvents();
    if (mounted) setState(() {});
  }

  Future<void> _savePendingEvents() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _pendingEventsKey,
      _pendingEvents.map(jsonEncode).toList(),
    );
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
      while (_pendingEvents.isNotEmpty) {
        await Api.createLockEvent(token: token, payload: _pendingEvents.first);
        _pendingEvents = _pendingEvents.sublist(1);
        await _savePendingEvents();
        if (mounted) setState(() {});
      }
    } catch (_) {
      // Keep the remaining records. Opening this page again, receiving another
      // report, or tapping retry will resume from the first unsent record.
    } finally {
      _syncingPendingEvents = false;
    }
  }

  Map<String, dynamic> _buildSwitchEventPayload({
    required LockItem lock,
    required String requestedState,
    required BleKeyOperationResult report,
    Map<String, dynamic>? operationLocation,
  }) {
    final reportTime = _extractReportTime(report.obj);
    final eventTime = (reportTime ?? DateTime.now()).toUtc().toIso8601String();
    final command = _extractCommand(report.obj) ?? 10;
    return <String, dynamic>{
      'source': 'flutter_app_ble_key',
      'deviceId': _selectedMac ?? widget.keyId,
      'vendorEventId':
          'ble_${reportTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}_${lock.number}_$requestedState',
      'lockId': lock.id,
      'keyId': widget.keyId,
      'vendorLockId': lock.number,
      'vendorKeyId': widget.number,
      'command': command,
      'status': requestedState == 'unlocked' ? 1 : 0,
      'eventTime': eventTime,
      'result': 'success',
      'rawPayload': <String, dynamic>{
        ...?operationLocation,
        'flow': 'app_key_control',
        'requestedState': requestedState,
        'previousDisplayState': lock.switchState,
        'control': <String, dynamic>{
          'controlMac': _selectedMac,
          'controlChannel': 'flutter_blekey_sdk',
          'controlledAt': DateTime.now().toIso8601String(),
          'controlledByKeyId': widget.keyId,
        },
        'report': <String, dynamic>{
          'code': report.code,
          'ret': report.ret,
          if (report.msg != null) 'msg': report.msg,
          if (report.obj != null) 'obj': report.obj,
          if (report.objText != null) 'objText': report.objText,
        },
      },
    };
  }

  DateTime? _extractReportTime(Object? value) {
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final milliseconds = _toInt(map['time']);
      if (milliseconds != null && milliseconds > 0) {
        return DateTime.fromMillisecondsSinceEpoch(milliseconds);
      }
      for (final nested in map.values) {
        final time = _extractReportTime(nested);
        if (time != null) return time;
      }
    }
    return null;
  }

  Map<String, Object?> _baseSdkArgs({String? keyLocalTime}) {
    return <String, Object?>{
      'secret': _secretController.text.trim(),
      'oldSecret': _secretController.text.trim(),
      'sign': int.tryParse(_signController.text.trim()) ?? 1,
      'lic': _licController.text.trim(),
      'lockIds': _selectedLock?.number ?? '',
      if (keyLocalTime != null && keyLocalTime.isNotEmpty) 'time': keyLocalTime,
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
      return OfflineDataStore.readObject('provisioning_config');
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
            onSelect: _busy || _authorized
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
            onPressed: _busy || _authorized ? null : _authorizeKey,
            icon: Icon(_authorized ? Icons.verified_user : Icons.key),
            label: Text(_authorized ? '已授权（持续监听开关锁）' : '授权'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
            ),
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
              pendingEvents.isEmpty
                  ? '所有开关锁记录已上报'
                  : '待上报 ${pendingEvents.length} 条（网络恢复后自动补传）',
            ),
            for (final event in visibleEvents) ...[
              const Divider(height: 16),
              Text(
                '${_eventStateLabel(event)} · ${event['vendorLockId'] ?? '-'} · ${event['eventTime'] ?? '-'}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (pendingEvents.isNotEmpty) ...[
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
    return event['status'] == 1 ? '开锁' : '关锁';
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
