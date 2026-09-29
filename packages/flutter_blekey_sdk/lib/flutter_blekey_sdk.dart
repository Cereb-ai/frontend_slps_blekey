import 'flutter_blekey_sdk_platform_interface.dart';

export 'flutter_blekey_sdk_platform_interface.dart'
    show BleKeyDevice, BleKeyEvent, BleKeyOperationResult;

class FlutterBlekeySdk {
  Future<String?> getPlatformVersion() {
    return FlutterBlekeySdkPlatform.instance.getPlatformVersion();
  }

  Future<bool> init() {
    return FlutterBlekeySdkPlatform.instance.init();
  }

  Future<Map<String, String?>> getSdkVersions() {
    return FlutterBlekeySdkPlatform.instance.getSdkVersions();
  }

  Future<bool> startScan({int timeoutMs = 10000}) {
    return FlutterBlekeySdkPlatform.instance.startScan(timeoutMs: timeoutMs);
  }

  Future<bool> stopScan() {
    return FlutterBlekeySdkPlatform.instance.stopScan();
  }

  Future<bool> executeOperation({
    required int index,
    String? mac,
    Map<String, Object?> args = const <String, Object?>{},
  }) {
    return FlutterBlekeySdkPlatform.instance.executeOperation(
      index: index,
      mac: mac,
      args: args,
    );
  }

  Stream<BleKeyEvent> get events => FlutterBlekeySdkPlatform.instance.events;
}
