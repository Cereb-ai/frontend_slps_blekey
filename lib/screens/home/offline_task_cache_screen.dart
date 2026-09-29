import 'package:flutter/material.dart';
import '../../api.dart';
import '../../models/current_task_package.dart';
import '../../services/offline_data_store.dart';
import '../../states/global_user.dart';
import 'key_control_screen.dart';

/// Read-only receipts; opening a control page always rechecks the server.
class OfflineTaskCacheScreen extends StatefulWidget {
  const OfflineTaskCacheScreen({super.key});
  @override
  State<OfflineTaskCacheScreen> createState() => _OfflineTaskCacheScreenState();
}

class _OfflineTaskCacheScreenState extends State<OfflineTaskCacheScreen> {
  final List<Widget> _cards = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _cards.clear();
    });
    try {
      final token = GlobalUser.instance.token;
      if (token == null) throw StateError('请重新登录');
      final keys = await Api.listLockKeys(token: token);
      for (final key in keys.where((k) => k['keyType'] == 'bluetooth')) {
        final id = key['id'].toString();
        final receipt = await OfflineDataStore.readObject('key_receipt_$id');
        String status;
        CurrentTaskPackage? task;
        try {
          task = CurrentTaskPackage.fromJson(
            await Api.getCurrentTaskPackage(token: token, keyId: id),
          );
          status = !task.isOffline
              ? '在线任务'
              : receipt == null
              ? '尚未下载到钥匙'
              : task.matchesReceipt(receipt)
              ? '已下载'
              : '需要更新：钥匙中的任务可能已过期';
        } catch (_) {
          status = '无法获取当前任务，请进入详情查看；历史回执不代表当前授权';
        }
        if (!mounted) return;
        _cards.add(
          Card(
            child: ListTile(
              title: Text(key['name']?.toString() ?? id),
              subtitle: Text(
                '$status\n${task?.scheduleLabel ?? ''}'
                '${receipt == null ? '' : '\n最近下载：${receipt['downloadedAt']}\nTask ID: ${receipt['taskId']}'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final meta = key['metadata'] is Map
                    ? key['metadata'] as Map
                    : const {};
                await Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => KeyControlScreen.fromArgs({
                      ...key,
                      'keyId': id,
                      'number': key['vendorKeyId'],
                      'bleMac': meta['bleMac'] ?? meta['mac'] ?? '',
                    }),
                  ),
                );
                if (mounted) await _load();
              },
            ),
          ),
        );
      }
    } catch (error) {
      _error = '读取失败：$error';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('钥匙任务与下载回执')),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) Text(_error!),
          if (!_loading && _cards.isEmpty) const Text('暂无蓝牙钥匙'),
          ..._cards,
        ],
      ),
    ),
  );
}
