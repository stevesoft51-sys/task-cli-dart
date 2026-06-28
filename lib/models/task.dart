import '../interfaces/prioritizable.dart';
import 'priority.dart';

sealed class Task implements Prioritizable {
  final String id;
  String title;
  @override
  Priority priority;
  @override
  DateTime? dueDate;
  bool isCompleted;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.priority,
    this.dueDate,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get type;

  String get statusSymbol => isCompleted ? '\u2713' : '\u25CB';

  void markCompleted() {
    isCompleted = true;
  }

  Map<String, dynamic> toJson();

  static Task fromJson(Map<String, dynamic> json) {
    return switch (json['type'] as String?) {
      'urgent' => UrgentTask.fromJson(json),
      _ => RegularTask.fromJson(json),
    };
  }

  @override
  String toString() {
    final due = dueDate != null ? ' | Echeance: $dueDate' : '';
    return switch (this) {
      UrgentTask(isOverdue: true, reminderMinutes: var rem) =>
        '$statusSymbol $title ($priority)$due | Rappel: ${rem}min [EN RETARD]',
      UrgentTask(reminderMinutes: var rem) =>
        '$statusSymbol $title ($priority)$due | Rappel: ${rem}min',
      _ => '$statusSymbol $title ($priority)$due',
    };
  }

  ({String type, String id, String title, Priority priority, bool isDone}) get info => (
    type: type,
    id: id,
    title: title,
    priority: priority,
    isDone: isCompleted,
  );
}

class RegularTask extends Task {
  RegularTask({
    required super.id,
    required super.title,
    required super.priority,
    super.dueDate,
    super.isCompleted,
    super.createdAt,
  });

  @override
  String get type => 'regular';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'title': title,
        'priority': priority.name,
        'dueDate': dueDate?.toIso8601String(),
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RegularTask.fromJson(Map<String, dynamic> json) => RegularTask(
        id: json['id'] as String,
        title: json['title'] as String,
        priority: Priority.fromString(json['priority'] as String),
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
        isCompleted: json['isCompleted'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}

class UrgentTask extends Task {
  final int reminderMinutes;

  UrgentTask({
    required super.id,
    required super.title,
    required super.priority,
    super.dueDate,
    super.isCompleted,
    super.createdAt,
    this.reminderMinutes = 30,
  });

  @override
  String get type => 'urgent';

  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now()) && !isCompleted;

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'title': title,
        'priority': priority.name,
        'dueDate': dueDate?.toIso8601String(),
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
        'reminderMinutes': reminderMinutes,
      };

  factory UrgentTask.fromJson(Map<String, dynamic> json) => UrgentTask(
        id: json['id'] as String,
        title: json['title'] as String,
        priority: Priority.fromString(json['priority'] as String),
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
        isCompleted: json['isCompleted'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        reminderMinutes: json['reminderMinutes'] as int? ?? 30,
      );
}
