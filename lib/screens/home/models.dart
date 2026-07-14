import 'package:dio/dio.dart';

typedef JsonMap = Map<String, dynamic>;

class KeyItem {
  final String id;
  final String name;
  final String number;
  final String bleMac;
  final String keyType;
  final int sign;
  final String lic;
  final String secret;
  final String ownerUserId;
  final String status;
  final DateTime updatedAt;

  const KeyItem({
    required this.id,
    required this.name,
    required this.number,
    this.bleMac = '',
    required this.keyType,
    this.sign = 1,
    this.lic = 'FFFFFFFFFFFFFFFF',
    this.secret = 'FFFFFFFFFFFFFFFFFFFF',
    required this.ownerUserId,
    required this.status,
    required this.updatedAt,
  });
}

class KeyEditorResult {
  const KeyEditorResult({
    required this.createPayload,
    required this.updatePayload,
  });

  final JsonMap createPayload;
  final JsonMap updatePayload;
}

class LockItem {
  final String id;
  final String name;
  final String number;
  final String location;
  final String switchState;
  final String status;
  final DateTime updatedAt;

  const LockItem({
    required this.id,
    required this.name,
    required this.number,
    required this.location,
    required this.switchState,
    this.status = 'uninstalled',
    required this.updatedAt,
  });
}

class LockEditorResult {
  const LockEditorResult({
    required this.createPayload,
    required this.updatePayload,
  });

  final JsonMap createPayload;
  final JsonMap updatePayload;
}

String formatDate(DateTime value) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} ${two(value.hour)}:${two(value.minute)}';
}

String formatRequestError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final details = _extractErrorDetails(error.response?.data);
    if (status != null && details.isNotEmpty) {
      return 'HTTP $status: $details';
    }
    if (details.isNotEmpty) return details;
    if (status != null) return 'HTTP $status';
    return error.message ?? error.toString();
  }
  return error.toString();
}

String _extractErrorDetails(dynamic data) {
  if (data == null) return '';
  if (data is String) return data;
  if (data is List) {
    final parts = data
        .map((e) => _extractErrorDetails(e))
        .where((e) => e.isNotEmpty);
    return parts.join('; ');
  }
  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    for (final key in const ['message', 'error', 'msg', 'detail']) {
      final text = map[key]?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    final errors = map['errors'] ?? map['details'] ?? map['violations'];
    final nested = _extractErrorDetails(errors);
    if (nested.isNotEmpty) return nested;
    return map.toString();
  }
  return data.toString();
}
