import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_blekey_sdk_method_channel.dart';

abstract class FlutterBlekeySdkPlatform extends PlatformInterface {
  /// Constructs a FlutterBlekeySdkPlatform.
  FlutterBlekeySdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterBlekeySdkPlatform _instance = MethodChannelFlutterBlekeySdk();

  /// The default instance of [FlutterBlekeySdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterBlekeySdk].
  static FlutterBlekeySdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterBlekeySdkPlatform] when
  /// they register themselves.
  static set instance(FlutterBlekeySdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool> init() {
    throw UnimplementedError('init() has not been implemented.');
  }

  Future<Map<String, String?>> getSdkVersions() {
    throw UnimplementedError('getSdkVersions() has not been implemented.');
  }

  Future<bool> startScan({int timeoutMs = 10000}) {
    throw UnimplementedError('startScan() has not been implemented.');
  }

  Future<bool> stopScan() {
    throw UnimplementedError('stopScan() has not been implemented.');
  }

  Future<bool> executeOperation({
    required int index,
    String? mac,
    Map<String, Object?> args = const <String, Object?>{},
  }) {
    throw UnimplementedError('executeOperation() has not been implemented.');
  }

  Stream<BleKeyEvent> get events {
    throw UnimplementedError('events has not been implemented.');
  }
}

class BleKeyDevice {
  const BleKeyDevice({
    this.name,
    this.mac,
    this.key,
    this.keyId,
    this.scanRecord,
    this.rssi,
    this.timestampNanos,
  });

  final String? name;
  final String? mac;
  final String? key;
  final String? keyId;
  final String? scanRecord;
  final int? rssi;
  final int? timestampNanos;

  factory BleKeyDevice.fromMap(Map<dynamic, dynamic> map) {
    return BleKeyDevice(
      name: map['name'] as String?,
      mac: map['mac'] as String?,
      key: map['key'] as String?,
      keyId: map['keyId'] as String?,
      scanRecord: map['scanRecord'] as String?,
      rssi: map['rssi'] as int?,
      timestampNanos: map['timestampNanos'] as int?,
    );
  }
}

class BleKeyEvent {
  const BleKeyEvent({
    required this.type,
    this.success,
    this.device,
    this.devices = const <BleKeyDevice>[],
    this.operationName,
    this.operationResult,
  });

  final String type;
  final bool? success;
  final BleKeyDevice? device;
  final List<BleKeyDevice> devices;
  final String? operationName;
  final BleKeyOperationResult? operationResult;

  factory BleKeyEvent.fromMap(Map<dynamic, dynamic> map) {
    final devices = map['devices'] as List<dynamic>?;
    return BleKeyEvent(
      type: map['type'] as String,
      success: map['success'] as bool?,
      device: map['device'] == null
          ? null
          : BleKeyDevice.fromMap(map['device'] as Map<dynamic, dynamic>),
      devices: devices == null
          ? const <BleKeyDevice>[]
          : devices
                .cast<Map<dynamic, dynamic>>()
                .map(BleKeyDevice.fromMap)
                .toList(growable: false),
      operationName: map['name'] as String?,
      operationResult: map['result'] == null
          ? null
          : BleKeyOperationResult.fromMap(
              map['result'] as Map<dynamic, dynamic>,
            ),
    );
  }
}

class BleKeyOperationResult {
  const BleKeyOperationResult({
    required this.ret,
    required this.code,
    this.msg,
    this.obj,
    this.objText,
  });

  final bool ret;
  final int code;
  final String? msg;
  final Object? obj;
  final String? objText;

  factory BleKeyOperationResult.fromMap(Map<dynamic, dynamic> map) {
    return BleKeyOperationResult(
      ret: map['ret'] as bool? ?? false,
      code: map['code'] as int? ?? 0,
      msg: map['msg'] as String?,
      obj: map['obj'],
      objText: map['objText'] as String?,
    );
  }
}
