import 'package:flutter/material.dart';

import '../../services/offline_data_store.dart';

class OfflineTaskCacheScreen extends StatefulWidget {
  const OfflineTaskCacheScreen({super.key});

  @override
  State<OfflineTaskCacheScreen> createState() => _OfflineTaskCacheScreenState();
}

class _OfflineTaskCacheScreenState extends State<OfflineTaskCacheScreen> {
  List<Map<String, dynamic>> _tasks = <Map<String, dynamic>>[];
  DateTime? _lastSyncedAt;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCache();
  }

  Future<void> _loadCache() async {
    final tasks = await OfflineDataStore.readList('tasks');
    tasks.sort((a, b) {
      final aTime = DateTime.tryParse(a['updatedAt']?.toString() ?? '');
      final bTime = DateTime.tryParse(b['updatedAt']?.toString() ?? '');
      return (bTime ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
        aTime ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    });
    final syncedAt = await OfflineDataStore.lastSyncedAt();
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _lastSyncedAt = syncedAt;
      _loading = false;
    });
  }

  Future<void> _sync() async {
    await OfflineDataStore.syncAll();
    await _loadCache();
  }

  @override
  Widget build(BuildContext context) {
    final ordinaryCount = _tasks
        .where((task) => task['groupMode']?.toString() != 'group')
        .length;
    final jointCount = _tasks.length - ordinaryCount;
    return Scaffold(
      appBar: AppBar(
        title: const Text('离线任务缓存'),
        actions: [
          IconButton(
            tooltip: '立即同步',
            onPressed: _sync,
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _sync,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _CacheSummaryCard(
                      total: _tasks.length,
                      ordinary: ordinaryCount,
                      joint: jointCount,
                      lastSyncedAt: _lastSyncedAt,
                    ),
                    const SizedBox(height: 12),
                    if (_tasks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: Text('本机暂无缓存任务')),
                      )
                    else
                      for (final task in _tasks) ...[
                        _CachedTaskCard(task: task),
                        const SizedBox(height: 10),
                      ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _CacheSummaryCard extends StatelessWidget {
  const _CacheSummaryCard({
    required this.total,
    required this.ordinary,
    required this.joint,
    required this.lastSyncedAt,
  });

  final int total;
  final int ordinary;
  final int joint;
  final DateTime? lastSyncedAt;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('本地工作集', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('共 $total 个任务 · 普通 $ordinary · 联签 $joint'),
            const SizedBox(height: 4),
            Text(
              '最后同步：${_formatDateTime(lastSyncedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CachedTaskCard extends StatelessWidget {
  const _CachedTaskCard({required this.task});

  final Map<String, dynamic> task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isJoint = task['groupMode']?.toString() == 'group';
    final status = task['status']?.toString() ?? '-';
    final keyIds = _strings(task['keyIds']);
    final lockIds = _strings(task['lockIds']);
    final block = task['timeBlock'] is Map
        ? Map<String, dynamic>.from(task['timeBlock'] as Map)
        : const <String, dynamic>{};
    final required = _integer(task['groupRequiredCount']);
    final cleared = _integer(task['groupClearedCount']);
    final canUseOffline =
        status == 'active' && keyIds.isNotEmpty && lockIds.isNotEmpty;

    return Card(
      child: ExpansionTile(
        leading: Icon(
          isJoint ? Icons.groups_outlined : Icons.assignment_outlined,
        ),
        title: Text((task['name'] ?? task['id'] ?? '-').toString()),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Tag(label: isJoint ? '联签任务' : '普通任务'),
              _Tag(label: status),
              _Tag(
                label: canUseOffline ? '离线候选' : '当前不可离线授权',
                color: canUseOffline
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          _Detail(label: 'Task ID', value: task['id']?.toString() ?? '-'),
          _Detail(label: '关联钥匙', value: keyIds.join('\n')),
          _Detail(label: '关联锁', value: lockIds.join('\n')),
          _Detail(label: '有效时间', value: _timeBlockLabel(block)),
          if (isJoint) _Detail(label: '联签进度', value: '$cleared / $required'),
          _Detail(
            label: '后端离线标记',
            value: task['offlineAccessAllowed'] == true ? '已开启' : '未开启',
          ),
          _Detail(
            label: '更新时间',
            value: _formatDateTime(
              DateTime.tryParse(task['updatedAt']?.toString() ?? ''),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(color: foreground, fontSize: 12)),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label)),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
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

String _timeBlockLabel(Map<String, dynamic> block) {
  final date = '${block['from'] ?? '-'} ~ ${block['to'] ?? '-'}';
  final times = block['times'];
  if (times is! List || times.isEmpty || times.first is! Map) return date;
  final range = Map<String, dynamic>.from(times.first as Map);
  return '$date\n${range['from'] ?? '-'} ~ ${range['to'] ?? '-'}';
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}
