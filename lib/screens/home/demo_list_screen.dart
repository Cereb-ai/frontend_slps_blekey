import 'package:flutter/material.dart';

import '../../routes.dart';

class DemoListScreen extends StatelessWidget {
  const DemoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo 列表')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DemoItem(
              icon: Icons.my_location_outlined,
              title: '定位测试',
              subtitle: '检查定位权限、定位服务并显示 lat、lng 和精度',
              onTap: () =>
                  Navigator.of(context).pushNamed(Routes.locationTest),
            ),
            const SizedBox(height: 12),
            _DemoItem(
              icon: Icons.fingerprint,
              title: '指纹钥匙开锁',
              subtitle: '纯界面演示指纹验证、触碰锁具和开锁记录状态',
              onTap: () =>
                  Navigator.of(context).pushNamed(Routes.fingerprintUnlockDemo),
            ),
            const SizedBox(height: 12),
            _DemoItem(
              icon: Icons.science_outlined,
              title: '当前测试主页',
              subtitle: '现有 Flutter SDK 初始化、扫描、版本和日志测试页',
              onTap: () => Navigator.of(context).pushNamed(Routes.currentTest),
            ),
            const SizedBox(height: 12),
            _DemoItem(
              icon: Icons.developer_board_outlined,
              title: '厂家 SDK 测试界面',
              subtitle: '扫描、连接、授权、记录、任务和指纹命令',
              onTap: () => Navigator.of(context).pushNamed(Routes.vendorTest),
            ),
            const SizedBox(height: 12),
            _DemoItem(
              icon: Icons.lock_open_outlined,
              title: '设置开关锁钥匙（在线）',
              subtitle: '按在线流程授权钥匙并测试开关锁能力',
              onTap: () =>
                  Navigator.of(context).pushNamed(Routes.onlineSwitchLock),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoItem extends StatelessWidget {
  const _DemoItem({
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
        minVerticalPadding: 18,
        leading: Icon(icon, color: colorScheme.secondary),
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
