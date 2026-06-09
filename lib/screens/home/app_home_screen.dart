import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api.dart';
import '../../routes.dart';
import '../../states/global_user.dart';

class AppHomeScreen extends StatefulWidget {
  const AppHomeScreen({super.key});

  @override
  State<AppHomeScreen> createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends State<AppHomeScreen> {
  int _tabIndex = 0;
  String _query = '';
  bool _keyLoading = false;
  bool _lockLoading = false;

  final List<_KeyItem> _keys = <_KeyItem>[];
  final List<_LockItem> _locks = <_LockItem>[];

  @override
  void initState() {
    super.initState();
    _loadKeysFromApi();
    _loadLocksFromApi();
  }

  List<_KeyItem> get _filteredKeys {
    if (_query.trim().isEmpty) return _keys;
    final query = _query.trim().toLowerCase();
    return _keys
        .where(
          (item) =>
              item.name.toLowerCase().contains(query) ||
              item.number.toLowerCase().contains(query),
        )
        .toList();
  }

  List<_LockItem> get _filteredLocks {
    if (_query.trim().isEmpty) return _locks;
    final query = _query.trim().toLowerCase();
    return _locks
        .where(
          (item) =>
              item.name.toLowerCase().contains(query) ||
              item.number.toLowerCase().contains(query) ||
              item.location.toLowerCase().contains(query),
        )
        .toList();
  }

  String get _title {
    if (_tabIndex == 0) return '钥匙管理';
    if (_tabIndex == 1) return '锁管理';
    return '我的';
  }

  bool get _showAdd => _tabIndex == 0 || _tabIndex == 1;

  Future<void> _loadKeysFromApi() async {
    final token = GlobalUser.instance.token;
    if (token == null || token.isEmpty) return;
    setState(() => _keyLoading = true);
    try {
      final response = await Api.listLockKeys(token: token);
      final mapped = response.map(_mapApiKey).toList();
      if (!mounted) return;
      setState(() {
        _keys
          ..clear()
          ..addAll(mapped);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('钥匙列表加载失败: $error')));
    } finally {
      if (mounted) setState(() => _keyLoading = false);
    }
  }

  Future<void> _loadLocksFromApi() async {
    final token = GlobalUser.instance.token;
    if (token == null || token.isEmpty) return;
    setState(() => _lockLoading = true);
    try {
      final response = await Api.listLockDevices(token: token);
      final mapped = response.map(_mapApiLock).toList();
      if (!mounted) return;
      setState(() {
        _locks
          ..clear()
          ..addAll(mapped);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('锁列表加载失败: $error')));
    } finally {
      if (mounted) setState(() => _lockLoading = false);
    }
  }

  Future<void> _onAddPressed() async {
    if (_tabIndex == 0) {
      final result = await _showKeyEditor();
      if (result == null) return;
      await _createKey(result);
      return;
    }
    if (_tabIndex == 1) {
      final result = await _showLockEditor();
      if (result == null) return;
      await _createLock(result);
    }
  }

  String? _requireToken() {
    final token = GlobalUser.instance.token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('登录状态已失效，请重新登录')));
      return null;
    }
    return token;
  }

  Future<void> _createKey(_KeyEditorResult result) async {
    final token = _requireToken();
    if (token == null) return;
    setState(() => _keyLoading = true);
    try {
      await Api.createLockKey(token: token, payload: result.createPayload);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('钥匙创建成功')));
      await _loadKeysFromApi();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('钥匙创建失败: $error')));
    } finally {
      if (mounted) setState(() => _keyLoading = false);
    }
  }

  Future<void> _createLock(_LockEditorResult result) async {
    final token = _requireToken();
    if (token == null) return;
    setState(() => _lockLoading = true);
    try {
      await Api.createLockDevice(token: token, payload: result.createPayload);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('锁创建成功')));
      await _loadLocksFromApi();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('锁创建失败: $error')));
    } finally {
      if (mounted) setState(() => _lockLoading = false);
    }
  }

  Future<void> _deleteKey(_KeyItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除钥匙'),
        content: Text('确认删除 ${item.name} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final token = _requireToken();
    if (token == null) return;
    try {
      await Api.deleteLockKey(token: token, id: item.id);
      await _loadKeysFromApi();
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

  Future<void> _deleteLock(_LockItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除锁'),
        content: Text('确认删除 ${item.name} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final token = _requireToken();
    if (token == null) return;
    try {
      await Api.deleteLockDevice(token: token, id: item.id);
      await _loadLocksFromApi();
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

  Future<_KeyEditorResult?> _showKeyEditor({_KeyItem? initial}) async {
    final nameController = TextEditingController(text: initial?.name ?? '');
    final numberController = TextEditingController(text: initial?.number ?? '');
    final ownerController = TextEditingController(
      text: initial?.ownerUserId ?? '',
    );
    var keyType = initial?.keyType ?? 'standard';
    var status = initial?.status ?? 'active';
    var currentStep = 0;

    return showModalBottomSheet<_KeyEditorResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return FractionallySizedBox(
              heightFactor: 0.92,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        initial == null ? '新增钥匙（分步）' : '编辑钥匙（分步）',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Stepper(
                        type: StepperType.vertical,
                        currentStep: currentStep,
                        onStepTapped: (value) {
                          setSheetState(() => currentStep = value);
                        },
                        controlsBuilder: (context, details) {
                          final isLast = currentStep == 2;
                          return Row(
                            children: [
                              FilledButton(
                                onPressed: isLast
                                    ? () {
                                        final name = nameController.text.trim();
                                        final number = numberController.text
                                            .trim();
                                        if (name.isEmpty || number.isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('请先填写名称和编号'),
                                            ),
                                          );
                                          return;
                                        }
                                        Navigator.of(context).pop(
                                          _KeyEditorResult(
                                            createPayload:
                                                _buildKeyCreatePayload(
                                                  name: name,
                                                  vendorKeyId: number,
                                                  keyType: keyType,
                                                  status: status,
                                                  ownerUserId: ownerController
                                                      .text
                                                      .trim(),
                                                ),
                                            updatePayload:
                                                _buildKeyUpdatePayload(
                                                  name: name,
                                                  keyType: keyType,
                                                  status: status,
                                                  ownerUserId: ownerController
                                                      .text
                                                      .trim(),
                                                ),
                                          ),
                                        );
                                      }
                                    : () => setSheetState(
                                        () => currentStep = currentStep + 1,
                                      ),
                                child: Text(isLast ? '保存' : '下一步'),
                              ),
                              const SizedBox(width: 8),
                              if (currentStep > 0)
                                OutlinedButton(
                                  onPressed: () => setSheetState(
                                    () => currentStep = currentStep - 1,
                                  ),
                                  child: const Text('上一步'),
                                ),
                            ],
                          );
                        },
                        steps: [
                          Step(
                            title: const Text('连接设备'),
                            isActive: currentStep >= 0,
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('参考网页流程：先连接设备并读取钥匙信息。'),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pushNamed(Routes.vendorTest),
                                  icon: const Icon(Icons.developer_board),
                                  label: const Text('打开厂家 SDK 测试页'),
                                ),
                              ],
                            ),
                          ),
                          Step(
                            title: const Text('信息填写'),
                            isActive: currentStep >= 1,
                            content: Column(
                              children: [
                                TextField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    labelText: '钥匙名称',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: numberController,
                                  enabled: initial == null,
                                  decoration: const InputDecoration(
                                    labelText: '钥匙编号 / vendorKeyId',
                                    helperText: '编辑时厂商编号不可修改',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: keyType,
                                  decoration: const InputDecoration(
                                    labelText: '钥匙类型',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'standard',
                                      child: Text('standard / 普通'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'bluetooth',
                                      child: Text('bluetooth / 蓝牙'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'fingerprint',
                                      child: Text('fingerprint / 指纹'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'cellular',
                                      child: Text('cellular / 4G'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'display',
                                      child: Text('display / 屏显'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'emergency',
                                      child: Text('emergency / 应急'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setSheetState(() => keyType = value);
                                    }
                                  },
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: ownerController,
                                  decoration: const InputDecoration(
                                    labelText: '归属用户 ID',
                                    helperText: '只表示保管人，不代表开锁权限',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: status,
                                  decoration: const InputDecoration(
                                    labelText: '钥匙状态',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'active',
                                      child: Text('active / 正常'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'damaged',
                                      child: Text('damaged / 损坏'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'lost',
                                      child: Text('lost / 丢失'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setSheetState(() => status = value);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          Step(
                            title: const Text('确认完成'),
                            isActive: currentStep >= 2,
                            content: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '钥匙名称: ${nameController.text.trim().isEmpty ? '-' : nameController.text.trim()}',
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '钥匙编号: ${numberController.text.trim().isEmpty ? '-' : numberController.text.trim()}',
                                  ),
                                  const SizedBox(height: 4),
                                  Text('类型: $keyType'),
                                  const SizedBox(height: 4),
                                  Text(
                                    '归属用户: ${ownerController.text.trim().isEmpty ? '-' : ownerController.text.trim()}',
                                  ),
                                  const SizedBox(height: 4),
                                  Text('状态: $status'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  JsonMap _buildKeyCreatePayload({
    required String name,
    required String vendorKeyId,
    required String keyType,
    required String status,
    required String ownerUserId,
  }) {
    final normalizedOwner = ownerUserId.isEmpty ? null : ownerUserId;
    return <String, dynamic>{
      'vendorKeyId': vendorKeyId,
      'keyType': keyType,
      'name': name,
      'assignedUserId': normalizedOwner,
      'ownerUserId': normalizedOwner,
      'status': status,
      'metadata': <String, dynamic>{
        'provisioningFlow': 'app_key_create',
        'department': 'Cereb',
        'source': 'android_app',
        'capturedAt': DateTime.now().toIso8601String(),
      },
    };
  }

  JsonMap _buildKeyUpdatePayload({
    required String name,
    required String keyType,
    required String status,
    required String ownerUserId,
  }) {
    final normalizedOwner = ownerUserId.isEmpty ? null : ownerUserId;
    return <String, dynamic>{
      'name': name,
      'keyType': keyType,
      'assignedUserId': normalizedOwner,
      'ownerUserId': normalizedOwner,
      'status': status,
      'metadata': <String, dynamic>{
        'department': 'Cereb',
        'source': 'android_app',
        'updatedFrom': 'app_key_edit',
        'capturedAt': DateTime.now().toIso8601String(),
      },
    };
  }

  Future<_LockEditorResult?> _showLockEditor({_LockItem? initial}) async {
    final nameController = TextEditingController(text: initial?.name ?? '');
    final numberController = TextEditingController(text: initial?.number ?? '');
    final locationController = TextEditingController(
      text: initial?.location ?? '',
    );
    var switchState = initial?.switchState ?? 'locked';
    var currentStep = 0;

    return showModalBottomSheet<_LockEditorResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return FractionallySizedBox(
              heightFactor: 0.92,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        initial == null ? '新增锁（分步）' : '编辑锁（分步）',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Stepper(
                        type: StepperType.vertical,
                        currentStep: currentStep,
                        onStepTapped: (value) {
                          setSheetState(() => currentStep = value);
                        },
                        controlsBuilder: (context, details) {
                          final isLast = currentStep == 5;
                          return Row(
                            children: [
                              FilledButton(
                                onPressed: isLast
                                    ? () {
                                        final name = nameController.text.trim();
                                        final number = numberController.text
                                            .trim();
                                        final location = locationController.text
                                            .trim();
                                        if (name.isEmpty ||
                                            number.isEmpty ||
                                            location.isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('请先填写名称、编号、位置'),
                                            ),
                                          );
                                          return;
                                        }
                                        Navigator.of(context).pop(
                                          _LockEditorResult(
                                            createPayload:
                                                _buildLockCreatePayload(
                                                  name: name,
                                                  vendorLockId: number,
                                                  location: location,
                                                  switchState: switchState,
                                                ),
                                            updatePayload:
                                                _buildLockUpdatePayload(
                                                  name: name,
                                                  location: location,
                                                  switchState: switchState,
                                                ),
                                          ),
                                        );
                                      }
                                    : () => setSheetState(
                                        () => currentStep = currentStep + 1,
                                      ),
                                child: Text(isLast ? '保存' : '下一步'),
                              ),
                              const SizedBox(width: 8),
                              if (currentStep > 0)
                                OutlinedButton(
                                  onPressed: () => setSheetState(
                                    () => currentStep = currentStep - 1,
                                  ),
                                  child: const Text('上一步'),
                                ),
                            ],
                          );
                        },
                        steps: [
                          Step(
                            title: const Text('连接设备'),
                            isActive: currentStep >= 0,
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('参考网页流程：先连接设备并初始化 SDK。'),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pushNamed(Routes.vendorTest),
                                  icon: const Icon(Icons.developer_board),
                                  label: const Text('打开厂家 SDK 测试页'),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pushNamed(Routes.onlineSwitchLock),
                                  icon: const Icon(Icons.lock_open),
                                  label: const Text('打开在线开关锁流程页'),
                                ),
                              ],
                            ),
                          ),
                          Step(
                            title: const Text('读取锁号'),
                            isActive: currentStep >= 1,
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '在 SDK 页面执行 ReadLockId 后，把锁编号回填到下方字段。',
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: numberController,
                                  enabled: initial == null,
                                  decoration: const InputDecoration(
                                    labelText: '锁编号',
                                    helperText: '编辑时厂商锁号不可修改',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Step(
                            title: const Text('基础信息'),
                            isActive: currentStep >= 2,
                            content: TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: '锁名称',
                              ),
                            ),
                          ),
                          Step(
                            title: const Text('状态设置'),
                            isActive: currentStep >= 3,
                            content: DropdownButtonFormField<String>(
                              initialValue: switchState,
                              decoration: const InputDecoration(
                                labelText: '开关状态',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'locked',
                                  child: Text('locked / 已上锁'),
                                ),
                                DropdownMenuItem(
                                  value: 'unlocked',
                                  child: Text('unlocked / 已解锁'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setSheetState(() => switchState = value);
                                }
                              },
                            ),
                          ),
                          Step(
                            title: const Text('位置信息'),
                            isActive: currentStep >= 4,
                            content: TextField(
                              controller: locationController,
                              decoration: const InputDecoration(
                                labelText: '位置',
                              ),
                            ),
                          ),
                          Step(
                            title: const Text('确认完成'),
                            isActive: currentStep >= 5,
                            content: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '锁名称: ${nameController.text.trim().isEmpty ? '-' : nameController.text.trim()}',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '锁编号: ${numberController.text.trim().isEmpty ? '-' : numberController.text.trim()}',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '位置: ${locationController.text.trim().isEmpty ? '-' : locationController.text.trim()}',
                                  ),
                                  const SizedBox(height: 8),
                                  Text('开关状态: $switchState'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  JsonMap _buildLockCreatePayload({
    required String name,
    required String vendorLockId,
    required String location,
    required String switchState,
  }) {
    return <String, dynamic>{
      'vendorLockId': vendorLockId,
      'name': name,
      'assetId': null,
      'metadata': <String, dynamic>{
        'provisioningFlow': 'app_lock_create',
        'location': location,
        'switchState': switchState,
        'source': 'android_app',
        'capturedAt': DateTime.now().toIso8601String(),
      },
    };
  }

  JsonMap _buildLockUpdatePayload({
    required String name,
    required String location,
    required String switchState,
  }) {
    return <String, dynamic>{
      'name': name,
      'assetId': null,
      'metadata': <String, dynamic>{
        'location': location,
        'switchState': switchState,
        'source': 'android_app',
        'updatedFrom': 'app_lock_edit',
        'capturedAt': DateTime.now().toIso8601String(),
      },
    };
  }

  Future<void> _editKey(_KeyItem item) async {
    final result = await _showKeyEditor(initial: item);
    if (result == null) return;
    final token = _requireToken();
    if (token == null) return;
    setState(() => _keyLoading = true);
    try {
      await Api.updateLockKey(
        token: token,
        id: item.id,
        payload: result.updatePayload,
      );
      await _loadKeysFromApi();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('钥匙已更新')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('钥匙更新失败: $error')));
    } finally {
      if (mounted) setState(() => _keyLoading = false);
    }
  }

  Future<void> _editLock(_LockItem item) async {
    final result = await _showLockEditor(initial: item);
    if (result == null) return;
    final token = _requireToken();
    if (token == null) return;
    setState(() => _lockLoading = true);
    try {
      await Api.updateLockDevice(
        token: token,
        id: item.id,
        payload: result.updatePayload,
      );
      await _loadLocksFromApi();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('锁已更新')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('锁更新失败: $error')));
    } finally {
      if (mounted) setState(() => _lockLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          if (_showAdd)
            IconButton(
              tooltip: '添加',
              onPressed: _onAddPressed,
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody(context)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.key_outlined), label: '钥匙'),
          NavigationDestination(icon: Icon(Icons.lock_outline), label: '锁'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: '我的'),
        ],
        onDestinationSelected: (index) {
          setState(() {
            _tabIndex = index;
            _query = '';
          });
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_tabIndex == 2) {
      return _MineTab(
        onOpenCurrentTest: () =>
            Navigator.of(context).pushNamed(Routes.currentTest),
        onOpenVendorTest: () =>
            Navigator.of(context).pushNamed(Routes.vendorTest),
        onOpenOnlineSwitchLock: () =>
            Navigator.of(context).pushNamed(Routes.onlineSwitchLock),
      );
    }

    final isKeyTab = _tabIndex == 0;
    final list = isKeyTab ? _filteredKeys : _filteredLocks;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: isKeyTab ? '搜索钥匙名称/编号' : '搜索锁名称/编号/位置',
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
          child: isKeyTab && _keyLoading
              ? const Center(child: CircularProgressIndicator())
              : !isKeyTab && _lockLoading
              ? const Center(child: CircularProgressIndicator())
              : list.isEmpty
              ? const Center(child: Text('暂无数据'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (isKeyTab) {
                      final item = list[index] as _KeyItem;
                      return _KeyCard(
                        item: item,
                        onEdit: () => _editKey(item),
                        onDelete: () => _deleteKey(item),
                      );
                    }
                    final item = list[index] as _LockItem;
                    return _LockCard(
                      item: item,
                      onEdit: () => _editLock(item),
                      onDelete: () => _deleteLock(item),
                    );
                  },
                ),
        ),
      ],
    );
  }

  _KeyItem _mapApiKey(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString();
    final name = (json['name'] ?? json['vendorKeyId'] ?? id).toString();
    final number = (json['vendorKeyId'] ?? id).toString();
    final status = (json['status'] ?? 'active').toString();
    final keyType = (json['keyType'] ?? 'standard').toString();
    final ownerUserId = (json['ownerUserId'] ?? json['assignedUserId'] ?? '')
        .toString();
    final updatedAtRaw = json['updatedAt']?.toString();
    final updatedAt = DateTime.tryParse(updatedAtRaw ?? '') ?? DateTime.now();
    return _KeyItem(
      id: id.isEmpty ? DateTime.now().microsecondsSinceEpoch.toString() : id,
      name: name,
      number: number,
      keyType: keyType,
      ownerUserId: ownerUserId,
      status: status,
      updatedAt: updatedAt,
    );
  }

  _LockItem _mapApiLock(Map<String, dynamic> json) {
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

    return _LockItem(
      id: id.isEmpty ? DateTime.now().microsecondsSinceEpoch.toString() : id,
      name: name,
      number: number,
      location: location,
      switchState: switchState,
      updatedAt: updatedAt,
    );
  }
}

class _KeyCard extends StatelessWidget {
  const _KeyCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final _KeyItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
                TextButton(onPressed: onEdit, child: const Text('编辑')),
                TextButton(onPressed: onDelete, child: const Text('删除')),
              ],
            ),
            const SizedBox(height: 2),
            Text('类型: ${item.keyType}'),
            const SizedBox(height: 2),
            Text('编号: ${item.number}'),
            if (item.ownerUserId.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('归属用户: ${item.ownerUserId}'),
            ],
            const SizedBox(height: 2),
            Text('状态: ${item.status == 'active' ? '正常' : item.status}'),
            const SizedBox(height: 2),
            Text('更新时间: ${_formatDate(item.updatedAt)}'),
          ],
        ),
      ),
    );
  }
}

class _LockCard extends StatelessWidget {
  const _LockCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final _LockItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
                TextButton(onPressed: onEdit, child: const Text('编辑')),
                TextButton(onPressed: onDelete, child: const Text('删除')),
              ],
            ),
            const SizedBox(height: 2),
            Text('编号: ${item.number}'),
            const SizedBox(height: 2),
            Text('位置: ${item.location}'),
            const SizedBox(height: 2),
            Text('开关状态: ${item.switchState == 'locked' ? '已上锁' : '已解锁'}'),
            const SizedBox(height: 2),
            Text('更新时间: ${_formatDate(item.updatedAt)}'),
          ],
        ),
      ),
    );
  }
}

class _MineTab extends StatefulWidget {
  const _MineTab({
    required this.onOpenCurrentTest,
    required this.onOpenVendorTest,
    required this.onOpenOnlineSwitchLock,
  });

  final VoidCallback onOpenCurrentTest;
  final VoidCallback onOpenVendorTest;
  final VoidCallback onOpenOnlineSwitchLock;

  @override
  State<_MineTab> createState() => _MineTabState();
}

class _MineTabState extends State<_MineTab> {
  String? _username;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    GlobalUser.instance.loadFromStorage().then((_) async {
      if (!mounted) return;
      setState(() {
        _username = GlobalUser.instance.username;
      });
      await GlobalUser.instance.fetchProfile();
      if (!mounted) return;
      setState(() {
        _username = GlobalUser.instance.username ?? GlobalUser.instance.email;
      });
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确认退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loggingOut = true);
    try {
      await GlobalUser.instance.logout();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (_) => false);
  }

  Future<void> _openCerebSite() async {
    final url = Uri.parse('http://cereb.ai');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法打开 Cereb.AI 官网')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: const Text('账号'),
                subtitle: Text(_username ?? '—'),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('版本'),
                subtitle: Text('1.0.0+1'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.science_outlined),
                title: const Text('当前测试主页'),
                subtitle: const Text('保留原有测试流程'),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onOpenCurrentTest,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.developer_board_outlined),
                title: const Text('厂家 SDK 测试界面'),
                subtitle: const Text('保留原有测试流程'),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onOpenVendorTest,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_open_outlined),
                title: const Text('设置开关锁钥匙（在线）'),
                subtitle: const Text('保留原有测试流程'),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onOpenOnlineSwitchLock,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: _loggingOut ? null : _logout,
          icon: _loggingOut
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout),
          label: const Text('退出登录'),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'powered by ',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            TextButton(
              onPressed: _openCerebSite,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Cereb.AI',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeyItem {
  const _KeyItem({
    required this.id,
    required this.name,
    required this.number,
    required this.keyType,
    required this.ownerUserId,
    required this.status,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String number;
  final String keyType;
  final String ownerUserId;
  final String status;
  final DateTime updatedAt;
}

class _KeyEditorResult {
  const _KeyEditorResult({
    required this.createPayload,
    required this.updatePayload,
  });

  final JsonMap createPayload;
  final JsonMap updatePayload;
}

class _LockEditorResult {
  const _LockEditorResult({
    required this.createPayload,
    required this.updatePayload,
  });

  final JsonMap createPayload;
  final JsonMap updatePayload;
}

class _LockItem {
  const _LockItem({
    required this.id,
    required this.name,
    required this.number,
    required this.location,
    required this.switchState,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String number;
  final String location;
  final String switchState;
  final DateTime updatedAt;
}

String _formatDate(DateTime value) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} ${two(value.hour)}:${two(value.minute)}';
}
