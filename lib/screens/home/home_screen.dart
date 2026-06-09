import 'package:flutter/material.dart';

import '../../routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('蓝牙钥匙 SDK 测试')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HomeItem(
              icon: Icons.science_outlined,
              title: '当前测试主页',
              subtitle: '进入现有 Flutter SDK 初始化、扫描、版本和日志测试页',
              onTap: () => Navigator.of(context).pushNamed(Routes.currentTest),
            ),
            const SizedBox(height: 12),
            _HomeItem(
              icon: Icons.developer_board_outlined,
              title: '厂家 SDK 测试界面',
              subtitle: '对齐 Android demo 的扫描、连接、授权、记录、任务和指纹命令',
              onTap: () => Navigator.of(context).pushNamed(Routes.vendorTest),
            ),
            const SizedBox(height: 12),
            _HomeItem(
              icon: Icons.lock_open_outlined,
              title: '设置开关锁钥匙（在线）',
              subtitle:
                  '按 InitSDK、connectToKey、setDateTime、setUserKey、setOnline 流程授权',
              onTap: () =>
                  Navigator.of(context).pushNamed(Routes.onlineSwitchLock),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeItem extends StatelessWidget {
  const _HomeItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        minVerticalPadding: 20,
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
