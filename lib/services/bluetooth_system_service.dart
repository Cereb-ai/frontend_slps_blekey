import 'package:flutter/services.dart';

class BluetoothSystemService {
  static const MethodChannel _channel = MethodChannel(
    'frontend_demo_blekey/bluetooth',
  );

  Future<bool> isBluetoothEnabled() async {
    return await _channel.invokeMethod<bool>('isBluetoothEnabled') ?? false;
  }

  Future<bool> requestEnableBluetooth() async {
    return await _channel.invokeMethod<bool>('requestEnableBluetooth') ?? false;
  }

  Future<int?> getAndroidSdkInt() async {
    try {
      return await _channel.invokeMethod<int>('getAndroidSdkInt');
    } on MissingPluginException {
      return null;
    }
  }
}
