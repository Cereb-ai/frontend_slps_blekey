import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'widgets/keys_list.dart';
import 'widgets/locks_list.dart';
import 'widgets/mine_tab.dart';
import 'widgets/key_editor_sheet.dart';
import 'widgets/lock_editor_sheet.dart';

class AppHomeScreen extends StatefulWidget {
  const AppHomeScreen({super.key});

  @override
  State<AppHomeScreen> createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends State<AppHomeScreen> {
  int _tabIndex = 0;
  int _keysReloadTrigger = 0;
  int _locksReloadTrigger = 0;

  String get _title {
    final l10n = AppLocalizations.of(context)!;
    if (_tabIndex == 0) return l10n.keysManagement;
    if (_tabIndex == 1) return l10n.locksManagement;
    return l10n.my;
  }

  bool get _showAdd => _tabIndex == 0 || _tabIndex == 1;

  Future<void> _onAddPressed() async {
    if (_tabIndex == 0) {
      final result = await showKeyEditorSheet(context);
      if (result == null) return;
      setState(() => _keysReloadTrigger++);
      return;
    }
    if (_tabIndex == 1) {
      final result = await showLockEditorSheet(context);
      if (result == null) return;
      setState(() => _locksReloadTrigger++);
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
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.key_outlined),
            label: AppLocalizations.of(context)!.keysManagement,
          ),
          NavigationDestination(
            icon: const Icon(Icons.lock_outline),
            label: AppLocalizations.of(context)!.locksManagement,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            label: AppLocalizations.of(context)!.my,
          ),
        ],
        onDestinationSelected: (index) {
          setState(() => _tabIndex = index);
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_tabIndex == 0) {
      return KeysList(
        key: ValueKey<int>(_keysReloadTrigger),
      );
    }
    if (_tabIndex == 1) {
      return LocksList(
        key: ValueKey<int>(_locksReloadTrigger),
      );
    }
    return MineTab(
      onOpenCurrentTest: () =>
          Navigator.of(context).pushNamed('/current-test'),
      onOpenVendorTest: () =>
          Navigator.of(context).pushNamed('/vendor-test'),
      onOpenOnlineSwitchLock: () =>
          Navigator.of(context).pushNamed('/online-switch-lock'),
    );
  }
}
