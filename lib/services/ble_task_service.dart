import 'dart:async';
import 'package:flutter_blekey_sdk/flutter_blekey_sdk.dart';
import '../models/current_task_package.dart';

typedef RunBleOperation =
    Future<BleKeyOperationResult> Function({
      required int index,
      required String expectedOperationName,
      String? mac,
      Map<String, Object?> args,
      Duration timeout,
    });

/// Every step completes only after the corresponding device acknowledgement.
class BleTaskService {
  BleTaskService(this.run);
  final RunBleOperation run;

  Future<BleKeyOperationResult> _execute(
    int index,
    String name, {
    String? mac,
    Map<String, Object?> args = const {},
  }) async {
    final result = await run(
      index: index,
      expectedOperationName: name,
      mac: mac,
      args: args,
      timeout: const Duration(seconds: 30),
    );
    if (!result.ret) throw StateError('$name 失败：${result.msg ?? result.code}');
    return result;
  }

  Future<void> verifyKey(String vendorKeyId) async {
    final result = await _execute(2, 'ReadKeyInfo');
    final obj = result.obj;
    final data = obj is Map && obj['data'] is Map ? obj['data'] as Map : obj;
    final id = data is Map ? (data['id'] ?? data['keyId'])?.toString() : null;
    if (id != vendorKeyId) throw StateError('实体钥匙与当前任务不一致，已停止写入');
  }

  Future<void> writeTask(
    CurrentTaskPackage task,
    String keyLocalTime, {
    bool Function()? isActive,
  }) async {
    if (keyLocalTime.isEmpty) throw StateError('平台未提供校时时间');
    void requireActive() {
      if (isActive != null && !isActive()) throw StateError('蓝牙连接或页面已关闭');
    }

    requireActive();
    await _execute(15, 'SetDateTime', args: {'time': keyLocalTime});
    requireActive();
    await _execute(6, 'SetUserKey', args: task.setUserKey);
    if (!task.isOffline) {
      requireActive();
      await _execute(7, 'SetOnline');
    }
  }

  Future<void> disconnect() => _execute(1, 'DisconnectKey');
  Future<void> clearRecords() => _execute(5, 'ClearRecords');

  Future<List<Map<String, dynamic>>> readRecords(
    Stream<BleKeyEvent> events,
  ) async {
    final records = <Map<String, dynamic>>[];
    Object? pageError;
    int? expectedTotal;
    final pageIndexes = <int>{};
    final sub = events.listen((event) {
      if (event.operationName != 'ReadKeyRecords') return;
      final result = event.operationResult;
      final obj = result?.obj;
      if (result?.ret != true || obj is! Map || obj['recordInfos'] is! List) {
        pageError = StateError('历史记录读取失败或格式不完整');
        return;
      }
      final total = obj['total'];
      if (total is! int ||
          total < 0 ||
          (expectedTotal != null && expectedTotal != total)) {
        pageError = StateError('历史记录总数不明确或读取期间发生变化');
      } else {
        expectedTotal = total;
      }
      final index = obj['index'];
      if (index is! int || index < 0 || !pageIndexes.add(index)) {
        pageError = StateError('历史记录分页缺失或重复');
      }
      for (final record in obj['recordInfos'] as List) {
        if (record is! Map) {
          pageError = StateError('历史记录格式无效');
        } else {
          records.add(Map<String, dynamic>.from(record));
        }
      }
    });
    try {
      await _execute(
        4,
        'ReadKeyRecordsComplete',
        args: {'clearAfterRead': false},
      );
      if (pageError != null) throw pageError!;
      if (expectedTotal != null) {
        final indexes = pageIndexes.toList()..sort();
        final total = expectedTotal!;
        // Firmware may number packets from zero or one; require a complete,
        // contiguous set. total counts packets, not individual records.
        final complete = total == 0
            ? records.isEmpty && indexes.length == 1 && indexes.first == 0
            : indexes.length == total &&
                  (indexes.first == 0 || indexes.first == 1) &&
                  indexes.last == indexes.first + total - 1;
        if (!complete) {
          throw StateError('历史记录不完整，禁止清除钥匙记录');
        }
      }
      return records;
    } finally {
      await sub.cancel();
    }
  }
}
