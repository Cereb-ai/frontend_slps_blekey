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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(formatRequestError(error))));
    }
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
    return [
      for (var index = 0; index < task.steps.length; index++)
        _StepCard(
          step: task.steps[index],
          isCurrent: index == nextPendingIndex,
          acting: _acting,
          onComplete: () => _completeStep(task.steps[index]),
        ),
    ];
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
