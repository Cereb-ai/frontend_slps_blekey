import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api.dart';
import '../../states/global_user.dart';
import '../../widgets/smart_list.dart';
import '../clearance/clearance_models.dart';
import '../clearance/worker_clearance_screen.dart';
import '../home/models.dart';
import 'sequential_task_detail_screen.dart';
import 'task_models.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  bool _loading = true;
  String? _error;
  List<AppTaskSummary> _tasks = const <AppTaskSummary>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = GlobalUser.instance.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = '登录已过期';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await Api.listTaskSummaries(token: token);
      final tasks = response.map(AppTaskSummary.fromJson).toList()
        ..sort(
          (a, b) => (b.updatedAt ?? DateTime(1970)).compareTo(
            a.updatedAt ?? DateTime(1970),
          ),
        );
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = formatRequestError(error);
      });
    }
  }

  Future<void> _openTask(AppTaskSummary task) async {
    if (task.type == AppTaskType.sequentialUnlock) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => SequentialTaskDetailScreen(taskId: task.id),
        ),
      );
      await _load();
      return;
    }

    final token = GlobalUser.instance.token;
    if (token == null) return;
    try {
      final response = await Api.listAuthorizationTasks(token: token);
      final matches = response
          .map(AuthorizationTaskItem.fromJson)
          .where((item) => item.id == task.id);
      if (matches.isEmpty || !mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => WorkerClearanceDetailScreen(task: matches.first),
        ),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(formatRequestError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _tasks.isEmpty) {
      return Center(
        child: FilledButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: Text(_error!),
        ),
      );
    }
    return SmartList<AppTaskSummary>(
      items: _tasks,
      loading: _loading,
      emptyText: '暂无任务',
      onRefresh: _load,
      reloadKey: _tasks.length,
      itemBuilder: (context, task, index) =>
          _TaskCard(task: task, onTap: () => _openTask(task)),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.onTap});

  final AppTaskSummary task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSequential = task.type == AppTaskType.sequentialUnlock;
    final color = isSequential ? Colors.orange : Colors.blue;
    final progress = task.total > 0 ? task.completed / task.total : 0.0;
    final schedule = isSequential ? _currentStepSchedule() : null;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isSequential
                        ? Icons.format_list_numbered
                        : Icons.group_work_outlined,
                    color: color,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      task.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isSequential ? '顺序开锁任务' : '联签任务',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (task.total > 0) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress.clamp(0, 1),
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${task.completed}/${task.total}'),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('状态：${_statusLabel(task.status)}'),
                  const Spacer(),
                  if (schedule != null)
                    Text(
                      schedule.$1,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: schedule.$2
                            ? Theme.of(context).colorScheme.error
                            : null,
                        fontWeight: schedule.$2 ? FontWeight.w600 : null,
                      ),
                    )
                  else if (task.updatedAt != null)
                    Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(task.updatedAt!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              if (isSequential &&
                  task.summary['nextLockName']?.toString().isNotEmpty ==
                      true) ...[
                const SizedBox(height: 8),
                Text('下一步：${task.summary['nextLockName']}'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'active' => '待执行',
      'in_progress' => '进行中',
      'completed' => '已完成',
      'cancelled' => '已取消',
      _ => status,
    };
  }

  (String, bool)? _currentStepSchedule() {
    if (task.status == 'completed') return ('任务已完成', false);
    final start = task.summary['nextWindowStart']?.toString() ?? '';
    final end = task.summary['nextWindowEnd']?.toString() ?? '';
    if (start.isEmpty || end.isEmpty) return ('当前步骤：不限时间', false);

    final now = DateTime.now();
    final validFrom = DateTime.tryParse(
      task.summary['validFrom']?.toString() ?? '',
    );
    final date =
        validFrom != null &&
            DateTime(
              now.year,
              now.month,
              now.day,
            ).isBefore(DateTime(validFrom.year, validFrom.month, validFrom.day))
        ? validFrom
        : now;
    final startAt = _combineDateAndTime(date, start);
    final endAt = _combineDateAndTime(date, end);
    if (startAt == null || endAt == null) {
      return ('当前步骤：${start.substring(0, 5)}', false);
    }
    final adjustedEnd = endAt.isBefore(startAt)
        ? endAt.add(const Duration(days: 1))
        : endAt;
    final overdue = now.isAfter(adjustedEnd);
    final prefix = overdue ? '已超时' : '当前步骤开始';
    return ('$prefix：${DateFormat('MM-dd HH:mm').format(startAt)}', overdue);
  }

  DateTime? _combineDateAndTime(DateTime date, String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    final second = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
    if (hour == null || minute == null) return null;
    return DateTime(date.year, date.month, date.day, hour, minute, second);
  }
}
