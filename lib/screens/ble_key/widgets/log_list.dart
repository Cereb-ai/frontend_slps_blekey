import 'package:flutter/material.dart';

import '../ble_key_controller.dart';

class LogList extends StatelessWidget {
  const LogList({required this.logs, super.key});

  final List<BleKeyLog> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('暂无事件日志'),
      );
    }

    return Column(
      children: logs.map((log) {
        final color = log.isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.onSurface;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  _formatTime(log.time),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: Text(log.message, style: TextStyle(color: color)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatTime(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }
}
