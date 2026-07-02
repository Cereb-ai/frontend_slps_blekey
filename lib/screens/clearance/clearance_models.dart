typedef JsonMap = Map<String, dynamic>;

class AuthorizationTaskItem {
  const AuthorizationTaskItem({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.groupMode,
    required this.groupRequiredUserIds,
    required this.groupRequiredCount,
    required this.groupClearedCount,
    required this.keyIds,
    required this.lockIds,
    this.groupExpireAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String status;
  final String groupMode;
  final List<String> groupRequiredUserIds;
  final int groupRequiredCount;
  final int groupClearedCount;
  final List<String> keyIds;
  final List<String> lockIds;
  final DateTime? groupExpireAt;
  final DateTime? updatedAt;

  bool get isGroup => groupMode == 'group';

  bool get isFullyCleared =>
      groupRequiredCount > 0 && groupClearedCount >= groupRequiredCount;

  bool involvesUser(String? userId) {
    if (userId == null || userId.isEmpty) return true;
    return groupRequiredUserIds.contains(userId);
  }

  factory AuthorizationTaskItem.fromJson(JsonMap json) {
    return AuthorizationTaskItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '-').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      groupMode: (json['groupMode'] ?? 'single').toString(),
      groupRequiredUserIds: _readStringList(
        json['groupRequiredUserIds'] ?? json['group_required_user_ids'],
      ),
      groupRequiredCount: _readInt(
        json['groupRequiredCount'] ?? json['group_required_count'],
      ),
      groupClearedCount: _readInt(
        json['groupClearedCount'] ?? json['group_cleared_count'],
      ),
      keyIds: _readStringList(json['keyIds'] ?? json['key_ids']),
      lockIds: _readStringList(json['lockIds'] ?? json['lock_ids']),
      groupExpireAt: _readDate(json['groupExpireAt'] ?? json['group_expire_at']),
      updatedAt: _readDate(json['updatedAt'] ?? json['updated_at']),
    );
  }
}

class UserClearanceItem {
  const UserClearanceItem({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.status,
    this.method,
    this.clearedAt,
    this.note,
  });

  final String id;
  final String taskId;
  final String userId;
  final String status;
  final String? method;
  final DateTime? clearedAt;
  final String? note;

  bool get isCleared => status == 'cleared';
  bool get isBlocked => status == 'blocked';
  bool get isPending => status == 'pending' || status.isEmpty;

  factory UserClearanceItem.fromJson(JsonMap json) {
    return UserClearanceItem(
      id: (json['id'] ?? '').toString(),
      taskId: (json['taskId'] ?? json['task_id'] ?? '').toString(),
      userId: (json['userId'] ?? json['user_id'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      method: json['method']?.toString(),
      clearedAt: _readDate(json['clearedAt'] ?? json['cleared_at']),
      note: json['note']?.toString(),
    );
  }
}

List<String> _readStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
  }
  return const <String>[];
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _readDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

bool isGroupLockoutBlockedReason(String reason) {
  final normalized = reason.toLowerCase();
  return normalized.contains('group lockout not cleared') ||
      normalized.contains('group lockout expired');
}

AuthorizationTaskItem? findGroupLockoutTaskForPair({
  required List<AuthorizationTaskItem> tasks,
  required String keyId,
  required String lockId,
}) {
  final matches = tasks
      .where((task) => task.isGroup)
      .where((task) => task.status == 'pending' || task.status == 'active')
      .where((task) => task.keyIds.contains(keyId) && task.lockIds.contains(lockId))
      .toList();
  if (matches.isEmpty) return null;
  matches.sort((a, b) {
    final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  });
  return matches.first;
}