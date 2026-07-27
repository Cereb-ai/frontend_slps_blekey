typedef JsonMap = Map<String, dynamic>;

enum AppTaskType {
  jointClearance,
  sequentialUnlock,
  timeWindow;

  static AppTaskType fromValue(Object? value) {
    return switch (value?.toString()) {
      'sequential_unlock' => AppTaskType.sequentialUnlock,
      'time_window' => AppTaskType.timeWindow,
      _ => AppTaskType.jointClearance,
    };
  }
}

class AppTaskSummary {
  const AppTaskSummary({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.status,
    required this.updatedAt,
    required this.summary,
  });

  final String id;
  final AppTaskType type;
  final String name;
  final String description;
  final String status;
  final DateTime? updatedAt;
  final JsonMap summary;

  factory AppTaskSummary.fromJson(JsonMap json) {
    final rawSummary = json['summary'];
    return AppTaskSummary(
      id: json['id']?.toString() ?? '',
      type: AppTaskType.fromValue(json['type']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      summary: rawSummary is Map
          ? Map<String, dynamic>.from(rawSummary)
          : <String, dynamic>{},
    );
  }

  int get completed =>
      int.tryParse(summary['completedSteps']?.toString() ?? '') ??
      int.tryParse(summary['clearedCount']?.toString() ?? '') ??
      0;

  int get total =>
      int.tryParse(summary['totalSteps']?.toString() ?? '') ??
      int.tryParse(summary['requiredCount']?.toString() ?? '') ??
      0;
}

class SequentialTaskStep {
  const SequentialTaskStep({
    required this.id,
    required this.position,
    required this.lockName,
    required this.operation,
    required this.windowStart,
    required this.windowEnd,
    required this.status,
  });

  final String id;
  final int position;
  final String lockName;
  final String operation;
  final String windowStart;
  final String windowEnd;
  final String status;

  factory SequentialTaskStep.fromJson(JsonMap json) {
    return SequentialTaskStep(
      id: json['id']?.toString() ?? '',
      position: int.tryParse(json['position']?.toString() ?? '') ?? 0,
      lockName:
          json['lockName']?.toString() ?? json['lockId']?.toString() ?? '',
      operation: json['operation']?.toString() ?? 'unlock',
      windowStart: json['windowStart']?.toString() ?? '',
      windowEnd: json['windowEnd']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
    );
  }
}

class SequentialTaskDetail {
  const SequentialTaskDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.executionMode,
    required this.status,
    required this.validFrom,
    required this.validUntil,
    required this.steps,
  });

  final String id;
  final String name;
  final String description;
  final String executionMode;
  final String status;
  final String validFrom;
  final String validUntil;
  final List<SequentialTaskStep> steps;

  factory SequentialTaskDetail.fromJson(JsonMap json) {
    final rawSteps = json['steps'];
    return SequentialTaskDetail(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      executionMode: json['executionMode']?.toString() ?? 'sequential',
      status: json['status']?.toString() ?? 'active',
      validFrom: json['validFrom']?.toString() ?? '',
      validUntil: json['validUntil']?.toString() ?? '',
      steps: rawSteps is List
          ? rawSteps
                .whereType<Map>()
                .map(
                  (item) => SequentialTaskStep.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const <SequentialTaskStep>[],
    );
  }
}
