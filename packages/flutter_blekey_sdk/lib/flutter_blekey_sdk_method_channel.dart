import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_blekey_sdk_platform_interface.dart';

/// An implementation of [FlutterBlekeySdkPlatform] that uses method channels.
class MethodChannelFlutterBlekeySdk extends FlutterBlekeySdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_blekey_sdk');

  @visibleForTesting
  final eventChannel = const EventChannel('flutter_blekey_sdk/events');

  @override
  Future<String?> getPlatformVersion() async {
    return _invokeMethod<String>(
      'getPlatformVersion',
      const <String, Object?>{},
    );
  }

  @override
  Future<bool> init() async {
    return await _invokeMethod<bool>('init', const <String, Object?>{}) ??
        false;
  }

  @override
  Future<Map<String, String?>> getSdkVersions() async {
    debugPrint(
      '[FlutterBlekeySdk][Flutter->Native] method=getSdkVersions args={}',
    );
    try {
      final versions = await methodChannel.invokeMapMethod<String, String?>(
        'getSdkVersions',
      );
      debugPrint(
        '[FlutterBlekeySdk][Native->Flutter] method=getSdkVersions result=$versions',
      );
      return versions ?? const <String, String?>{};
    } catch (error, stackTrace) {
      debugPrint(
        '[FlutterBlekeySdk][Native->Flutter] method=getSdkVersions error=$error stack=$stackTrace',
      );
      rethrow;
    }
  }

  @override
  Future<bool> startScan({int timeoutMs = 10000}) async {
    return await _invokeMethod<bool>('startScan', <String, Object?>{
          'timeoutMs': timeoutMs,
        }) ??
        false;
  }

  @override
  Future<bool> stopScan() async {
    return await _invokeMethod<bool>('stopScan', const <String, Object?>{}) ??
        false;
  }

  @override
  Future<bool> executeOperation({
    required int index,
    String? mac,
    Map<String, Object?> args = const <String, Object?>{},
  }) async {
    return await _invokeMethod<bool>('executeOperation', <String, Object?>{
          'index': index,
          'mac': mac,
          ...args,
        }) ??
        false;
  }

  @override
  Stream<BleKeyEvent> get events {
    return eventChannel.receiveBroadcastStream().map((event) {
      debugPrint('[FlutterBlekeySdk][Event] raw=$event');
      return BleKeyEvent.fromMap(event as Map<dynamic, dynamic>);
    });
  }

  Future<T?> _invokeMethod<T>(String method, Map<String, Object?> args) async {
    debugPrint('[FlutterBlekeySdk][Flutter->Native] method=$method args=$args');
    try {
      final result = await methodChannel.invokeMethod<T>(
        method,
        args.isEmpty ? null : args,
      );
      debugPrint(
        '[FlutterBlekeySdk][Native->Flutter] method=$method result=$result',
      );
      return result;
    } catch (error, stackTrace) {
      debugPrint(
        '[FlutterBlekeySdk][Native->Flutter] method=$method error=$error stack=$stackTrace',
      );
      rethrow;
    }
  }
}
