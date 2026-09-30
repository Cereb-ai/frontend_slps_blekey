import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_blekey_sdk/flutter_blekey_sdk.dart';
import 'package:frontend_demo_blekey/services/ble_record.dart';
import 'package:frontend_demo_blekey/services/ble_task_service.dart';

Map<String, dynamic> record(int status, int flag1) => {
  'cmd': 10,
  'lockid': '202606050002',
  'time': 1782996573000,
  'status': status,
  'flag1': flag1,
};
Map<String, dynamic> page(int total, int index, int count) => {
  'total': total,
  'index': index,
  'recordInfos': List.generate(count, (i) => record(i % 2, 0)),
};
Future<List<Map<String, dynamic>>> readPages(
  List<Map<String, dynamic>> pages,
) async {
  final events = StreamController<BleKeyEvent>.broadcast();
  final service = BleTaskService(({
    required index,
    required expectedOperationName,
    mac,
    args = const {},
    timeout = const Duration(seconds: 30),
  }) async {
    expect(index, 4);
    expect(args, {'clearAfterRead': false});
    for (final page in pages) {
      events.add(
        BleKeyEvent(
          type: 'operationResult',
          operationName: 'ReadKeyRecords',
          operationResult: BleKeyOperationResult(ret: true, code: 0, obj: page),
        ),
      );
    }
    await Future<void>.delayed(Duration.zero);
    return const BleKeyOperationResult(ret: true, code: 0);
  });
  try {
    return await service.readRecords(events.stream);
  } finally {
    await events.close();
  }
}

void main() {
  for (final flag in [0, 1, 2, 4, 48, 67, 255]) {
    for (final status in [0, 1]) {
      test('vendor outcome flag1=$flag status=$status', () {
        final payload = BleRecord(
          record(status, flag),
        ).payload(keyId: 'key', vendorKeyId: 'vendor', deviceId: 'mac');
        final success = flag <= 2;
        expect(payload['result'], success ? 'success' : 'failed');
        expect(
          (payload['rawPayload'] as Map)['operation'],
          (success ? status == 0 : status == 1) ? 'unlock' : 'lock',
        );
      });
    }
  }
  test('old pending payload is corrected without changing event identity', () {
    final legacy = <String, dynamic>{
      'vendorEventId': 'stable-id',
      'result': 'success',
      'syncStatus': 'pending',
      'rawPayload': {'report': record(1, 48), 'operation': 'lock'},
    };
    final corrected = BleRecord.normalizePayload(legacy);
    expect(corrected['result'], 'failed');
    expect((corrected['rawPayload'] as Map)['operation'], 'unlock');
    expect(corrected['vendorEventId'], 'stable-id');
    expect(legacy['result'], 'success');
    expect((legacy['rawPayload'] as Map)['operation'], 'lock');
  });
  test('legacy payload without report is copied without guessing', () {
    final legacy = <String, dynamic>{
      'result': 'failed',
      'syncStatus': 'pending',
    };
    final copied = BleRecord.normalizePayload(legacy)..remove('syncStatus');
    expect(copied['result'], 'failed');
    expect(legacy['syncStatus'], 'pending');
  });
  test('missing or invalid outcome cannot become successful', () {
    for (final value in [null, -1, 256, 'bad']) {
      expect(
        () => BleRecord({...record(0, 0), 'flag1': value}),
        throwsFormatException,
      );
    }
  });
  for (final start in [0, 1]) {
    test('multiple records per page with index base $start', () async {
      expect(
        await readPages([page(2, start, 3), page(2, start + 1, 2)]),
        hasLength(5),
      );
    });
  }
  test('empty read completes without deleting anything', () async {
    expect(await readPages([]), isEmpty);
    expect(await readPages([page(0, 0, 0)]), isEmpty);
  });
  for (final entry in <String, List<Map<String, dynamic>>>{
    'missing page': [page(2, 1, 2)],
    'duplicate page': [page(2, 1, 2), page(2, 1, 2)],
    'gap': [page(2, 0, 2), page(2, 2, 2)],
    'changed total': [page(2, 1, 2), page(3, 2, 2)],
    'missing index': [
      {
        'total': 1,
        'recordInfos': [record(0, 0)],
      },
    ],
    'zero total with records': [page(0, 0, 1)],
  }.entries) {
    test('reject ${entry.key}', () async {
      await expectLater(readPages(entry.value), throwsStateError);
    });
  }
}
