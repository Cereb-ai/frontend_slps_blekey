import 'package:flutter/material.dart';

class FingerprintUnlockDemoScreen extends StatelessWidget {
  const FingerprintUnlockDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('指纹钥匙开锁')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeroPanel(colorScheme: colorScheme),
            const SizedBox(height: 16),
            _StepPanel(colorScheme: colorScheme),
            const SizedBox(height: 16),
            const _StatusGrid(),
            const SizedBox(height: 16),
            _UnlockRecordCard(colorScheme: colorScheme),
          ],
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vanma 指纹智能钥匙',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '员工完成指纹验证后，用钥匙触碰被授权锁具即可开锁。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _KeyMockup(colorScheme: colorScheme),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _CapabilityChip(label: '指纹验证'),
              _CapabilityChip(label: '蓝牙通信'),
              _CapabilityChip(label: 'IP65'),
              _CapabilityChip(label: '60000 条记录'),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeyMockup extends StatelessWidget {
  const _KeyMockup({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 154,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFF16253A),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.secondary.withValues(alpha: 0.16),
              border: Border.all(color: colorScheme.secondary),
            ),
            child: Icon(Icons.fingerprint, color: colorScheme.secondary),
          ),
          const Spacer(),
          Container(
            width: 42,
            height: 66,
            decoration: BoxDecoration(
              color: const Color(0xFF0B1220),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.key, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: colorScheme.primary.withValues(alpha: 0.18),
      side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
    );
  }
}

class _StepPanel extends StatelessWidget {
  const _StepPanel({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('开锁流程', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          const _UnlockStep(
            index: '1',
            title: '选择指纹钥匙',
            subtitle: 'FK04-FP-1024 已连接，电量 86%',
            active: true,
          ),
          const _UnlockStep(
            index: '2',
            title: '按压指纹区',
            subtitle: '指纹模板匹配成功，操作者：张三',
            active: true,
          ),
          const _UnlockStep(
            index: '3',
            title: '触碰目标锁具',
            subtitle: '锁具 VM-LK-8001 在授权时间内',
            active: true,
          ),
          const _UnlockStep(
            index: '4',
            title: '开锁完成',
            subtitle: '生成本地开锁记录，等待同步后台',
            active: false,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.fingerprint),
              label: const Text('模拟验证并开锁'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockStep extends StatelessWidget {
  const _UnlockStep({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.active,
  });

  final String index;
  final String title;
  final String subtitle;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = active ? colorScheme.secondary : colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: color.withValues(alpha: 0.16),
            child: Text(
              index,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusGrid extends StatelessWidget {
  const _StatusGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.75,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _MetricCard(label: '指纹容量', value: '100', unit: '枚'),
        _MetricCard(label: '开锁记录', value: '60k', unit: '条'),
        _MetricCard(label: '钥匙电量', value: '86', unit: '%'),
        _MetricCard(label: '授权锁具', value: '12', unit: '把'),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.titleLarge,
              children: [
                TextSpan(text: value),
                TextSpan(
                  text: ' $unit',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockRecordCard extends StatelessWidget {
  const _UnlockRecordCard({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('最近记录', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          const _RecordRow(
            title: 'VM-LK-8001 配电柜锁',
            subtitle: '张三 · 指纹验证 · 今日 14:32',
            success: true,
          ),
          const Divider(height: 20),
          const _RecordRow(
            title: 'VM-LK-7019 机柜锁',
            subtitle: '李四 · 非授权时段 · 昨日 18:06',
            success: false,
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.title,
    required this.subtitle,
    required this.success,
  });

  final String title;
  final String subtitle;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final color = success ? const Color(0xFF43D17A) : const Color(0xFFFFB35C);
    return Row(
      children: [
        Icon(
          success ? Icons.check_circle_outline : Icons.warning_amber,
          color: color,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
