import 'package:flutter/material.dart';

import '../../../api.dart' hide JsonMap;
import '../../../l10n/app_localizations.dart';
import '../../../routes.dart';
import '../../../states/global_user.dart';
import '../../../services/offline_data_store.dart';
import '../../../widgets/smart_list.dart';
import '../models.dart';
import 'key_editor_sheet.dart';

/// Standalone key management list widget.
///
/// Manages its own data fetching, loading state, search filtering, and CRUD.
class KeysList extends StatefulWidget {
  const KeysList({super.key});

  @override
  State<KeysList> createState() => _KeysListState();
}

class _KeysListState extends State<KeysList> {
  final List<KeyItem> _items = <KeyItem>[];
  String _query = '';
  bool _loading = false;

  List<KeyItem> get _filtered {
    if (_query.trim().isEmpty) return _items;
    final query = _query.trim().toLowerCase();
    return _items
        .where(
          (item) =>
              item.name.toLowerCase().contains(query) ||
              item.number.toLowerCase().contains(query),
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
    final cached = await OfflineDataStore.readList('keys');
    if (mounted && cached.isNotEmpty) {
      setState(() {
        _items
          ..clear()
          ..addAll(cached.map(_mapApiKey));
      });
    }
    try {
      final response = await Api.listLockKeys(token: token);
      await OfflineDataStore.saveList('keys', response);
      final mapped = response.map(_mapApiKey).toList();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(mapped);
      });
    } catch (error) {
      if (!mounted) return;
      if (_items.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('钥匙列表加载失败: $error')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit(KeyItem item) async {
    final result = await showKeyEditorSheet(context, initial: item);
    if (result == null) return;
    final token = _requireToken();
    if (token == null) return;
    setState(() => _loading = true);
    try {
      await Api.updateLockKey(
        token: token,
        id: item.id,
        payload: result.updatePayload,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('钥匙已更新')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('钥匙更新失败: ${formatRequestError(error)}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _rename(KeyItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: item.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renameKeyTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.keyWizardKeyName),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.rename),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || name == item.name) return;
    final token = _requireToken();
    if (token == null) return;
    await Api.updateLockKey(
      token: token,
      id: item.id,
      payload: <String, dynamic>{'name': name},
    );
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.renameSuccess)));
    }
  }

  Future<void> _openControl(KeyItem item) async {
    final updated = await Navigator.of(context).pushNamed(
      Routes.keyControl,
      arguments: <String, dynamic>{
        'keyId': item.id,
        'name': item.name,
        'number': item.number,
        'bleMac': item.bleMac,
        'keyType': item.keyType,
        'sign': item.sign,
        'lic': item.lic,
        'secret': item.secret,
      },
    );
    if (updated == true) {
      await _load();
    }
  }

  Future<void> _delete(KeyItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteKeyTitle),
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
      await Api.deleteLockKey(token: token, id: item.id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('钥匙已删除')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('钥匙删除失败: $error')));
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
              hintText: l10n.searchKeyHint,
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
          child: SmartList<KeyItem>(
            key: ValueKey<String>('key-list-$_query'),
            items: _filtered.cast<KeyItem>(),
            loading: _loading,
            onRefresh: _load,
            itemBuilder: (context, item, index) {
              return _KeyCard(
                item: item,
                onTap: () => _openControl(item),
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

  KeyItem _mapApiKey(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString();
    final name = (json['name'] ?? json['vendorKeyId'] ?? id).toString();
    final number = (json['vendorKeyId'] ?? id).toString();
    final metadataRaw = json['metadata'];
    final metadata = metadataRaw is Map
        ? Map<String, dynamic>.from(metadataRaw)
        : const <String, dynamic>{};
    final bleMac = _extractBleMac(metadata);
    final status = (json['status'] ?? 'active').toString();
    final keyType = (json['keyType'] ?? 'standard').toString();
    final ownerUserId = (json['ownerUserId'] ?? json['assignedUserId'] ?? '')
        .toString();
    final updatedAtRaw = json['updatedAt']?.toString();
    final updatedAt = DateTime.tryParse(updatedAtRaw ?? '') ?? DateTime.now();
    return KeyItem(
      id: id.isEmpty ? DateTime.now().microsecondsSinceEpoch.toString() : id,
      name: name,
      number: number,
      bleMac: bleMac,
      keyType: keyType,
      sign: json['sign'] is num
          ? (json['sign'] as num).toInt()
          : int.tryParse(json['sign']?.toString() ?? '') ?? 1,
      lic: (json['lic'] ?? json['license'] ?? 'FFFFFFFFFFFFFFFF').toString(),
      secret: (json['secret'] ?? 'FFFFFFFFFFFFFFFFFFFF').toString(),
      ownerUserId: ownerUserId,
      status: status,
      updatedAt: updatedAt,
    );
  }

  String _extractBleMac(Map<String, dynamic> metadata) {
    final direct = metadata['bleMac']?.toString().trim() ?? '';
    if (direct.isNotEmpty) return direct;

    final readKeyInfo = metadata['readKeyInfo'];
    if (readKeyInfo is Map) {
      final map = Map<String, dynamic>.from(readKeyInfo);
      for (final key in const ['bleMac', 'mac']) {
        final value = map[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
      final obj = map['obj'];
      if (obj is Map) {
        final nested = Map<String, dynamic>.from(obj);
        for (final key in const ['bleMac', 'mac']) {
          final value = nested[key]?.toString().trim() ?? '';
          if (value.isNotEmpty) return value;
        }
      }
    }
    return '';
  }
}

class _KeyCard extends StatelessWidget {
  const _KeyCard({
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onRename,
    required this.onDelete,
  });

  final KeyItem item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
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
              Text('${l10n.keyWizardTypeSummary}: ${item.keyType}'),
              const SizedBox(height: 2),
              Text('${l10n.keyWizardKeyNumberSummary}: ${item.number}'),
              if (item.ownerUserId.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('${l10n.keyWizardOwnerSummary}: ${item.ownerUserId}'),
              ],
              const SizedBox(height: 2),
              Text(
                '${l10n.keyWizardStatusSummary}: ${item.status == 'active' ? l10n.keyStatusActive : item.status}',
              ),
              const SizedBox(height: 2),
              Text('${l10n.listUpdatedAt}: ${formatDate(item.updatedAt)}'),
              const SizedBox(height: 6),
              Text(
                l10n.keyCardTapHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
