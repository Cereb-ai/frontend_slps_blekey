import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_demo_blekey/services/offline_access_decision.dart';

void main() {
  final at = DateTime(2026, 7, 22, 11);

  Map<String, dynamic> task({
    bool offline = true,
    String status = 'active',
    int required = 0,
    int cleared = 0,
  }) {
    return <String, dynamic>{
      'id': 'task-1',
      'status': status,
      'offlineAccessAllowed': offline,
      'userScope': 'all',
      'keyIds': <String>['key-1'],
      'lockIds': <String>['lock-1'],
      'timeBlock': <String, dynamic>{
        'from': '2026-07-20',
        'to': '2026-07-23',
        'times': <Map<String, String>>[
          <String, String>{'from': '08:00', 'to': '18:00'},
        ],
      },
      'groupMode': required > 0 ? 'group' : 'single',
      'groupRequiredCount': required,
      'groupClearedCount': cleared,
      'createdAt': '2026-07-20T00:00:00Z',
    };
  }

  test('allows a matching server-approved offline task', () {
    final result = decideOfflineAccess(
      tasks: <Map<String, dynamic>>[task()],
      keyId: 'key-1',
      lockId: 'lock-1',
      userId: 'user-1',
      at: at,
    );
    expect(result['allowed'], isTrue);
    expect(result['offline'], isTrue);
    expect(result['taskId'], 'task-1');
  });

  test('demo mode also uses a task without the offline flag', () {
    final result = decideOfflineAccess(
      tasks: <Map<String, dynamic>>[task(offline: false)],
      keyId: 'key-1',
      lockId: 'lock-1',
      userId: 'user-1',
      at: at,
    );
    expect(result['allowed'], isTrue);
  });

  test('rejects outside the cached task time window', () {
    final result = decideOfflineAccess(
      tasks: <Map<String, dynamic>>[task()],
      keyId: 'key-1',
      lockId: 'lock-1',
      userId: 'user-1',
      at: DateTime(2026, 7, 22, 20),
    );
    expect(result['allowed'], isFalse);
  });

  test('rejects an uncleared group lockout task', () {
    final result = decideOfflineAccess(
      tasks: <Map<String, dynamic>>[task(required: 2, cleared: 1)],
      keyId: 'key-1',
      lockId: 'lock-1',
      userId: 'user-1',
      at: at,
    );
    expect(result['allowed'], isFalse);
  });
}
