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
  final List<String> _operationResults = <String>[];
  final StreamController<BleKeyEvent> _operationEventController =
      StreamController<BleKeyEvent>.broadcast();

  bool get initialized => _initialized;
  bool get scanning => _scanning;
  String? get platformVersion => _platformVersion;
  Map<String, String?> get sdkVersions => Map.unmodifiable(_sdkVersions);
  List<BleKeyDevice> get devices => List.unmodifiable(_devicesByMac.values);
  List<BleKeyLog> get logs => List.unmodifiable(_logs);
  List<String> get operationResults => List.unmodifiable(_operationResults);
  Stream<BleKeyEvent> get operationEvents => _operationEventController.stream;

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
      final jarVersion = _sdkVersions['jar'];
      final soVersion = _sdkVersions['so'];
      _addLog(
        _initialized
            ? 'Java 库 init 调用成功，jar=${jarVersion ?? '未知'}，so=${soVersion ?? '未知'}'
            : 'Java 库 init 调用失败',
        isError: !_initialized,
      );
    });
  }

  Future<void> ensureReady() async {
    if (_initialized && _eventSubscription != null) return;
    await initialize();
    if (!_initialized) {
      throw StateError('SDK 初始化失败');
    }
  }

  Future<void> startScan({int timeoutMs = 10000}) async {
    await _run('开始扫描', () async {
      await ensureReady();
      final granted = await _requestBluetoothPermissions();
      if (!granted) return;
      final bluetoothReady = await _ensureBluetoothEnabled();
      if (!bluetoothReady) return;
      if (_scanning) {
        await _sdk.stopScan();
        _scanning = false;
      }
      _devicesByMac.clear();
      _scanning = await _sdk.startScan(timeoutMs: timeoutMs);
      _addLog(
        _scanning
            ? 'Java 库 startScan 调用成功，超时 ${timeoutMs}ms'
            : 'Java 库 startScan 调用失败',
        isError: !_scanning,
      );
    });
  }

  Future<void> stopScan() async {
    await _run('停止扫描', () async {
      final stopped = await _sdk.stopScan();
      _scanning = false;
      _addLog(stopped ? '扫描已停止' : '停止扫描失败');
    });
  }

  Future<void> executeVendorOperation({
    required int index,
    String? mac,
    Map<String, Object?> args = const <String, Object?>{},
  }) async {
    await _run('执行厂家命令', () async {
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
      final sent = await _sdk.executeOperation(
        index: index,
        mac: mac,
        args: args,
      );
      _addOperationResult(
        '${_vendorOperationName(index)}：${sent ? '已下发' : '下发失败'}',
      );
    });
  }

  Future<BleKeyOperationResult> executeVendorOperationAndWait({
    required int index,
    required String expectedOperationName,
    String? mac,
    Map<String, Object?> args = const <String, Object?>{},
    Duration timeout = const Duration(seconds: 12),
  }) async {
    await ensureReady();
    final waiting = _operationEventController.stream
        .firstWhere((event) {
          return event.type == 'operationResult' &&
              event.operationName == expectedOperationName &&
              event.operationResult != null;
        })
        .timeout(timeout);
    await executeVendorOperation(index: index, mac: mac, args: args);
    final event = await waiting;
    final result = event.operationResult!;
    if (!(result.ret || result.code >= 0)) {
      throw StateError(
        '${event.operationName} 失败：${result.msg ?? result.code}',
      );
    }
    return result;
  }

  Future<BleKeyOperationResult> waitForOperationResult({
    required String expectedOperationName,
    bool Function(BleKeyOperationResult result)? where,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    await ensureReady();
    final event = await _operationEventController.stream
        .firstWhere((event) {
          final result = event.operationResult;
          if (event.type != 'operationResult' ||
              event.operationName != expectedOperationName ||
              result == null) {
            return false;
          }
          return where?.call(result) ?? true;
        })
        .timeout(timeout);
    return event.operationResult!;
  }

  void clearLogs() {
    _logs.clear();
    _operationResults.clear();
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
    final requiredPermissions = await _requiredAndroidPermissions();
    final preferences = await SharedPreferences.getInstance();
    final hadDeniedAnyPermission = requiredPermissions.any(
      (permission) =>
          preferences.getBool(_permissionDeniedKey(permission)) == true,
    );
    final permissionResults = await requiredPermissions.request();
    final deniedPermissions = permissionResults.entries
        .where((entry) => !entry.value.isGranted && !entry.value.isLimited)
        .toList(growable: false);

    if (deniedPermissions.isNotEmpty) {
      final permanentlyDenied = deniedPermissions.any(
        (entry) => entry.value.isPermanentlyDenied || entry.value.isRestricted,
      );
      final names = deniedPermissions
          .map((entry) => _permissionLabel(entry.key))
          .join('、');
      _addLog('缺少权限：$names', isError: true);
      await _rememberDeniedPermissions(
        preferences,
        deniedPermissions.map((entry) => entry.key),
      );
      if (permanentlyDenied || hadDeniedAnyPermission) {
        _addLog('权限再次请求失败，已打开应用设置，请手动允许蓝牙、WLAN 和定位权限', isError: true);
        await openAppSettings();
      }
      return false;
    }
    await _clearDeniedPermissions(preferences, requiredPermissions);

    _addLog('蓝牙、WLAN 与定位权限已授权');
    return true;
  }

  Future<List<Permission>> _requiredAndroidPermissions() async {
    final sdkInt = await _bluetoothSystemService.getAndroidSdkInt();
    if (sdkInt == null) {
      return <Permission>[];
    }

    return <Permission>[
      if (sdkInt >= 31) ...<Permission>[
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ],
      if (sdkInt >= 33) Permission.nearbyWifiDevices,
      Permission.locationWhenInUse,
    ];
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
    if (permission == Permission.bluetoothAdvertise) return '附近设备-广播';
    if (permission == Permission.nearbyWifiDevices) return 'WLAN 权限';
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
        _addLog(
          event.success == true ? 'Java 库扫描回调：已开始' : 'Java 库扫描回调：启动失败',
          isError: event.success != true,
        );
      case 'device':
        final device = event.device;
        if (device != null) {
          _devicesByMac[device.mac ?? device.key ?? device.name ?? 'unknown'] =
              device;
          _addLog(
            '发现设备：${device.name ?? '未命名'} ${device.mac ?? ''}'
            '${device.keyId == null ? '' : '，keyId=${device.keyId}'}',
          );
        }
      case 'scanFinished':
        _scanning = false;
        for (final device in event.devices) {
          _devicesByMac[device.mac ?? device.key ?? device.name ?? 'unknown'] =
              device;
        }
        _addLog('扫描完成，共 ${_devicesByMac.length} 台设备');
      case 'operationResult':
        final result = event.operationResult;
        _operationEventController.add(event);
        final ok = result?.ret == true || (result?.code ?? -1) >= 0;
        _addOperationResult(
          '${event.operationName ?? 'Operation'}：code=${result?.code ?? '-'}'
          '${result?.msg == null ? '' : '，msg=${result!.msg}'}'
          '${result?.obj == null ? '' : '，obj=${result!.obj}'}',
          isError: !ok,
        );
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

  void _addOperationResult(String message, {bool isError = false}) {
    _operationResults.insert(
      0,
      '${DateTime.now().toIso8601String().substring(11, 19)}  $message',
    );
    _addLog(message, isError: isError);
    if (_operationResults.length > 100) {
      _operationResults.removeRange(100, _operationResults.length);
    }
  }

  String _vendorOperationName(int index) {
    if (index < 0 || index >= vendorOperationNames.length) return '未知命令';
    return vendorOperationNames[index];
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _operationEventController.close();
    super.dispose();
  }
}

const List<String> vendorOperationNames = <String>[
  '连接钥匙蓝牙模块',
  '断开钥匙蓝牙模块',
  '读取钥匙信息',
  '设置钥匙密钥',
  '读取钥匙记录',
  '清除钥匙记录',
  '设置用户钥匙',
  '用户钥匙在线授权',
  '设置采集锁号钥匙',
  '设置初始化钥匙',
  '设置管理钥匙',
  '设置事件钥匙',
  '设置黑名单钥匙',
  '设置空白钥匙',
  '清除黑名单标记',
  '钥匙校时',
  '指纹授权',
  '删除指纹',
  '下载指纹',
  '用户钥匙多人多锁',
  '设置开关锁次数',
  '用户钥匙（多时间块）',
  '采集指纹',
  '下载指纹(任务版)',
  '下载任务(任务版)',
  '删除任务(任务版)',
];
