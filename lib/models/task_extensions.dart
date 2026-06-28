import 'task.dart';
import 'priority.dart';

extension TaskListExtensions on List<Task> {
  List<Task> filterByPriority(Priority priority) =>
    where((t) => t.priority == priority).toList();

  List<Task> get completedTasks => where((t) => t.isCompleted).toList();

  List<Task> get pendingTasks => where((t) => !t.isCompleted).toList();

  List<Task> get urgentOnly => whereType<UrgentTask>().toList();

  List<Task> get overdueTasks =>
    whereType<UrgentTask>().where((t) => t.isOverdue).toList();

  ({int total, int completed, int pending, int urgent, double rate}) get stats {
    var total = length;
    var completed = completedTasks.length;
    var pending = pendingTasks.length;
    var urgent = urgentOnly.length;
    var rate = total > 0 ? completed / total : 0.0;
    return (total: total, completed: completed, pending: pending, urgent: urgent, rate: rate);
  }

  List<Task> sortedByPriority() => toList()
    ..sort((a, b) => b.priority.level.compareTo(a.priority.level));

  List<Task> sortedByDate() => toList()
    ..sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

  bool get anyCompleted => any((t) => t.isCompleted);
  bool get anyUrgent => any((t) => t is UrgentTask);
  bool get allHighPriority => every((t) => t.priority == Priority.high);
  bool get allCompleted => every((t) => t.isCompleted);

  Task? get earliestDueDate =>
    isEmpty ? null : reduce((a, b) {
      if (a.dueDate == null && b.dueDate == null) return a;
      if (a.dueDate == null) return b;
      if (b.dueDate == null) return a;
      return a.dueDate!.isBefore(b.dueDate!) ? a : b;
    });
}

extension StringTaskExtensions on String {
  bool get isValidTaskTitle => trim().isNotEmpty;

  String get capitalized =>
    isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}
