/// A stable hardware identity shared by live reports and history reads.
class BleRecord {
  BleRecord(this.raw) {
    if (command != 10 ||
        vendorLockId.isEmpty ||
        milliseconds == null ||
        milliseconds! <= 0 ||
        status == null ||
        flag1 == null ||
        flag1! < 0 ||
        flag1! > 255) {
      throw const FormatException('CMD=10 记录缺少锁号、硬件时间或有效结果，保留钥匙记录');
    }
  }
  final Map<String, dynamic> raw;
  int? _int(String key) => int.tryParse(raw[key]?.toString() ?? '');
  int? get command => _int('cmd') ?? _int('command');
  int? get milliseconds => _int('time');
  int? get status => _int('status');
  int? get flag1 => _int('flag1');
  bool get succeeded => flag1! <= 2;
  String? get operation {
    if (status != 0 && status != 1) return null;
    return (succeeded ? status == 0 : status == 1) ? 'unlock' : 'lock';
  }

  /// Recompute old pending payloads from hardware data without changing identity.
  static Map<String, dynamic> normalizePayload(Map<String, dynamic> payload) {
    final raw = payload['rawPayload'];
    if (raw is! Map || raw['report'] is! Map) {
      return Map<String, dynamic>.from(payload);
    }
    final record = BleRecord(Map<String, dynamic>.from(raw['report'] as Map));
    final normalizedRaw = Map<String, dynamic>.from(raw)..remove('operation');
    if (record.operation != null) normalizedRaw['operation'] = record.operation;
    return {
      ...payload,
      'result': record.succeeded ? 'success' : 'failed',
      'rawPayload': normalizedRaw,
    };
  }

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
    'result': succeeded ? 'success' : 'failed',
    'rawPayload': {
      'report': raw,
      if (operation != null) 'operation': operation,
    },
  };
}
