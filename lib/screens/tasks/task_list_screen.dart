import 'package:flutter/material.dart';
import '../../api.dart';
import '../../states/global_user.dart';
import '../clearance/clearance_models.dart';
import '../clearance/worker_clearance_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Map<String, dynamic>> _tasks = [];
  String? _error;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = GlobalUser.instance.token;
      if (token == null) throw StateError('请重新登录');
      final tasks = await Api.listAuthorizationTasks(token: token);
      if (mounted) setState(() => _tasks = tasks);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = '任务加载失败：$error';
          _tasks = [];
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) Text(_error!),
        if (!_loading && _tasks.isEmpty) const Text('暂无授权任务'),
        for (final task in _tasks)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(task['name']?.toString() ?? '授权任务'),
              subtitle: Text(
                '${task['status']} · ${task['groupMode'] == 'group' ? '联合授权' : '普通授权'}\n'
                '${task['validFrom']} – ${task['validUntil']}\n'
                '${(task['timeWindows'] as List? ?? []).map((w) => '${w['start']} – ${w['end']}').join(' / ')}',
              ),
              isThreeLine: true,
              onTap: task['groupMode'] != 'group'
                  ? null
                  : () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => WorkerClearanceDetailScreen(
                            task: AuthorizationTaskItem.fromJson(task),
                          ),
                        ),
                      );
                      if (mounted) await _load();
                    },
            ),
          ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('请从钥匙详情进入在线授权或下载离线任务。'),
        ),
      ],
    ),
  );
}
