import 'dart:async';

import 'package:flutter/material.dart';

import '../../api.dart';
import '../../l10n/app_localizations.dart';
import '../../states/global_user.dart';
import '../../services/offline_data_store.dart';
import '../../widgets/smart_list.dart';
import '../home/models.dart';
import 'clearance_models.dart';

class WorkerClearanceScreen extends StatefulWidget {
  const WorkerClearanceScreen({super.key, this.initialTaskId});

  final String? initialTaskId;

  @override
  State<WorkerClearanceScreen> createState() => _WorkerClearanceScreenState();
}

class _WorkerClearanceScreenState extends State<WorkerClearanceScreen> {
  bool _loading = true;
  String? _error;
  List<AuthorizationTaskItem> _tasks = const <AuthorizationTaskItem>[];
  bool _openedInitialTask = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTasks());
  }

  Future<void> _loadTasks() async {
    final token = GlobalUser.instance.token;
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.sessionExpired;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final cached = await OfflineDataStore.readList('tasks');
    if (cached.isNotEmpty) _applyTasks(cached);

    try {
      if (GlobalUser.instance.userId == null) {
        await GlobalUser.instance.fetchProfile();
      }
      final response = await Api.listAuthorizationTasks(token: token);
      await OfflineDataStore.saveList('tasks', response);
      _applyTasks(response);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_tasks.isEmpty) _error = formatRequestError(error);
      });
    }
  }

  void _applyTasks(List<Map<String, dynamic>> response) {
    final userId = GlobalUser.instance.userId;
    final tasks =
        response
            .map(AuthorizationTaskItem.fromJson)
            .where((task) => task.isGroup)
            .where((task) => task.involvesUser(userId))
            .where((task) => task.status != 'rejected')
            .toList()
          ..sort((a, b) {
            final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });

    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _loading = false;
    });
    _maybeOpenInitialTask(tasks);
  }

  void _maybeOpenInitialTask(List<AuthorizationTaskItem> tasks) {
    if (_openedInitialTask || widget.initialTaskId == null) return;
    final match = tasks.where((task) => task.id == widget.initialTaskId);
    if (match.isEmpty) return;
    _openedInitialTask = true;
    _openTaskDetail(match.first);
  }

  Future<void> _openTaskDetail(AuthorizationTaskItem task) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => WorkerClearanceDetailScreen(task: task),
      ),
    );
    await _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_error != null && _tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadTasks,
                child: Text(l10n.clearanceRetry),
              ),
            ],
          ),
        ),
      );
    }

    return SmartList<AuthorizationTaskItem>(
      items: _tasks,
      loading: _loading,
      emptyText: l10n.clearanceEmpty,
      onRefresh: _loadTasks,
      reloadKey: _tasks.length,
      itemBuilder: (context, task, index) {
        final progress = task.groupRequiredCount > 0
            ? task.groupClearedCount / task.groupRequiredCount
            : 0.0;
        final blocked = !task.isFullyCleared;

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openTaskDetail(task),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      _StatusChip(
                        label: _taskStatusLabel(l10n, task),
                        tone: blocked
                            ? _StatusTone.warning
                            : _StatusTone.success,
                      ),
                    ],
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      task.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0, 1),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.clearanceProgress(
                          task.groupClearedCount,
                          task.groupRequiredCount,
                        ),
                      ),
                    ],
                  ),
                  if (blocked) ...[
                    const SizedBox(height: 10),
                    Text(
                      l10n.clearanceUnlockBlocked(
                        task.groupRequiredCount - task.groupClearedCount,
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _taskStatusLabel(AppLocalizations l10n, AuthorizationTaskItem task) {
    if (task.isFullyCleared) return l10n.clearanceReady;
    if (task.status == 'active') return l10n.clearanceActive;
    return l10n.clearancePending;
  }
}

class WorkerClearanceDetailScreen extends StatefulWidget {
  const WorkerClearanceDetailScreen({super.key, required this.task});

  final AuthorizationTaskItem task;

  @override
  State<WorkerClearanceDetailScreen> createState() =>
      _WorkerClearanceDetailScreenState();
}

class _WorkerClearanceDetailScreenState
    extends State<WorkerClearanceDetailScreen> {
  AuthorizationTaskItem? _task;
  List<UserClearanceItem> _clearances = const <UserClearanceItem>[];
  bool _loading = true;
  bool _acting = false;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _loadDetail();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _acting) return;
      _loadDetail(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDetail({bool silent = false}) async {
    final token = GlobalUser.instance.token;
    if (token == null || token.isEmpty) return;

    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final cachedTasks = await OfflineDataStore.readList('tasks');
    final cachedClearances = await OfflineDataStore.readTaskClearances(
      widget.task.id,
    );
    final cachedTask = cachedTasks
        .map(AuthorizationTaskItem.fromJson)
        .where((task) => task.id == widget.task.id)
        .firstOrNull;
    if (mounted && (cachedTask != null || cachedClearances.isNotEmpty)) {
      setState(() {
        if (cachedTask != null) _task = cachedTask;
        if (cachedClearances.isNotEmpty) {
          _clearances = cachedClearances
              .map(UserClearanceItem.fromJson)
              .toList();
        }
        _loading = false;
      });
    }

    try {
      final tasks = await Api.listAuthorizationTasks(token: token);
      final clearances = await Api.listTaskClearances(
        token: token,
        taskId: widget.task.id,
      );
      await OfflineDataStore.saveList('tasks', tasks);
      await OfflineDataStore.saveTaskClearances(widget.task.id, clearances);
      final refreshed = tasks
          .map(AuthorizationTaskItem.fromJson)
          .where((task) => task.id == widget.task.id)
          .firstOrNull;

      if (!mounted) return;
      setState(() {
        if (refreshed != null) _task = refreshed;
        _clearances = clearances.map(UserClearanceItem.fromJson).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_clearances.isEmpty) _error = formatRequestError(error);
      });
    }
  }

  UserClearanceItem? _clearanceForUser(String userId) {
    for (final item in _clearances) {
      if (item.userId == userId) return item;
    }
    return null;
  }

  Future<void> _submitClearance(String action) async {
    final l10n = AppLocalizations.of(context)!;
    final token = GlobalUser.instance.token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sessionExpired)));
      return;
    }

    setState(() => _acting = true);
    try {
      if (action == 'clear') {
        await Api.clearGroupLockoutTask(token: token, taskId: widget.task.id);
      } else {
        await Api.blockGroupLockoutTask(token: token, taskId: widget.task.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'clear'
                ? l10n.clearanceClearedSuccess
                : l10n.clearanceBlockedSuccess,
          ),
        ),
      );
      await _loadDetail(silent: true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(formatRequestError(error))));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final task = _task ?? widget.task;
    final currentUserId = GlobalUser.instance.userId;
    final myClearance = currentUserId == null
        ? null
        : _clearanceForUser(currentUserId);
    final progress = task.groupRequiredCount > 0
        ? task.groupClearedCount / task.groupRequiredCount
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.clearanceDetailTitle)),
      body: _loading && _clearances.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadDetail(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (task.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(task.description),
                          ],
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0, 1),
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.clearanceProgress(
                              task.groupClearedCount,
                              task.groupRequiredCount,
                            ),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          if (!task.isFullyCleared) ...[
                            const SizedBox(height: 8),
                            Text(
                              l10n.clearanceUnlockBlocked(
                                task.groupRequiredCount -
                                    task.groupClearedCount,
                              ),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            Text(
                              l10n.clearanceAllReady,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (task.groupExpireAt != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              l10n.clearanceExpireAt(
                                formatDate(task.groupExpireAt!),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.clearanceWorkerList,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...task.groupRequiredUserIds.map((userId) {
                    final clearance = _clearanceForUser(userId);
                    final isMe = userId == currentUserId;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            userId.isEmpty ? '?' : userId[0].toUpperCase(),
                          ),
                        ),
                        title: Text(isMe ? l10n.clearanceYou(userId) : userId),
                        subtitle: Text(_workerStatusLabel(l10n, clearance)),
                        trailing: _StatusChip(
                          label: _workerStatusLabel(l10n, clearance),
                          tone: _toneForClearance(clearance),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  if (currentUserId != null &&
                      task.groupRequiredUserIds.contains(currentUserId)) ...[
                    FilledButton.icon(
                      onPressed: _acting || myClearance?.isCleared == true
                          ? null
                          : () => _submitClearance('clear'),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(l10n.clearanceClearAction),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(60),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: _acting || myClearance?.isBlocked == true
                          ? null
                          : () => _submitClearance('block'),
                      icon: const Icon(Icons.handyman_outlined),
                      label: Text(l10n.clearanceBlockAction),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(60),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  String _workerStatusLabel(AppLocalizations l10n, UserClearanceItem? item) {
    if (item == null || item.isPending) return l10n.clearanceStatusPending;
    if (item.isCleared) return l10n.clearanceStatusCleared;
    if (item.isBlocked) return l10n.clearanceStatusBlocked;
    return item.status;
  }

  _StatusTone _toneForClearance(UserClearanceItem? item) {
    if (item == null || item.isPending) return _StatusTone.neutral;
    if (item.isCleared) return _StatusTone.success;
    if (item.isBlocked) return _StatusTone.warning;
    return _StatusTone.neutral;
  }
}

enum _StatusTone { success, warning, neutral }

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.tone});

  final String label;
  final _StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color background;
    Color foreground;
    switch (tone) {
      case _StatusTone.success:
        background = scheme.primaryContainer;
        foreground = scheme.onPrimaryContainer;
      case _StatusTone.warning:
        background = scheme.errorContainer;
        foreground = scheme.onErrorContainer;
      case _StatusTone.neutral:
        background = scheme.surfaceContainerHighest;
        foreground = scheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
