import 'dart:convert';
import 'package:crypto/crypto.dart';

/// The server is the only source of the vendor payload. Never synthesize grants.
class CurrentTaskPackage {
  CurrentTaskPackage.fromJson(Map<String, dynamic> json)
    : taskId = _text(json['taskId']),
      taskUpdatedAt = _text(json['taskUpdatedAt']),
      vendorKeyId = _text(json['vendorKeyId']),
      mode = _text(json['mode']),
      _payload = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(json['setUserKey'])) as Map,
      ) {
    if (taskId.isEmpty ||
        vendorKeyId.isEmpty ||
        !RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(taskUpdatedAt) ||
        DateTime.tryParse(taskUpdatedAt) == null ||
        !['online', 'offline'].contains(mode) ||
        _payload['isOnline'] != (mode == 'online')) {
      throw const FormatException('任务包标识、版本或模式无效');
    }
    final ids = _payload['lockIds'];
    final blocks = _payload['timeBlocks'];
    if (ids is! List ||
        ids.isEmpty ||
        ids.any(
          (id) => id is! String || !RegExp(r'^[0-9A-Fa-f]{12}$').hasMatch(id),
        ) ||
        blocks is! List ||
        blocks.isEmpty) {
      throw const FormatException('任务包缺少有效锁号或时间块');
    }
    for (final block in blocks) {
      if (block is! Map ||
          !_date(block['from']) ||
          !_date(block['to']) ||
          (block['from'] as String).compareTo(block['to'] as String) > 0) {
        throw const FormatException('任务日期无效');
      }
      final times = block['times'];
      if (times is! List ||
          times.isEmpty ||
          times.any(
            (time) =>
                time is! Map || !_time(time['from']) || !_time(time['to']),
          )) {
        throw const FormatException('任务每日时间窗无效');
      }
    }
  }

  final String taskId;
  final String taskUpdatedAt;
  final String vendorKeyId;
  final String mode;
  final Map<String, dynamic> _payload;
  bool get isOffline => mode == 'offline';
  List<String> get lockIds => List<String>.from(_payload['lockIds'] as List);
  Map<String, dynamic> get setUserKey =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(_payload)) as Map);
  String get payloadHash =>
      sha256.convert(utf8.encode(jsonEncode(_canonical(_payload)))).toString();
  String get scheduleLabel => (_payload['timeBlocks'] as List)
      .map((block) {
        final windows = (block['times'] as List)
            .map((time) => '${time['from']} – ${time['to']}')
            .join(' / ');
        return '${block['from']} – ${block['to']}\n$windows';
      })
      .join('\n');

  bool matchesReceipt(Map<String, dynamic>? receipt) =>
      receipt != null &&
      receipt['taskId'] == taskId &&
      receipt['taskUpdatedAt'] == taskUpdatedAt &&
      receipt['vendorKeyId'] == vendorKeyId &&
      receipt['payloadHash'] == payloadHash;

  Map<String, dynamic> receipt(String keyId) => {
    'keyId': keyId,
    'vendorKeyId': vendorKeyId,
    'taskId': taskId,
    'taskUpdatedAt': taskUpdatedAt,
    'payloadHash': payloadHash,
    'downloadedAt': DateTime.now().toUtc().toIso8601String(),
  };

  static String _text(Object? value) => value is String ? value : '';
  static bool _date(Object? value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return false;
    }
    final parsed = DateTime.tryParse(value);
    return parsed != null && parsed.toIso8601String().startsWith(value);
  }

  static bool _time(Object? value) =>
      value is String &&
      RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d$').hasMatch(value);
  static Object? _canonical(Object? value) {
    if (value is Map) {
      final keys = value.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: _canonical(value[key])};
    }
    if (value is List) return value.map(_canonical).toList();
    return value;
  }
}
