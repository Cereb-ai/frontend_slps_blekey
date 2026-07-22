Map<String, dynamic> decideOfflineAccess({
  required List<Map<String, dynamic>> tasks,
  required String keyId,
  required String lockId,
  required String? userId,
  required DateTime at,
}) {
  final matches =
      tasks.where((task) {
        if (task['status']?.toString() != 'active') {
          return false;
        }
        if (!_strings(task['keyIds']).contains(keyId) ||
            !_strings(task['lockIds']).contains(lockId)) {
          return false;
        }
        final userScope = task['userScope']?.toString() ?? 'all';
        return userScope == 'all' ||
            (userId != null && _strings(task['userIds']).contains(userId));
      }).toList()..sort((a, b) {
        final aTime = DateTime.tryParse(a['createdAt']?.toString() ?? '');
        final bTime = DateTime.tryParse(b['createdAt']?.toString() ?? '');
        return (bTime ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
          aTime ?? DateTime.fromMillisecondsSinceEpoch(0),
        );
      });

  if (matches.isEmpty) {
    return <String, dynamic>{
      'allowed': false,
      'offline': true,
      'reasons': <String>['no cached active authorization task'],
    };
  }

  final task = matches.first;
  final reasons = <String>[];
  if (!_withinTimeBlock(at, task['timeBlock'])) {
    reasons.add('outside cached task time window');
  }
  if (task['groupMode']?.toString() == 'group') {
    final expiresAt = DateTime.tryParse(
      task['groupExpireAt']?.toString() ?? '',
    );
    if (expiresAt != null && at.isAfter(expiresAt)) {
      reasons.add('group lockout expired');
    }
    final required = _integer(task['groupRequiredCount']);
    final cleared = _integer(task['groupClearedCount']);
    if (required > 0 && cleared < required) {
      reasons.add('group lockout not cleared: $cleared/$required');
    }
  }
  return <String, dynamic>{
    'allowed': reasons.isEmpty,
    'offline': true,
    'taskId': task['id']?.toString(),
    'reasons': reasons,
  };
}

bool _withinTimeBlock(DateTime at, Object? value) {
  if (value is! Map) return false;
  final block = Map<String, dynamic>.from(value);
  final from = _date(block['from']);
  final to = _date(block['to']);
  final day = DateTime(at.year, at.month, at.day);
  if (from == null || to == null || day.isBefore(from) || day.isAfter(to)) {
    return false;
  }
  final times = block['times'];
  if (times is! List || times.isEmpty || times.first is! Map) return true;
  final range = Map<String, dynamic>.from(times.first as Map);
  final start = _minuteOfDay(range['from']);
  final end = _minuteOfDay(range['to']);
  if (start == null || end == null) return false;
  final current = at.hour * 60 + at.minute;
  return start <= end
      ? current >= start && current <= end
      : current >= start || current <= end;
}

DateTime? _date(Object? value) {
  final parts = value?.toString().split('-');
  if (parts == null || parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  return year == null || month == null || day == null
      ? null
      : DateTime(year, month, day);
}

int? _minuteOfDay(Object? value) {
  final parts = value?.toString().split(':');
  if (parts == null || parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return hour * 60 + minute;
}

List<String> _strings(Object? value) {
  return value is List
      ? value.map((item) => item.toString()).toList()
      : <String>[];
}

int _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
