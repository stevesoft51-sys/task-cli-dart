import 'priority.dart';

abstract class Task {
  final String id;
  String title;
  Priority priority;
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

  void markCompleted() {
    isCompleted = true;
  }

  Map<String, dynamic> toJson();

  static Task fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == 'urgent') {
      return UrgentTask.fromJson(json);
    }
    return RegularTask.fromJson(json);
  }

  @override
  String toString() {
    final status = isCompleted ? '✓' : '○';
    final due = dueDate != null ? ' | Échéance: $dueDate' : '';
    return '[$status] $title ($priority)$due';
  }
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

  @override
  String toString() {
    final base = super.toString();
    final overdue = isOverdue ? ' EN RETARD' : '';
    final reminder = ' | Rappel: $reminderMinutes min';
    return '$base$reminder$overdue';
  }
}
