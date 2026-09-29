/// A stable hardware identity shared by live reports and history reads.
class BleRecord {
  BleRecord(this.raw) {
    if (command != 10 ||
        vendorLockId.isEmpty ||
        milliseconds == null ||
        milliseconds! <= 0 ||
        status == null) {
      throw const FormatException('CMD=10 记录缺少锁号、硬件时间或状态，保留钥匙记录');
    }
  }
  final Map<String, dynamic> raw;
  int? _int(String key) => int.tryParse(raw[key]?.toString() ?? '');
  int? get command => _int('cmd') ?? _int('command');
  int? get milliseconds => _int('time');
  int? get status => _int('status');
  String get vendorLockId => (raw['lockid'] ?? raw['lockId'] ?? '').toString();
  String id(String vendorKeyId) =>
      'ble:$vendorKeyId:$vendorLockId:$milliseconds:10:$status:${raw['flag'] ?? 0}:${raw['flag1'] ?? 0}:${raw['finger'] ?? 0}:${raw['taskid'] ?? ''}';
  Map<String, dynamic> payload({
    required String keyId,
    required String vendorKeyId,
    required String deviceId,
    String? lockId,
  }) => {
    'source': 'android_app',
    'deviceId': deviceId,
    'vendorEventId': id(vendorKeyId),
    'keyId': keyId,
    'lockId': ?lockId,
    'vendorKeyId': vendorKeyId,
    'vendorLockId': vendorLockId,
    'command': 10,
    'status': status,
    'flag': _int('flag'),
    'flag1': _int('flag1'),
    'eventTime': DateTime.fromMillisecondsSinceEpoch(
      milliseconds!,
      isUtc: true,
    ).toIso8601String(),
    'result': status == 0 || status == 1 ? 'success' : 'failed',
    'rawPayload': {
      'report': raw,
      if (status == 0 || status == 1)
        'operation': status == 1 ? 'unlock' : 'lock',
    },
  };
}
