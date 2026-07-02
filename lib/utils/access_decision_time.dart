abstract final class AccessDecisionTime {
  static const defaultTimezone = 'Asia/Hong_Kong';

  static String resolveTimezone(Map<String, dynamic>? config) {
    final time = config?['time'];
    if (time is Map) {
      final value = time['timezone']?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return defaultTimezone;
  }

  /// RFC3339 `at` for POST /slps/access/decide.
  static String resolveDecisionAt(Map<String, dynamic>? config) {
    final time = config?['time'];
    if (time is Map) {
      final serverUtc = time['serverUtc']?.toString().trim() ?? '';
      if (serverUtc.isNotEmpty) return serverUtc;

      final keyLocalTime = time['keyLocalTime']?.toString().trim() ?? '';
      final offset = time['keyLocalOffset']?.toString().trim() ?? '';
      if (keyLocalTime.isNotEmpty && offset.isNotEmpty) {
        return '${keyLocalTime.replaceFirst(' ', 'T')}$offset';
      }
    }
    return DateTime.now().toUtc().toIso8601String();
  }

  static String? resolveKeyLocalTime(Map<String, dynamic>? config) {
    final time = config?['time'];
    if (time is Map) {
      final value = time['keyLocalTime']?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return null;
  }
}