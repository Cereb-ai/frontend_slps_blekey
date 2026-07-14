import 'package:flutter/material.dart';

import '../../../api.dart' hide JsonMap;
import '../../../l10n/app_localizations.dart';
import '../../../states/global_user.dart';
import '../../../widgets/smart_list.dart';
import '../models.dart';
import 'lock_editor_sheet.dart';

/// Standalone lock management list widget.
///
/// Manages its own data fetching, loading state, search filtering, and CRUD.
///
/// Note: online unlock (开锁) has moved onto the key side. Lock cards are now
/// management-only entries; tapping a lock card is no longer wired to a
/// control screen. Use a key card to perform online unlock.
class LocksList extends StatefulWidget {
  const LocksList({super.key});

  @override
  State<LocksList> createState() => _LocksListState();
}

class _LocksListState extends State<LocksList> {
  final List<LockItem> _items = <LockItem>[];
  String _query = '';
  bool _loading = false;

  List<LockItem> get _filtered {
    if (_query.trim().isEmpty) return _items;
    final query = _query.trim().toLowerCase();
    return _items
        .where(
          (item) =>
              item.name.toLowerCase().contains(query) ||
              item.number.toLowerCase().contains(query) ||
              item.location.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = GlobalUser.instance.token;
    if (token == null || token.isEmpty) return;
    setState(() => _loading = true);
    try {
      final response = await Api.listLockDevices(token: token);
      final mapped = response.map(_mapApiLock).toList();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(mapped);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('锁列表加载失败: $error')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit(LockItem item) async {
    final result = await showLockEditorSheet(context, initial: item);
    if (result == null) return;
    final token = _requireToken();
    if (token == null) return;
    setState(() => _loading = true);
    try {
      await Api.updateLockDevice(
        token: token,
        id: item.id,
        payload: result.updatePayload,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('锁已更新')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('锁更新失败: ${formatRequestError(error)}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _rename(LockItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: item.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renameLockTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.lockWizardLockName),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: Text(l10n.rename)),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || name == item.name) return;
    final token = _requireToken();
    if (token == null) return;
    await Api.updateLockDevice(token: token, id: item.id, payload: <String, dynamic>{'name': name});
    await _load();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.renameSuccess)));
  }

  Future<void> _delete(LockItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteLockTitle),
        content: Text(l10n.confirmDeleteItem(item.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final token = _requireToken();
    if (token == null) return;
    try {
      await Api.deleteLockDevice(token: token, id: item.id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('锁已删除')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('锁删除失败: $error')));
    }
  }

  String? _requireToken() {
    final token = GlobalUser.instance.token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.sessionExpired)),
      );
      return null;
    }
    return token;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: l10n.searchLockHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => setState(() => _query = ''),
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
        ),
        Expanded(
          child: SmartList<LockItem>(
            key: ValueKey<String>('lock-list-$_query'),
            items: _filtered.cast<LockItem>(),
            loading: _loading,
            onRefresh: _load,
            itemBuilder: (context, item, index) {
              return _LockCard(
                item: item,
                onEdit: () => _edit(item),
                onRename: () => _rename(item),
                onDelete: () => _delete(item),
              );
            },
          ),
        ),
      ],
    );
  }

  LockItem _mapApiLock(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString();
    final metadataRaw = json['metadata'];
    final metadata = metadataRaw is Map
        ? Map<String, dynamic>.from(metadataRaw)
        : const <String, dynamic>{};

    final name = (json['name'] ?? json['vendorLockId'] ?? id).toString();
    final number = (json['vendorLockId'] ?? id).toString();
    final location =
        (metadata['location'] ??
                metadata['address'] ??
                metadata['siteName'] ??
                '-')
            .toString();

    final switchStateRaw =
        (json['lastState'] ?? metadata['switchState'] ?? 'locked').toString();
    final switchState = switchStateRaw.toLowerCase() == 'unlocked'
        ? 'unlocked'
        : 'locked';

    final updatedAtRaw =
        (json['updatedAt'] ??
                (json['latestEvent'] is Map
                    ? (json['latestEvent'] as Map)['eventTime']
                    : null))
            ?.toString();
    final updatedAt = DateTime.tryParse(updatedAtRaw ?? '') ?? DateTime.now();

    final status = (json['status'] ?? metadata['status'] ?? 'uninstalled')
        .toString();

    return LockItem(
      id: id.isEmpty ? DateTime.now().microsecondsSinceEpoch.toString() : id,
      name: name,
      number: number,
      location: location,
      switchState: switchState,
      status: status,
      updatedAt: updatedAt,
    );
  }
}

class _LockCard extends StatelessWidget {
  const _LockCard({
    required this.item,
    required this.onEdit,
    required this.onRename,
    required this.onDelete,
  });

  final LockItem item;
  final VoidCallback onEdit;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(onPressed: onEdit, child: Text(l10n.edit)),
                TextButton(onPressed: onRename, child: Text(l10n.rename)),
                TextButton(onPressed: onDelete, child: Text(l10n.delete)),
              ],
            ),
            const SizedBox(height: 2),
            Text('${l10n.lockWizardLockNumberSummary}: ${item.number}'),
            const SizedBox(height: 2),
            Text('${l10n.lockWizardLocationSummary}: ${item.location}'),
            const SizedBox(height: 2),
            Text(
              '${l10n.lockWizardSwitchStateSummary}: ${item.switchState == 'locked' ? l10n.lockStateLocked : l10n.lockStateUnlocked}',
            ),
            const SizedBox(height: 2),
            Text('${l10n.listUpdatedAt}: ${formatDate(item.updatedAt)}'),
          ],
        ),
      ),
    );
  }
}
