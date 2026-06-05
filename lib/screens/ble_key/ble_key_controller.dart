import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blekey_sdk/flutter_blekey_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/bluetooth_system_service.dart';

class BleKeyLog {
  const BleKeyLog({
    required this.message,
    required this.time,
    this.isError = false,
  });

  final String message;
  final DateTime time;
  final bool isError;
}

class BleKeyController extends ChangeNotifier {
  static const _permissionDeniedPrefix = 'permission_denied_';

  final FlutterBlekeySdk _sdk = FlutterBlekeySdk();
  final BluetoothSystemService _bluetoothSystemService =
      BluetoothSystemService();

  StreamSubscription<BleKeyEvent>? _eventSubscription;
  bool _initialized = false;
  bool _scanning = false;
  String? _platformVersion;
  Map<String, String?> _sdkVersions = const <String, String?>{};
  final Map<String, BleKeyDevice> _devicesByMac = <String, BleKeyDevice>{};
  final List<BleKeyLog> _logs = <BleKeyLog>[];

  bool get initialized => _initialized;
  bool get scanning => _scanning;
  String? get platformVersion => _platformVersion;
  Map<String, String?> get sdkVersions => Map.unmodifiable(_sdkVersions);
  List<BleKeyDevice> get devices => List.unmodifiable(_devicesByMac.values);
  List<BleKeyLog> get logs => List.unmodifiable(_logs);

  Future<void> preparePermissions() async {
    await _run('权限检查', () async {
      final granted = await _requestBluetoothPermissions();
      if (!granted) return;
      await _ensureBluetoothEnabled();
    });
  }

  Future<void> initialize() async {
    await _run('初始化 SDK', () async {
      final granted = await _requestBluetoothPermissions();
      if (!granted) return;
      final bluetoothReady = await _ensureBluetoothEnabled();
      if (!bluetoothReady) return;
      _eventSubscription ??= _sdk.events.listen(
        _handleEvent,
        onError: (Object error, StackTrace stackTrace) {
          _addLog('事件通道异常：$error', isError: true);
        },
      );
      _platformVersion = await _sdk.getPlatformVersion();
      _initialized = await _sdk.init();
      _sdkVersions = await _sdk.getSdkVersions();
      _addLog('SDK 初始化${_initialized ? '成功' : '失败'}');
    });
  }

  Future<void> startScan({int timeoutMs = 10000}) async {
    await _run('开始扫描', () async {
      final granted = await _requestBluetoothPermissions();
      if (!granted) return;
      final bluetoothReady = await _ensureBluetoothEnabled();
      if (!bluetoothReady) return;
      _devicesByMac.clear();
      _scanning = await _sdk.startScan(timeoutMs: timeoutMs);
      _addLog('扫描已启动，超时 ${timeoutMs}ms');
    });
  }

  Future<void> stopScan() async {
    await _run('停止扫描', () async {
      final stopped = await _sdk.stopScan();
      _scanning = false;
      _addLog(stopped ? '扫描已停止' : '停止扫描失败');
    });
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  Future<void> _run(String action, Future<void> Function() task) async {
    try {
      await task();
    } on PlatformException catch (error) {
      _addLog('$action 失败：${error.message ?? error.code}', isError: true);
    } catch (error) {
      _addLog('$action 失败：$error', isError: true);
    } finally {
      notifyListeners();
    }
  }

  Future<bool> _requestBluetoothPermissions() async {
    final bluetoothPermissions = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ];
    final preferences = await SharedPreferences.getInstance();
    final hadDeniedBluetooth = bluetoothPermissions.any(
      (permission) =>
          preferences.getBool(_permissionDeniedKey(permission)) == true,
    );
    final bluetoothResults = await bluetoothPermissions.request();
    final deniedBluetooth = bluetoothResults.entries
        .where((entry) => !entry.value.isGranted && !entry.value.isLimited)
        .toList(growable: false);

    if (deniedBluetooth.isNotEmpty) {
      final permanentlyDenied = deniedBluetooth.any(
        (entry) => entry.value.isPermanentlyDenied || entry.value.isRestricted,
      );
      final names = deniedBluetooth
          .map((entry) => _permissionLabel(entry.key))
          .join('、');
      _addLog('缺少权限：$names', isError: true);
      await _rememberDeniedPermissions(
        preferences,
        deniedBluetooth.map((entry) => entry.key),
      );
      if (permanentlyDenied || hadDeniedBluetooth) {
        _addLog('权限再次请求失败，已打开应用设置，请手动允许附近设备权限', isError: true);
        await openAppSettings();
      }
      return false;
    }
    await _clearDeniedPermissions(preferences, bluetoothPermissions);

    final hadDeniedLocation =
        preferences.getBool(
          _permissionDeniedKey(Permission.locationWhenInUse),
        ) ==
        true;
    final locationStatus = await Permission.locationWhenInUse.request();
    if (!locationStatus.isGranted && !locationStatus.isLimited) {
      _addLog('定位权限未授权。Android 11 及以下扫描蓝牙通常需要定位权限。', isError: true);
      await _rememberDeniedPermissions(preferences, <Permission>[
        Permission.locationWhenInUse,
      ]);
      if (locationStatus.isPermanentlyDenied ||
          locationStatus.isRestricted ||
          hadDeniedLocation) {
        _addLog('定位权限再次请求失败，已打开应用设置，请手动允许定位权限', isError: true);
        await openAppSettings();
      }
    } else {
      await _clearDeniedPermissions(preferences, <Permission>[
        Permission.locationWhenInUse,
      ]);
    }

    _addLog('蓝牙权限已授权');
    return true;
  }

  Future<void> _rememberDeniedPermissions(
    SharedPreferences preferences,
    Iterable<Permission> permissions,
  ) async {
    for (final permission in permissions) {
      await preferences.setBool(_permissionDeniedKey(permission), true);
    }
  }

  Future<void> _clearDeniedPermissions(
    SharedPreferences preferences,
    Iterable<Permission> permissions,
  ) async {
    for (final permission in permissions) {
      await preferences.remove(_permissionDeniedKey(permission));
    }
  }

  String _permissionDeniedKey(Permission permission) {
    return '$_permissionDeniedPrefix${permission.value}';
  }

  String _permissionLabel(Permission permission) {
    if (permission == Permission.bluetoothScan) return '附近设备-扫描';
    if (permission == Permission.bluetoothConnect) return '附近设备-连接';
    if (permission == Permission.locationWhenInUse) return '定位权限';
    return permission.toString();
  }

  Future<bool> _ensureBluetoothEnabled() async {
    final enabled = await _bluetoothSystemService.isBluetoothEnabled();
    if (enabled) {
      _addLog('蓝牙已开启');
      return true;
    }

    _addLog('蓝牙未开启，已请求系统弹窗');
    await _bluetoothSystemService.requestEnableBluetooth();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final enabledAfterRequest = await _bluetoothSystemService
        .isBluetoothEnabled();
    _addLog(
      enabledAfterRequest ? '蓝牙已开启' : '蓝牙仍未开启，请在系统设置中打开蓝牙',
      isError: !enabledAfterRequest,
    );
    return enabledAfterRequest;
  }

  void _handleEvent(BleKeyEvent event) {
    switch (event.type) {
      case 'scanStarted':
        _scanning = event.success == true;
        _addLog('扫描回调：${event.success == true ? '已开始' : '启动失败'}');
      case 'device':
        final device = event.device;
        if (device != null) {
          _devicesByMac[device.mac ?? device.key ?? device.name ?? 'unknown'] =
              device;
          _addLog('发现设备：${device.name ?? '未命名'} ${device.mac ?? ''}');
        }
      case 'scanFinished':
        _scanning = false;
        for (final device in event.devices) {
          _devicesByMac[device.mac ?? device.key ?? device.name ?? 'unknown'] =
              device;
        }
        _addLog('扫描完成，共 ${_devicesByMac.length} 台设备');
      default:
        _addLog('未知事件：${event.type}');
    }
    notifyListeners();
  }

  void _addLog(String message, {bool isError = false}) {
    _logs.insert(
      0,
      BleKeyLog(message: message, time: DateTime.now(), isError: isError),
    );
    if (_logs.length > 100) {
      _logs.removeRange(100, _logs.length);
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}
