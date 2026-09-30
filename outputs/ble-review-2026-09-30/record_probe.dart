// ignore_for_file: avoid_relative_lib_imports, avoid_print
import '/Users/zhuang/Documents/cereb/frontend_slps_blekey/lib/services/ble_record.dart';
void main() {
  for (final flag in [0, 4, 48, 67]) {
    for (final status in [0, 1]) {
      final p = BleRecord({'cmd':10,'lockid':'202606050002','time':1782996573000,'status':status,'flag1':flag}).payload(keyId:'key',vendorKeyId:'vendor',deviceId:'probe');
      print('flag1=$flag status=$status => ${p['result']} ${(p['rawPayload'] as Map)['operation']}');
    }
  }
}
