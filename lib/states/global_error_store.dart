import 'package:flutter/foundation.dart';

class AppErrorEntry {
  const AppErrorEntry({
    required this.message,
    required this.time,
    this.stackTrace,
  });

  final String message;
  final DateTime time;
  final StackTrace? stackTrace;
}

class GlobalErrorStore extends ChangeNotifier {
  GlobalErrorStore._();

  static final GlobalErrorStore instance = GlobalErrorStore._();

  final List<AppErrorEntry> _errors = <AppErrorEntry>[];

  List<AppErrorEntry> get errors => List.unmodifiable(_errors);

  AppErrorEntry? get latest => _errors.isEmpty ? null : _errors.first;

  void add(Object error, StackTrace stackTrace) {
    _errors.insert(
      0,
      AppErrorEntry(
        message: error.toString(),
        time: DateTime.now(),
        stackTrace: stackTrace,
      ),
    );
    if (_errors.length > 50) {
      _errors.removeRange(50, _errors.length);
    }
    notifyListeners();
  }

  void clear() {
    _errors.clear();
    notifyListeners();
  }
}
