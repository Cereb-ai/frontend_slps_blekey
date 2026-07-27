import 'package:flutter/material.dart';

import '../../api.dart';
import '../../states/global_user.dart';
import '../home/models.dart';
import 'task_models.dart';

class SequentialTaskDetailScreen extends StatefulWidget {
  const SequentialTaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<SequentialTaskDetailScreen> createState() =>
      _SequentialTaskDetailScreenState();
}

class _SequentialTaskDetailScreenState
    extends State<SequentialTaskDetailScreen> {
  SequentialTaskDetail? _task;
  String? _error;
  bool _loading = true;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = GlobalUser.instance.token;
    if (token == null) return;
    try {
      final response = await Api.getSequentialUnlockTask(
        token: token,
        taskId: widget.taskId,
      );
      if (!mounted) return;
      setState(() {
        _task = SequentialTaskDetail.fromJson(response);
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = formatRequestError(error);
      });
    }
  }

  Future<void> _completeStep(SequentialTaskStep step) async {
    final operationLabel = step.operation == 'lock' ? '上锁' : '开锁';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认$operationLabel完成'),
        content: Text(
          '请确认已经对“${step.lockName}”完成$operationLabel操作。'
          '服务器将校验任务顺序及时间窗口。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认完成'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final token = GlobalUser.instance.token;
    if (token == null) return;
    setState(() => _acting = true);
    try {
      final response = await Api.completeSequentialUnlockStep(
        token: token,
        taskId: widget.taskId,
        stepId: step.id,
        operation: step.operation,
      );
      if (!mounted) return;
      setState(() {
        _task = SequentialTaskDetail.fromJson(response);
        _acting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('步骤已完成')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _acting = false);
      final message = formatRequestError(error);
      if (message.contains('outside step time window')) {
        await _showTimeWindowError(step);
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _showTimeWindowError(SequentialTaskStep step) async {
    final now = DateTime.now();
    final start = _todayAt(step.windowStart);
    var end = _todayAt(step.windowEnd);
    if (start != null && end != null && end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }
    final hasExpired = end != null && now.isAfter(end);
    final operationLabel = step.operation == 'lock' ? '上锁' : '开锁';
    final title = hasExpired
        ? '当前$operationLabel时间窗口已过'
        : '当前$operationLabel时间窗口尚未开始';
    final description = hasExpired
        ? '该步骤已超过允许的操作时间，请联系管理员调整任务时间或重新创建任务。'
        : '请在允许的时间窗口内再执行该步骤。';

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          hasExpired ? Icons.event_busy_outlined : Icons.schedule_outlined,
          color: hasExpired
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
          size: 36,
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(description, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text('允许操作时间'),
                  const SizedBox(height: 4),
                  Text(
                    '${step.windowStart} - ${step.windowEnd}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  DateTime? _todayAt(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    final second = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
    if (hour == null || minute == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute, second);
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    return Scaffold(
      appBar: AppBar(title: const Text('顺序开锁任务')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : task == null
          ? Center(child: Text(_error ?? '任务不存在'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    task.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text('${task.validFrom} - ${task.validUntil}'),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(task.description),
                  ],
                  const SizedBox(height: 20),
                  ..._buildSteps(task),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildSteps(SequentialTaskDetail task) {
    final nextPendingIndex = task.steps.indexWhere(
      (step) => step.status == 'pending',
    );
    final widgets = <Widget>[];
    for (var index = 0; index < task.steps.length; index++) {
      if (index > 0) widgets.add(const SizedBox(height: 12));
      widgets.add(
        _StepCard(
          step: task.steps[index],
          isCurrent: index == nextPendingIndex,
          acting: _acting,
          onComplete: () => _completeStep(task.steps[index]),
        ),
      );
    }
    return widgets;
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.isCurrent,
    required this.acting,
    required this.onComplete,
  });

  final SequentialTaskStep step;
  final bool isCurrent;
  final bool acting;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final completed = step.status == 'completed';
    final operationLabel = step.operation == 'lock' ? '上锁' : '开锁';
    return Card(
      color: isCurrent
          ? Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.4)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 17,
              child: completed
                  ? const Icon(Icons.check, size: 18)
                  : Text('${step.position}'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.lockName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$operationLabel'
                    '${step.windowStart.isNotEmpty ? ' · ${step.windowStart} - ${step.windowEnd}' : ''}',
                  ),
                  if (isCurrent) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: acting ? null : onComplete,
                      icon: Icon(
                        step.operation == 'lock' ? Icons.lock : Icons.lock_open,
                      ),
                      label: Text('完成$operationLabel'),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              completed
                  ? '已完成'
                  : isCurrent
                  ? '当前步骤'
                  : '等待中',
            ),
          ],
        ),
      ),
    );
  }
}
