import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_blekey_sdk/flutter_blekey_sdk.dart';
import 'package:frontend_demo_blekey/models/current_task_package.dart';
import 'package:frontend_demo_blekey/services/ble_task_service.dart';
import 'package:frontend_demo_blekey/services/ble_record.dart';

Map<String, dynamic> package({bool offline = true}) => {
  'taskId': 'task-1',
  'taskUpdatedAt': '2026-09-29T08:00:00Z',
  'vendorKeyId': '202606050001',
  'mode': offline ? 'offline' : 'online',
  'setUserKey': {
    'lockIds': ['202606050001', '202606050002'],
    'isOnline': !offline,
    'timeBlocks': [
      {
        'from': '2026-09-29',
        'to': '2026-10-29',
        'times': [
          {'from': '08:00:00', 'to': '12:00:00'},
          {'from': '14:00:00', 'to': '18:00:00'},
        ],
      },
    ],
  },
};

void main() {
  test('offline sends all server locks/windows and never SetOnline', () async {
    final calls = <int>[];
    final task = CurrentTaskPackage.fromJson(package());
    final service = BleTaskService(({
      required index,
      required expectedOperationName,
      mac,
      args = const {},
      timeout = const Duration(seconds: 30),
    }) async {
      calls.add(index);
      if (index == 6) expect(args, task.setUserKey);
      if (index == 15) expect(args['time'], '2026-09-29 16:00:00');
      return const BleKeyOperationResult(ret: true, code: 0);
    });
    await service.writeTask(task, '2026-09-29 16:00:00');
    expect(calls, [15, 6]);
  });
  test(
    'online waits for SetUserKey acknowledgement before SetOnline',
    () async {
      final ack = Completer<BleKeyOperationResult>();
      final calls = <int>[];
      final service = BleTaskService(({
        required index,
        required expectedOperationName,
        mac,
        args = const {},
        timeout = const Duration(seconds: 30),
      }) async {
        calls.add(index);
        if (index == 6) return ack.future;
        return const BleKeyOperationResult(ret: true, code: 0);
      });
      final writing = service.writeTask(
        CurrentTaskPackage.fromJson(package(offline: false)),
        '2026-09-29 16:00:00',
      );
      await Future<void>.delayed(Duration.zero);
      expect(calls, [15, 6]);
      ack.complete(const BleKeyOperationResult(ret: true, code: 0));
      await writing;
      expect(calls, [15, 6, 7]);
    },
  );
  for (final failedStep in [15, 6, 7]) {
    test(
      'failure at $failedStep is propagated even with nonnegative code',
      () async {
        final calls = <int>[];
        final service = BleTaskService(({
          required index,
          required expectedOperationName,
          mac,
          args = const {},
          timeout = const Duration(seconds: 30),
        }) async {
          calls.add(index);
          return BleKeyOperationResult(ret: index != failedStep, code: 0);
        });
        await expectLater(
          service.writeTask(
            CurrentTaskPackage.fromJson(package(offline: false)),
            '2026-09-29 16:00:00',
          ),
          throwsStateError,
        );
        expect(calls.last, failedStep);
      },
    );
  }
  test('hardware identity mismatch stops the operation', () async {
    final service = BleTaskService(
      ({
        required index,
        required expectedOperationName,
        mac,
        args = const {},
        timeout = const Duration(seconds: 30),
      }) async => const BleKeyOperationResult(
        ret: true,
        code: 0,
        obj: {'id': 'different-key'},
      ),
    );
    await expectLater(service.verifyKey('202606050001'), throwsStateError);
  });
  test('receipt compares task version and payload, not only task ID', () {
    final task = CurrentTaskPackage.fromJson(package());
    final receipt = task.receipt('key-1');
    expect(task.matchesReceipt(receipt), isTrue);
    final changed = package()..['taskUpdatedAt'] = '2026-09-29T09:00:00Z';
    expect(
      CurrentTaskPackage.fromJson(changed).matchesReceipt(receipt),
      isFalse,
    );
    final payloadChange = package();
    (payloadChange['setUserKey'] as Map)['lockIds'] = ['202606050003'];
    expect(
      CurrentTaskPackage.fromJson(payloadChange).matchesReceipt(receipt),
      isFalse,
    );
  });
  test('payload hash ignores map order and payload getter is defensive', () {
    final task = CurrentTaskPackage.fromJson(package());
    final hash = task.payloadHash;
    (task.setUserKey['lockIds'] as List).clear();
    expect(task.payloadHash, hash);
    final value = package();
    final payload = value['setUserKey'] as Map;
    value['setUserKey'] = {
      'isOnline': payload['isOnline'],
      'timeBlocks': payload['timeBlocks'],
      'lockIds': payload['lockIds'],
    };
    expect(CurrentTaskPackage.fromJson(value).payloadHash, hash);
  });
  for (final mutate in <void Function(Map<String, dynamic>)>[
    (p) => p['mode'] = 'unknown',
    (p) => p['taskUpdatedAt'] = '2026-09-29T08:00:00',
    (p) => (p['setUserKey'] as Map)['isOnline'] = true,
    (p) => (p['setUserKey'] as Map)['lockIds'] = [],
    (p) => (p['setUserKey'] as Map)['timeBlocks'] = [],
    (p) => (p['setUserKey']['timeBlocks'][0] as Map)['times'] = [],
    (p) => (p['setUserKey']['timeBlocks'][0] as Map)['from'] = '2026-02-30',
  ]) {
    test('malformed package fails closed ${mutate.hashCode}', () {
      final value = package();
      mutate(value);
      expect(() => CurrentTaskPackage.fromJson(value), throwsFormatException);
    });
  }
  test('same record from history and live report has identical stable ID', () {
    final raw = {
      'cmd': 10,
      'lockid': '202606050002',
      'time': 1782996573000,
      'status': 1,
    };
    final live = BleRecord(raw);
    final history = BleRecord({...raw, '__class__': 'RecordInfo'});
    expect(live.id('202606050001'), history.id('202606050001'));
    expect(live.id('202606050001'), isNot(live.id('202606050009')));
    expect(
      live.payload(
        keyId: 'key',
        vendorKeyId: '202606050001',
        deviceId: 'mac',
      )['eventTime'],
      endsWith('Z'),
    );
  });
  test('missing hardware timestamp never gets a synthetic current time', () {
    expect(
      () => BleRecord({'cmd': 10, 'lockid': '202606050002', 'status': 1}),
      throwsFormatException,
    );
  });
  test('CMD=19 cannot be uploaded as a lock event', () {
    expect(
      () => BleRecord({
        'cmd': 19,
        'lockid': '202606050002',
        'time': 1782996573000,
        'status': 1,
      }),
      throwsFormatException,
    );
  });
  for (final incomplete in [false, true]) {
    test('history validates page count incomplete=$incomplete', () async {
      final events = StreamController<BleKeyEvent>.broadcast(sync: true);
      final service = BleTaskService(({
        required index,
        required expectedOperationName,
        mac,
        args = const {},
        timeout = const Duration(seconds: 30),
      }) async {
        expect(index, 4);
        expect(args['autoContinue'], true);
        events.add(
          BleKeyEvent(
            type: 'operationResult',
            operationName: 'ReadKeyRecords',
            operationResult: BleKeyOperationResult(
              ret: true,
              code: 0,
              obj: {
                'total': incomplete ? 2 : 1,
                'recordInfos': [
                  {'cmd': 10, 'time': 1234},
                ],
              },
            ),
          ),
        );
        return const BleKeyOperationResult(ret: true, code: 0);
      });
      if (incomplete) {
        await expectLater(service.readRecords(events.stream), throwsStateError);
      } else {
        expect(await service.readRecords(events.stream), hasLength(1));
      }
      await events.close();
    });
  }
  test(
    'leaving the page after clock acknowledgement prevents task write',
    () async {
      var active = true;
      final calls = <int>[];
      final service = BleTaskService(({
        required index,
        required expectedOperationName,
        mac,
        args = const {},
        timeout = const Duration(seconds: 30),
      }) async {
        calls.add(index);
        active = false;
        return const BleKeyOperationResult(ret: true, code: 0);
      });
      await expectLater(
        service.writeTask(
          CurrentTaskPackage.fromJson(package()),
          '2026-09-29 16:00:00',
          isActive: () => active,
        ),
        throwsStateError,
      );
      expect(calls, [15]);
    },
  );
}
